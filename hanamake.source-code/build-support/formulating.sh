#  Copyright (C) 2022 Hanami Zero
#
#  This file is part of hanamake,
#  a C and C++ development utility.
#
#  hanamake is free software: you can redistribute it and/or modify
#  it under the terms of the GNU Affero General Public License --
#  the superset of version 3 of the GNU General Public License --
#  as published by the Free Software Foundation.
#
#  hanamake is distributed in the hope that it will be useful,
#  but WITHOUT ANY WARRANTY; without even the implied warranty
#  of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
#  See the GNU Affero General Public License for more details.
#
#  You should have received a copy of the GNU Affero General Public License
#  along with hanamake. If not, see <https://www.gnu.org/licenses/>.

> ${1} echo \
"\
/* Copyright (C) 2022 Hanami Zero

   This file is part of hanamake,
   a C and C++ development utility.

   hanamake is free software: you can redistribute it and/or modify
   it under the terms of the GNU Affero General Public License --
   the superset of version 3 of the GNU General Public License --
   as published by the Free Software Foundation.

   hanamake is distributed in the hope that it will be useful,
   but WITHOUT ANY WARRANTY; without even the implied warranty
   of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
   See the GNU Affero General Public License for more details.

   You should have received a copy of the GNU Affero General Public License
   along with hanamake. If not, see <https://www.gnu.org/licenses/>. */
"


# Insert system header files
>>${1} echo \
"\
#include <stdint.h>
#include <stdio.h>

"

# Gather the function pathways
pathways="\
$(\
find build         \
  \( -name '*.i'   \
  -o -name '*.ipp' \
  \)               \
  -type d          \
  -exec sh -c      \
'
  while test ${#} -gt 0 \
  ; do : \
    ; echo "${1}"/* \
    ; shift 1 \
  ; done
' \
'_' '{}' '+' \
| tr ' ' '\n' \
| while read -r pathway \
; do : \
  ; target_path="${pathway%__hanamade_test__}" \
  ; test_target="$(basename ${target_path})" \
  ; if test      "${pathway#${target_path}}" = "__hanamade_test__" \
  ; then : \
    ; echo "$(c++filt ${test_target})0/${pathway}" \
  ; else : \
    ; echo "$(c++filt ${test_target})/${pathway}" \
  ; fi \
; done \
| LC_COLLATE=C sort -k1 -t/ \
| cut -d/ -f1 --complement \
)\
"  # Can't seem to get sort to recognize ' ' 0x20 - 0x2F characters, hence 0x30


# Get function dependency information
#
# 1. Generate function name to coi-function index sed translation file

function_names="$(basename -a ${pathways})"
echo ${function_names} \
| tr ' ' '\n' \
| cat -n \
| sed 's/^[\t ]*\([0-9][0-9]*\)[\t ]*\([$A-Z_a-z][$0-9A-Z_a-z]*\)/s\/\2$\/(\1-1)\//' \
> 0hana-main.c.sed


#
# 2. Insert unit test declarations and check test binding
test_names="$(basename -a ${pathways} | tr ' ' '\n' | grep  '__hanamade_test__$')"
test_targets="$(echo    ${test_names} | tr ' ' '\n' | sed 's/__hanamade_test__$//g')"
for target in ${test_targets}
do
>>${1} echo "void ${target}__hanamade_test__"
>>${1} echo "( FILE      ** const __hanamade_test__log_file"
>>${1} echo ", char const * const __hanamade_test__log_path"
>>${1} echo ", char const * const __hanamade_test__targetID"
>>${1} echo ") ;"
>>${1} echo
done
>>${1} echo


#
# 3. Identify dependencies of each function by (possibly C++ mangled) GNU assembler name
coi="0"
for path in ${pathways}
do \
dependency_list="\
$(  grep  -w 'bl\|call'  "${path}" \
  | sed 's/\(bl\|call\)//' \
  | sed 's/[\t ][\t ]*//' \
  | sed 's/@.*//' \
  | grep  -v "$(basename "${path}")" \
  | grep -ow  $(echo ${function_names} | sed 's/\([$A-Z_a-z][$0-9A-Z_a-z]*\)[\t ]*/\1\\|/g') \
  | LC_COLLATE=C sort -u \
  | sed -f 0hana-main.c.sed \
  | while read -r expression \
  ; do : \
    ; printf "$((${expression})), " \
  ; done \
)"
dependencies="$(printf "${dependency_list}" | wc -w)" \

  name="$(basename "${path}")"

  if test "${dependencies}" -gt 0
  then
    >>${1} echo \
    "size_t const dependency_of_$(printf "%04X" "${coi}")[${dependencies}] = { ${dependency_list}};"
  else
    >>${1} echo \
    "#define      dependency_of_$(printf "%04X" "${coi}")       0"
  fi

  coi="$((coi + 1))"
done
>>${1} printf "\n\n"


# Get number of code objects
>>${1} echo "#define code_objects $(echo ${pathways} | wc -w)"
>>${1} printf "\n\n"


# Define code object information structure for access in dispatcher loop
>>${1} echo \
"\
enum code_object_status { passed, failed, updated, depends };

struct code_object_info
{
  char   const * const name;
  /*----------------------*/
  char   const * const log_path;
  FILE         *       log_file;
  /*--------------------------*/
  size_t const * const dependency;
  size_t const         dependencies;
  /*------------------------------*/
  void        (* const __hanamade_test__)
  ( FILE      ** const __hanamade_test__log_file
  , char const * const __hanamade_test__log_path
  , char const * const __hanamade_test__targetID
  ) ;
  size_t const         __hanamade_test__subject_index;
  /*------------------------------------------------*/
  enum code_object_status status;
}
coi[code_objects] =
{\
"

# Identify longest code object name for test output formatting (relative right justify names)
coi="0"
hanamade_test_prefix='(test)  '
test_prefix_length=$(printf "${hanamade_test_prefix}" | wc -m)
longest_name=0
for name in $(basename -a ${pathways})
do
  name_length=$(printf "${name}" | sed 's/__hanamade_test__$//' | c++filt | wc -m)
  if test -n "$(echo   "${name}" | grep  '__hanamade_test__$')"
  then name_length=$((name_length + test_prefix_length))
  fi

  if test ${name_length} -gt ${longest_name}
  then longest_name=${name_length}
  fi
done


# Initialize the code object information ("coi") array
for identity in ${pathways}
do
  name=$(basename ${identity})
  name_string="$(printf "${name}" | sed 's/__hanamade_test__$//' | c++filt)"
  name_length="$(printf "${name_string}" | wc -m)"
  is_a_test=0

  if test -n "$(echo ${name} | grep '__hanamade_test__$')"
  then
    is_a_test=1
    name_length="$((name_length + test_prefix_length))"
    name_string="${hanamade_test_prefix}${name_string}"
  fi

  extra_spaces="$(for i in $(seq $((longest_name - name_length))); do printf ' '; done)"

  if test ${is_a_test} -eq 1                           # name
  then
    >>${1} echo "  { \"$(echo "${name_string}" | sed 's/(test)/(test)'"${extra_spaces}"'/')\""
  else
    >>${1} echo "  { \"${extra_spaces}${name_string}\""
  fi

  >>${1} echo "  , \"$(echo ${identity}.log | sed 's/^build\//log\//')\""
                                                       # log_path string
  >>${1} echo "  , NULL"                               # log_file FILE pointer

  dependency_array="dependency_of_$(printf "%04X" ${coi})"
  >>${1} echo "  , ${dependency_array}"
                                                       # dependency
  >>${1} echo "  , sizeof(${dependency_array}) / sizeof(size_t)"
                                                       # dependencies

  if test ${is_a_test} -eq 1
  then                                                 # if the name is not a test and has an eXactly matching test
    >>${1} echo "  , ${name}"                          # __hanamade_test__
    >>${1} echo "  , $(($(echo ${name%__hanamade_test__} | sed -f 0hana-main.c.sed)))"
                                                       # __hanamade_test__subject_index
  else
    >>${1} echo "  , NULL"                             # __hanamade_test__
    >>${1} echo "  , -1"                               # __hanamade_test__subject_index
  fi

  >>${1} echo "  , failed"                             # code object status (default: failed)

  >>${1} echo "  } ,"
  >>${1} echo

  coi="$((coi + 1))"
done
>>${1} printf '%s' \
"\
} ;

char * left_justified
( char const * cstring
)
{ while(*cstring == ' ') cstring++;
  return (char *)cstring;
}


/* Determine topological ordering,
   (a pseudo-topological ordering if circular dependencies are present)

   So that code objects are placed after their dependencies in top[] */


/* First, create implicitly available variables */

typedef size_t     code_object_index;
typedef size_t     code_object_dependency_index;

code_object_index  top[code_objects];
code_object_index  top_iterator = 0;

enum { unsorted, sorted, in_recursion }
top_status[code_objects] = { unsorted };


/* Declare the recursive step of topological sorting */

void topological_sort_visit
( code_object_index const C
) ;


/* Define the inital step / outer loop for topological sorting */

void topological_sort_dependencies
(
)
{ for
  ( code_object_index C = 0
  ; C < code_objects
  ; C++
  )
  {
    if(top_status[C] == unsorted)
       topological_sort_visit(C);
  }
}


/* Define the recursive step for topological sorting */

void topological_sort_visit
( code_object_index const C
)
{ top_status[C] = in_recursion;

  for
  ( code_object_dependency_index D = 0
  ; D < coi[C].dependencies
  ; D++
  )
  {
    if(top_status[coi[C].dependency[D]] == unsorted)
    {
      topological_sort_visit(coi[C].dependency[D]);
    }
    else
    if(top_status[coi[C].dependency[D]] == in_recursion)
    {
      /* Circular dependency detected
      -- do nothing */
    }
    else
    // Already 'sorted'
    {
      /* Forward edge detected
      -- do nothing */
    }
  }

  top[top_iterator++] = C;
  top_status[C] = sorted;
}


/* Define a recursive scanner for dependency path finding */

char function_is_dependent
( size_t const index
, size_t const subject_index
, char * const visited_object  // size is code_objects
)
{ visited_object[index] = 1;

  for(size_t D = 0; D < coi[index].dependencies; D++)
  {
    if( coi[index].dependency[D] == subject_index )
    {
      return 1;
    }
    else
    if( ! visited_object[coi[index].dependency[D]] )
    {
      if
      ( function_is_dependent
        ( coi[index].dependency[D]
        , subject_index
        , visited_object
        )
      )
      {
        return 1;
      }
    }
  }
  return 0; 
}

char __hanamade_test__is_dependent
( size_t const index
)
{ char visited_object[code_objects] = { 0 };
       visited_object[index]        =   1;

  for(size_t D = 0; D < coi[index].dependencies; D++)
  {
    if( coi[index].dependency[D] == coi[index].__hanamade_test__subject_index )
    {
      return 1;
    }
    else
    if( ! visited_object[coi[index].dependency[D]] )
    {
      if
      ( function_is_dependent
        ( coi[index].dependency[D]
        , coi[index].__hanamade_test__subject_index
        , visited_object
        )
      )
      {
        return 1;
      }
    }
  }
  return 0;
}

char every__hanamade_test__is_dependent
(
)
{
  char result = 1;  // look for a counter example

  for(size_t C = 0; C < code_objects; C++)
  {
    if(coi[C].__hanamade_test__)  // if C is a test
    {
      if( ! __hanamade_test__is_dependent(C))  // if C is NOT actually dependent on its subject / target
      {
        char const * const message = \"\n! UNCONNECTED :  (test)  is independent of target  %s\";
        printf(message, left_justified(coi[coi[C].__hanamade_test__subject_index].name));
        result = 0;
      }
    }
  }
  return result;
}


int main(void)
{
  printf(\"\n- Checking for unconnected test targets...\");
  if( ! every__hanamade_test__is_dependent() )
  {
    printf
    ( \"\n\"
      \"\n  No dependency path was detected for the above functions to their\"
      \"\n  named targets, suggesting an error is present in your logic.\"
      \"\n\"
      \"\n  Bridge the missing links between test(s) and target(s) to proceed.\"
      \"\n\"
    );
    return -1;
  }


  printf(\"\n- Identifying indirect dependencies...\");

  topological_sort_dependencies();


  printf(\"\n- Determining (re)test rationale...\n\");

  /* Check for source file updates
     (empty logs in log/%.i(pp) produced by make) */

  for(size_t index = 0; index < code_objects; index++)
  {
    /* Log file presence indicates either source update or
       prior test failure */

    if((coi[index].log_file = fopen(coi[index].log_path, \"r\")))
    {
      /* Getting an End Of File (EOF) value at the beginning of
         the file means its empty,
         and the corresponding source file was updated

         Getting any other value means the file is non-empty,
         indicating a prior testing failure
         (which is the default assumption, so no action is taken) */

      if(fgetc(coi[index].log_file) == EOF) coi[index].status = updated;

      /* Close and reassign NULL to log_file
         to avoid interfering with testing,
         which uses a non-NULL  log_file value to detect a failed test */

      fclose(coi[index].log_file);
      coi[index].log_file = NULL;
      remove(coi[index].log_path);
    }


    /* No log file means no update nor failure -- an implicit pass */

    else coi[index].status = passed;
  }


  /* Run topological dependency analysis
     setting non-updated objects that depend on objects
     with status:
     'updated' OR
     'depends' to 'depends' */

  for
  ( code_object_index index = 0
  ; index < code_objects
  ; index++
  )
  {
    if(coi[top[index]].status != updated)
    {
      for
      ( code_object_dependency_index D = 0
      ; D < coi[top[index]].dependencies
      ; D++
      )
      {
        /* Iterating through the code objects in
           TOPOLOGICAL order, get the status of each
           dependency.

           If the dependency has been
           'updated' or
           'depends' on anything,

           set the depending code object--
           NOT the dependency--
           status to 'depends'

           The result consistency check at the end handles
           the case of a passed test depending on a failed test.

           The status of the depending object can be changed with:
           coi[top[index]].status = <new_status>

           The status of the dependency can be accessed through:
           coi[coi[top[index]].dependency[D]].status */

        if(coi[coi[top[index]].dependency[D]].status == updated
        || coi[coi[top[index]].dependency[D]].status == depends
        )
        {
          coi[top[index]].status = depends;
        }
      }
    }
  }

  /* Identify required testing based on direct updates (source file updates)
     OR
     indirect updates
     (dependency on direct update
      OR
      dependency on dependency on ... direct update
     ) */

  size_t tests_required_to_run = 0;
  size_t updates = 0;

  for(size_t index = 0; index < code_objects; index++)
  {
    switch(coi[index].status)
    {
      case updated:
        printf(\"\n  %s  [ updated source file ]\", coi[index].name);
        updates++;

        if(coi[index].__hanamade_test__)
        { tests_required_to_run++; }
        break;

      case depends:
        printf(\"\n  %s  [ depends on: \", coi[index].name);

        /* Is this behavior you desire? */

        if(coi[coi[index].dependency[0]].status == updated
        || coi[coi[index].dependency[0]].status == depends
        ) printf(\"%s\", coi[coi[index].dependency[0]].name);

        for(size_t D = 1; D < coi[index].dependencies; D++)
          if(coi[coi[index].dependency[D]].status == updated
          || coi[coi[index].dependency[D]].status == depends
          ) printf(\", %s\", coi[coi[index].dependency[D]].name);

        printf(\" ]\");

        if(coi[index].__hanamade_test__)
        { tests_required_to_run++; }
        break;

      case  failed:
        printf(\"\n  %s  [ failing ]\", coi[index].name);

        if(coi[index].__hanamade_test__)
        { tests_required_to_run++; }
        break;

      case  passed: /* do nothing */
        break;
    }
  }


  /* Execute required tests and report results */
  if(tests_required_to_run || updates) printf(\"\n\n\");
  if(tests_required_to_run > 0) printf(\"- Testing Functions...\n\n\");
  else printf(\"- No testing required.\n\");

  printf(\"  ...\");

  for(size_t index = 0; index < code_objects; index++)
  {
    if(coi[index].__hanamade_test__ != NULL && coi[index].status != passed)
    {
      coi[index].__hanamade_test__
      (   &(coi[index].log_file)
      , coi[coi[index].__hanamade_test__subject_index].log_path
      , left_justified
        (
        coi[coi[index].__hanamade_test__subject_index].name
        )
      );

      if(coi[index].log_file != NULL)
      {
        printf
        ( \"\b\b\b%s  [ FAILED ] -- see hanamade/log\n  ...\"
        , coi[coi[index].__hanamade_test__subject_index].name
        );
        coi[index].status = failed;
      }

      else
      {
        printf
        ( \"\b\b\b%s  [ PASSED ]\n  ...\"
        , coi[coi[index].__hanamade_test__subject_index].name
        );
        coi[index].status = passed;
      }
    }
  }


  printf(\"\b\b\b   \n- Complete.\n\");


  printf(\"- Checking results for inconsistencies...\n\");

  char consistent = 1;  // true

  FILE * inconsistent_test_results_log =
  fopen(\"inconsistent-test-results.log\", \"w\");

  for(size_t index = 0; index < code_objects; index++)
  {
    char inconsistent = 0;  // reset - false

    if(coi[index].status == passed)
    {
      for(size_t D = 0; D < coi[index].dependencies; D++)
      {
        if(coi[coi[index].dependency[D]].status == failed)
        {
          inconsistent += 1;  // true
            consistent = 0;  // false

          if(inconsistent == 1)
          {
            char const * const ir_log_text_format =
            \"\n  %s  [ INCONSISTENT WITH DEPENDENCY: %s\";

            fprintf
            ( inconsistent_test_results_log
            , ir_log_text_format
            , coi[index].name
            , coi[coi[index].dependency[D]].name
            );

            printf
            ( ir_log_text_format
            , coi[index].name
            , coi[coi[index].dependency[D]].name
            );
          }
          else  // multiple inconsistencies
          {
            char const * const ir_log_text_format =
            \", %s\";

            fprintf
            ( inconsistent_test_results_log
            , ir_log_text_format
            , coi[coi[index].dependency[D]].name
            );

            printf
            ( ir_log_text_format
            , coi[coi[index].dependency[D]].name
            );
          }
        }
      }

      if(inconsistent)
      {
        char const * const ir_log_text_format =
        \" ]\";

        fprintf
        ( inconsistent_test_results_log
        , ir_log_text_format
        );

        printf
        ( ir_log_text_format
        );
      }
    }
  }


  /* WARNING: AT THE CURRENT STAGE OF DEVELOPMENT,
     THERE IS NO WAY TO DETECT INCONSISTENT TEST RESULTS.

     IN THE ORIGINAL HANAMAKE PROTOTYPE (A YEAR BEFORE IT EVEN HAD ITS NAME),
     EVERY USER FUNCTION WAS IMPLICITLY BOUND TO A TEST INCLUDED IN THE SAME
     IMPLEMENTATION FILE, BEARING THE SAME NAME AS THE USER FUNCTION,
     PREFIXED WITH 'test_'.

     THIS RESTRICTION MADE CLEAR THE CONNECTION BETWEEN USER FUNCTION AND
     UNIT TEST.

     FURTHER, THE PROTOTYPE COULD ONLY BE USED WITH C CODE, NOT C++.

     IN ORDER TO MAKE HANAMAKE A MORE FLEXIBLE, EASY TO ADOPT AND USE
     UTILITY, THESE AND OTHER RESTRICTIONS WERE LIFTED.

     HOWEVER, THIS BORE 2 IMPORTANT CONSEQUENCES

     - AMBIGUITY AS TO WHAT A TEST IS ACTUALLY TESTING, AND
     - C++ NAMESPACE (AND SUCH DEPTH) AMBIGUITY

     THE CURRENT SCHEME TO DEFINE A TEST IN HANAMAKE IS VIA A MACRO:
     'hanamake_test(your_test_name)', WHICH EVALUATES TO:
     '__hanamade_test__your_test_name'.

     EVEN IF THE 1ST CONSEQUENCE IS RESOLVED BY RESTRICTING TEST NAMES TO
     FUNCTION SIGNATURES, AND CREATING A HANAMADE NAMESPACE

       ( __hanamade_test__CPP_namespace::function(...)

       would potentially require a new namespace for every C++ function at
       minimum.

       __hanamade_test__::CPP_namespace::function(...)

       reduces the global namespace issue to only a single global namespace
       )

     THIS DOES NOT SOLVE THE ISSUE OF NAMESPACE DECLARATIONS

       ( To define a member of a namespace, you must declare the namespace
       as so:

         namespace NS1 { member_name; }

       namespace NS1 { CPP_namespace::function(...); }

       is invalid--it must be declared as

       namespace NS1 { namespace CPP_namespace { type function(...); } }

       This is not viable in general with a macro alone--it fundamentally
       requires ** some form of ** parsing the C++ source code in advance
       to achieve via macro.
       )
  */

  if(consistent)
  {
    char const * const consistent_results_message =
    \"\n  CONSISTENT -- Your code test results are consistent with each other.\"
    \"\n\"
    \"\n                Specifically, no function whose test passed\"
    \"\n                  depends upon a function whose test failed.\n\"
    ;

    /* DO NOT PRINT TO LOG. THE RESULTS ARE CONSISTENT. REMOVE THE LOG. */

    remove(\"inconsistent-test-results.log\");

    printf(consistent_results_message);
  }
  else
  {
    char const * const ir_log_text_format = \"\n\"
    \"\n  INCONSISTENT -- Your code test results are NOT consistent with each other.\"
    \"\n\"
    \"\n                  Specifically, some functions whose tests passed\"
    \"\n                         depend upon functions whose tests failed.\n\"
    ;

    fprintf
    ( inconsistent_test_results_log
    , ir_log_text_format
    );

    printf
    ( ir_log_text_format
    );
  }

  fclose(inconsistent_test_results_log);


  printf(\"\n- Valgrind Memcheck Result...\n\");

  return 0;
}
"
