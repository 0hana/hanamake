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
#include <stdio.h>
"

# Insert unit test declarations
test_names="$(basename -a ${2} | grep '__hanamade_test__$')"
for name in ${test_names}
do
>>${1} echo "void ${name}"
>>${1} echo "( FILE      ** const __hanamade_test__log_file"
>>${1} echo ", char const * const __hanamade_test__log_path"
>>${1} echo ") ;"
>>${1} echo
done

# Get number of code objects
>>${1} echo "#define code_objects $(echo ${2} | wc -w)"

function_names="$(basename -a ${2})"
echo ${function_names} \
| tr ' ' '\n' \
| cat -n \
| sed 's/[\t ]*\([0-9][0-9]*\)[\t ]*\([(),0-9:A-Z_a-z][(),0-9:A-Z_a-z]*\)/s\/\2\/(\1-1)\//' \
> 0hana-main.c.sed

for path in ${2}
do : \
	; grep 'bl\|call'     "${path}" \
	| grep -vw "$(basename ${path})" \
	| grep -ow "$(echo ${function_names} | sed 's/\([(),0-9:A-Z_a-z][(),0-9:A-Z_a-z]*\)[ ]*/\1\\|/g')" \
	| LC_COLLATE=C sort -u \
	>  ${path}.dependencies
	mv ${path}.dependencies ${path}
done

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
  ) ;
  /*------------------------------------------*/
  enum code_object_status status;
}

coi[code_objects] =
{\
"

# Identify longest code object name for test output formatting (relative right justify names)
hanamade_test_prefix_length=$(printf '__hanamade_test__' | wc -m)
translation_length=8
longest_base=0
for name in $(basename -a ${2})
do
	name_length=$(printf ${name} | wc -m)
	if test -n "$(echo   ${name} | grep '__hanamade_test__$')"
	then name_length=$((${name_length} - ${hanamade_test_prefix_length} + ${translation_length}))
	fi
	if test ${name_length} -gt ${longest_base}
	then longest_base=${name_length}
	fi
done

# Initialize the code object information ("coi") array
for identity in ${2}
do
	base=$(basename ${identity})
	base_length=$(printf ${base} | wc -m)
	# name string
	if test -n "$(echo ${base} | grep '__hanamade_test__$')"
	then
	base_length=$((${base_length} - ${hanamade_test_prefix_length} + ${translation_length}))
	>>${1} echo "  { \"$(for i in $(seq $((${longest_base} - ${base_length}))); do printf ' '; done)$(echo "${base}" | sed 's/__hanamade_test__$//')\""
	else
	>>${1} echo "  { \"$(for i in $(seq $((${longest_base} - ${base_length}))); do printf ' '; done)${base}\""
	fi

	>>${1} echo "  , \"$(echo ${identity}.log | sed 's/^build\//log\//')\""
	                                       # log_path string
	>>${1} echo "  , NULL"                 # log_file FILE pointer
	>>${1} echo "  , NULL"                 # dependency
	>>${1} echo "  , 0"                    # dependencies

	if test -n "$(echo ${base} | grep '__hanamade_test__$')"
	then
	>>${1} echo "  , ${base}"              # __hanamade_test__ function pointer
	else
	>>${1} echo "  , NULL"                 # __hanamade_test__ function NULL pointer (not a test)
	fi

	>>${1} echo "  , failed"               # code object status (default: failed)

	>>${1} echo "  } ,"
	>>${1} echo
done

>>${1} printf '%s' \
"\
} ;


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
{
	for
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
{
	top_status[C] = in_recursion;

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


int main(void)
{
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
				printf(\"\n  %s%s  [ updated ]\", (coi[index].__hanamade_test__ ? \"(test)  \" : \"\"), coi[index].name);
				updates++;

				if(coi[index].__hanamade_test__)
				{ tests_required_to_run++; }
				break;

			case depends:
				printf(\"\n  %s%s  [ depends on: \", (coi[index].__hanamade_test__ ? \"(test)  \" : \"\"), coi[index].name);

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
				printf(\"\n  %s%s  [ failing ]\", (coi[index].__hanamade_test__ ? \"(test)  \" : \"\"), coi[index].name);

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
			coi[index].__hanamade_test__(&(coi[index].log_file), coi[index].log_path);

			if(coi[index].log_file != NULL)
			{
				printf(\"\b\b\b%s  [ FAILED ] -- see hanamade/%s\n  ...\", coi[index].name, coi[index].log_path);
				coi[index].status = failed;
			}

			else
			{
				printf(\"\b\b\b%s  [ PASSED ]\n  ...\", coi[index].name);
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
		\"\n                depends upon a function whose test failed.\n\"
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
		\"\n                  depend upon functions whose tests failed.\n\"
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
