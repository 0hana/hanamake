#!/bin/sh
#  Copyright (C) 2022 Hanami Zero
#
#  This file is part of hanamake,
#  a C and C++ development testing utility.
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

mkdir -p \
   hanamade
cd hanamade


#  Remove prior source symbolic link

rm -f source


#  Define Usage text

Usage="Usage:  hanamake [ clean | -s <source-code-directory> ]"


#  Determine if source code directory has custom name

if (test ${#} -eq 1 && test ${1} = clean) \
|| (test ${#} -eq 2 && test ${1} = -s) \
|| (test ${#} -eq 0)
then
  if test ${#} -eq 1
  then cd .. \
    && rm -r hanamade \
    && echo 'hanamake:  All hanamade files removed.' \
    && exit
  fi
  if test ${#} -eq 2
  then ln -s ../"${2}" source; source="${2}"
  else ln -s ../source source; source= #zero
  fi
else
  1>&2 echo "${Usage}"
  exit 1
fi


#  Check that source is actually a link to a directory

issue="hakuna matata"
if ! test -d source; then issue="is not a directory"; fi
if ! test -e source; then issue="does not exist"    ; fi

if test "${issue}" != "hakuna matata"
then
  if test -n "${source}"
  then
    1>&2 echo "hanamake:  specified <source-code-directory> '${source}'"
    1>&2 echo "           ${issue}."
  else
    1>&2 echo "hanamake:  default <source-code-directory> 'source'"
    1>&2 echo "           ${issue}."
    1>&2 echo
    1>&2 echo "           You can specify a <source-code-directory> using"
    1>&2 echo "           the  -s option:"
    1>&2 echo
    1>&2 echo "           ${Usage}"
  fi
  1>&2 echo
  1>&2 echo   "           Exiting."
  exit 2
fi


#  Ensure a previous_source directory is available for comparison
#
#  It is copied from source at the end of the script

if ! test -d previous_source
then mkdir   previous_source
fi


#  Identify changes in content between identically named files in
#  source and previous_source and overwrite source file modification
#  times
#
#  This is to deal with situations such as the user swapping the names
#  of 2 or more source files, which would not update file modification
#  time, thus 'make' would not detect the update, potentially causing
#  difficult to diagnose problems

for file in $(find -H source \( -name '*.[ch]' -o -name '*.[ch]pp' \) -type f)
do
  if test -f previous_${file}
  then
    if test -n "$(diff previous_${file} ${file})"
    then touch  ${file}
    fi
  fi
done


#  Find hanamake-components directory -- adjust based on install

hanamake_components="$(dirname $(command -v hanamake))/hanamake-components"


#  Provide and maintain a logs directory to record updates and errors

log_groups=$(\
  find -H source \( -name '*.c' -o -name '*.cpp' \) -type f \
  | sed -e 's/^source/logs/' -e 's/.c$/.i/' -e 's/.cpp$/.ipp/' \
)

mkdir -p $(dirname ${log_groups})
mv logs previous_logs
mkdir -p $(dirname ${log_groups})

for group in ${log_groups}
do
  if test -d previous_${group}
  then mv previous_${group} ${group}
  fi
done

rm -r previous_logs


#  Invoke the hanamakefile

make \
  -j -r hanamake_components="${hanamake_components}" \
  -f "${hanamake_components}/makefile" || exit 3


#  Run the run the unit tester

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
&& rm 0hana-main.log
then
  echo
  echo '* Final Result... -- PASS -- No errors encountered.'
  rm -r logs
  ctatus='0'
else
  echo \
  | tee -a 0hana-main.log
  echo '* Final Result... -- FAIL -- See hanamade/logs.' \
  | tee -a 0hana-main.log
  ctatus='128'
fi


#  Record current state of <source-code-directory>

rm -r         previous_source
cp -Hr source previous_source


#  Return exit ctatus --
#  zsh treats 'status' as special and blocks use. Peaches.

exit ${ctatus}
