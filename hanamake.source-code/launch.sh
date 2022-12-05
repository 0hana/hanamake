#!/bin/sh
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

Usage=\
"\
Usage: hanamake [ -s <source-directory> ... ]
     | hanamake debug [ <function-name> ... ]
     | hanamake clean \
"


#  Import Stage-1 support code:
#  - 'issue()'
#  - 'inform_hanamade_reserved()'
#
#  And execute 'hanamade' reservation checks

. "$(command -v hanamake).source-code/launch-support/stage-1.sh"


#  Import Stage-2 support code:
#  - 'mode=alpha'
#  - 'validate()'
#
#  And 'validate()' command input (determines operating mode)

. "$(command -v hanamake).source-code/launch-support/stage-2.sh"


#  Process debug support code in launch-support/debug.sh

if test "${mode}" = debug
then

  . "$(command -v hanamake).source-code/launch-support/debug.sh"
  exit

fi


#  Process cleaning

if test "${mode}" = clean
then

  rm -r hanamade
  issue "All hanamade files removed."
  exit

fi


#  CRITICAL POINT: From here on, all code execution must occur within 'hanamade'
#  =============================================================================

cd hanamade


#  Import and execute Stage-3 source linking support code:

. "$(command -v hanamake).source-code/launch-support/stage-3.sh"


#  Import and execute Stage-4 time protection support code:

. "$(command -v hanamake).source-code/launch-support/stage-4.sh"


#  Import and execute Stage-5 test log maintenance support code:

. "$(command -v hanamake).source-code/launch-support/stage-5.sh"


#  Invoke the hanamake internal makefile

trap \
  '1>&2 printf "\n%s\n" "hanamake:  Exiting. (CODE ${?})"; rm -f build.log' \
  EXIT INT

hanamake_source_code="$(command -v hanamake).source-code"

exec 4>&1  # Thanks @mtraceur -- See <https://stackoverflow.com/a/30659751>
MAKE_EXIT="\
$(
{
  { \
    2>&1 \
    make \
      -j -r hanamake_source_code="${hanamake_source_code}" \
      -f "${hanamake_source_code}/build-support/makefile"  \
    3>&- ; \
    echo "${?}" 1>&3 ; \
  } 4>&- \
  | tee build.log 1>&4 ; \
} 3>&1
)\
"
exec 4>&-  # Close off fd4 connection to fd1


# Display a notification if make failed

test "${MAKE_EXIT}" -eq 0 \
|| \
if test -n "$(find build -name '*.error' -type f)"
then

   find build -name '*.error' -type f \
  -exec sh -c \
  'while test ${#} -gt 0; do cat "${1}"; shift; done' \
  "hanamake.source-code/launch.sh: build-errors find" '{}' '+' \
  > 0hana-main.log

 ( printf "\n  Press Q to close this notification\n\n"
   cat 0hana-main.log
 ) \
 | less

  printf '\n  BUILD ABORTED.\n' | tee -a build.log
  >> build.log cat 0hana-main.log
  mv build.log     0hana-main.log

  exit 253

else

  printf '\n  BUILD ABORTED.\n' | tee -a build.log
  mv build.log     0hana-main.log

  exit 252

fi


#  Run the unit tester and exit with final status code
#    0 = All Clear
#  128 = See 0hana-main.log

printf '%s\n%s\n%s\n%s\n' \
       '---------------' \
       'BUILD SUCCEEDED' \
       '---------------' \
       '-- EXECUTING --' \
| tee 0hana-main.log

if 2>&1 valgrind \
  --tool=memcheck \
  --leak-check=full \
  --show-leak-kinds=all \
  -q -s ./0hana-main \
| tee -a  0hana-main.log \
\
&& ! grep -q '^! UNCONNECTED :' 0hana-main.log \
&& ! grep -q '\[ FAILED \]'     0hana-main.log \
&&   grep -q 'ERROR SUMMARY: 0' 0hana-main.log \
&& rm 0hana-main.log \
&& rm -r log
then

  printf '\n%s\n%s\n' \
         '% Final Result...' \
         '-- PASS -- No errors encountered.'

  exit   0  # All Clear

else

  printf '\n%s\n%s\n' \
         '% Final Result...' \
         '-- FAIL -- See hanamade/0hana-main.log' \
  | tee -a 0hana-main.log
  find log -name '*.log' -type f -exec sh -c \
  '
  >> 0hana-main.log cat "${@}"
  ' \
  'hanamake.source-code/launch.sh: 0hana-main.log concatenation' '{}' '+'

  exit 128  # See 0hana-main.log

fi
