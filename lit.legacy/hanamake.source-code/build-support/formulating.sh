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
#include <unistd.h>
#include <pthread.h>

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
'formulating.sh: gathering %.i(pp) pathways' '{}' '+' \
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
>>${1} printf '%s\n\n' "} ;"
>>${1} cat "$(command -v hanamake).source-code/build-support/formulation.c"
