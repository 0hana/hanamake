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

hanamake_source_code="$(command -v hanamake).source-code"

make \
  -j -r hanamake_source_code="${hanamake_source_code}" \
  -f "${hanamake_source_code}/build-support/makefile" || exit ${?}


#  Run the unit tester

echo
echo '-- EXECUTING --'
if 2>&1 valgrind \
  --tool=memcheck \
  --leak-check=full \
  --show-leak-kinds=all \
  -q -s ./0hana-main \
| tee 0hana-main.log \
\
&& ! grep -q '\[ FAILED \]'     0hana-main.log \
&&   grep -q 'ERROR SUMMARY: 0' 0hana-main.log \
&& rm 0hana-main.log \
&& rm -r log
then status=0
  echo
  echo '~ Final Result... -- PASS -- No errors encountered.'
else status=128
  echo \
  | tee -a 0hana-main.log
  echo '~ Final Result... -- FAIL -- See hanamade/0hana-main.log' \
  | tee -a 0hana-main.log
  find log -name '*.log' -type f -exec sh -c \
  '
  >> 0hana-main.log cat "${@}"
  ' \
  '_' '{}' '+'
fi


#  Return exit status

exit ${status}
