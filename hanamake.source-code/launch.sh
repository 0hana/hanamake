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
  '1>&2 printf "\n%s\n" "hanamake:  Exiting. (CODE ${?})"' \
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
  | tee complete.log 1>&4 ; \
} 3>&1
)\
"
exec 4>&-  # Close off fd4 connection to fd1


# Display a notification if make failed

test "${MAKE_EXIT}" -eq 0 \
|| \
if test -n "$(find build -name '*.error' -type f)"
then

  printf '\n  BUILD ABORTED -- See hanamade/complete.log\n' \
  | tee -a complete.log

   find build -name '*.error' -type f \
  -exec sh -c \
  'while test ${#} -gt 0; do cat "${1}"; shift; done' \
  "hanamake.source-code/launch.sh: build-errors find" '{}' '+' \
  > notification

  ( printf "\n  Press Q to close this notification\n\n"
    cat notification
  ) \
  | less

  >> complete.log printf '\n'
  >> complete.log cat notification
  rm notification
  exit 253

else

  printf '\n  BUILD ABORTED -- See hanamade/complete.log\n' \
  | tee -a complete.log
  exit 252

fi


#  Run the unit tester and exit with final status code
#    0 = All Clear
#  128 = See complete.log

clear
printf '%s\n%s\n%s\n%s\n' \
       '---------------' \
       'BUILD SUCCEEDED' \
       '---------------' \
       '-- EXECUTING --' \
| tee -a complete.log

if 2>&1 valgrind \
  --tool=memcheck \
  --leak-check=full \
  --show-leak-kinds=all \
  -q -s ./0hana-main \
| tee -a complete.log \
\
&& ! grep -q '^! UNCONNECTED :'                  complete.log \
&& ! grep -q '\[ FAILED \]'                      complete.log \
&&   grep -q '^==[0-9][0-9]*== ERROR SUMMARY: 0' complete.log \
&& rm complete.log \
&& rm -r log
then

  printf '\n%s%s\n%s\n%s\n%s\n%s%s\n' \
         'uuuuuuuuuuuuuuuuu' \
         'uuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuu' \
         ' ' \
         '  PASS -- All requirements were met' \
         ' ' \
         'nnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnn' \
         'nnnnnnnnnnnnnnnnn'

  exit   0  # All Clear

else

  printf '\n%s%s\n%s\n%s\n%s\n%s%s\n' \
         'uuuuuuuuuuuuuuuuu' \
         'uuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuu' \
         ' ' \
         '  FAIL -- See hanamade/complete.log' \
         ' ' \
         'nnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnn' \
         'nnnnnnnnnnnnnnnnn' \
  | tee -a complete.log
  find log -name '*__hanamade_test__.log' -type f -exec sh -c \
  '
  >> complete.log cat "${@}"
  ' \
  'hanamake.source-code/launch.sh: complete.log concatenation' '{}' '+'

  exit 128  # See complete.log

fi
