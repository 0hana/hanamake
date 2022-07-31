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

if ! test -d previous-source-link
then mkdir   previous-source-link  # illude hanamake to simplify code logic
fi


#  If hanamake was previously run, then a 'previous-source-link' will
#  be present, containing a copy of every source code file used in
#  the previous build.
#
#  We want to contrast every current source file under source-link
#  against those under 'previous-source-link',
#  and update file modification time-stamps where differences exist.
#
#  This is to deal with situations such as the user swapping the names of
#  2 or more files, which DOES NOT update file modification times, but
#  COULD affect inter-source relations:
#
#  Since moving and renaming files does not affect file modification times,
#  'make' will not detect such changes, and thus not rebuild code,
#  giving the impression that everything is A-OK,
#  even if you've just broken the entire code-base by name shuffling.
#
#  This step can be optimized for 'git' workflows by replacing all the
#  'previous-source-link' related code with 2 or 3 calls to a command like:
#
#  touch \
#  $( git diff --staged --name-status \
#   | grep -v "D$(printf '\t')" \
#   | cut -f 2 \
#   | grep 'source/'
#   )
#
#  If you have 'git' workflow, I highly recommend it, as
#  'hanamake' was partly designed for use as a scalable git pre-commit hook

find -P source-link -type l -exec sh -c \
'
while test ${#} -gt 0
do

  2>/dev/null find          \
  -H "${1}"                 \
  \( -name '\''*.[ch]'\''   \
  -o -name '\''*.[ch]pp'\'' \
  \) -type f                \
  -exec sh -c               \
  '\''
    while test ${#} -gt 0
    do

      if test -f "previous-${1}"
      then

        if test -n "$(diff  "${1}" "previous-${1}")"
        then touch "${1}"  # to update modification time-stamp for detection
                           # by make
        fi

      else touch "${1}"  # this is in case of hanamake TERMination before
                         # "committing" source changes to previous-source-link
                         # in prior run:
                         #
                         # if such sudden TERMination occurred,
                         # then it is possible that a file whose name
                         # was swapped but not committed as a previous-source
                         # (thus no time-stamp update) would not be detected by
                         # make
                         #
                         # if such pre-mature TERMination does not occur,
                         # then there is no material performance penalty, since,
                         # if "${1}" really is a new file,
                         # make would detect it for re-making anyway
                         #
                         # otherwise, the penalty is only the rebuilding of
                         # the uncommitted files, which is at worst a fresh
                         # rebuild as if all files were new or modified,
                         # partially obviating the "hanamake clean" function
      fi

      shift 1

    done
  '\'' \
  "inner-find time protection loop" \{\} \+

  # the \{\} \+ means to use all found files as positional parameters to
  # the -exec sh -c command

  shift 1

done
' \
"outer-find time protection loop" '{}' '+'


#  Commit current state of <source-directories>

rm -r previous-source-link
mkdir previous-source-link
find -P source-link -type l -exec sh -c \
'
while test ${#} -gt 0
do

  2>/dev/null find          \
  -H "${1}"                 \
  \( -name '\''*.[ch]'\''   \
  -o -name '\''*.[ch]pp'\'' \
  \) -type f                \
  -exec sh -c               \
  '\''
  while test ${#} -gt 0
  do

    mkdir -p  "$(dirname "previous-${1}")"
    cp "${1}"            "previous-${1}"
    shift 1

  done
  '\'' \
  "inner-find recording to previous" \{\} \+

  shift 1

done
' \
"outer-find recording to previous" '{}' '+'
