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

make_log_directories()
{
  find -P source-link -type l -exec sh -c \
  '
  while test ${#} -gt 0
  do

    find                   \
    -H "${1}"              \
    \( -name '\''*.c'\''   \
    -o -name '\''*.cpp'\'' \
    \) -type f             \
    -exec sh -c            \
    '\''
    while test ${#} -gt 0
    do

      directory="$(dirname "${1}")"
      mkdir -p "log${directory#source-link}"  # remove source-link from the
                                              # beginning of:
                                              #
                                              # source-link/.../*.c(pp)
      shift 1

    done
    '\'' \
    "inner-find make_log_directories" \{\} \+

    shift 1

  done
  ' \
  "outer-find make_log_directories" '{}' '+'
}

make_log_directories
mv log previous-log
make_log_directories

find -P source-link -type l -exec sh -c \
'
while test ${#} -gt 0
do

  find                   \
  -H "${1}"              \
  \( -name '\''*.c'\''   \
  -o -name '\''*.cpp'\'' \
  \) -type f             \
  -exec sh -c            \
  '\''
  while test ${#} -gt 0
  do

    convert_to_log="log${1#source-link}"  # change source-link to log
    log_c_path="${convert_to_log%pp}"     # get the log/.../*.c

    pp="${convert_to_log#${log_c_path}}"  # get plusplus presence
    log_group="${log_c_path%c}i${pp}"     # make log/.../*.i(pp)

    if test -d "previous-${log_group}"
    then mv    "previous-${log_group}" "${log_group}"
    fi

    shift 1

  done
  '\'' \
  "inner-find make log_groups" \{\} \+

  shift 1

done
' \
"outer-find make log_groups" '{}' '+'

rm -r previous-log
