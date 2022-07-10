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

2>/dev/null find   \
  -L source-link   \
  \( -name '*.c'   \
  -o -name '*.cpp' \
  \) -type f       \
  -exec sh -c      \
  '
  make_log_directories()
  {
    while test ${#} -gt 0
    do

      log_group="$(              \
        printf "%s" "${1}"       \
        | sed                    \
        -e "s/^source-link/log/" \
        -e "s/.c$/.i/"           \
        -e "s/.cpp$/.ipp/"       \
      )"

      mkdir -p "$(dirname "${log_group}")"

      shift 1

    done
  }

  make_log_directories "${@}"
  mv log previous_log
  make_log_directories "${@}"

  while test ${#} -gt 0
  do

    log_group="$(              \
      printf "%s" "${1}"       \
      | sed                    \
      -e "s/^source-link/log/" \
      -e "s/.c$/.i/"           \
      -e "s/.cpp$/.ipp/"       \
    )"

    if test -d "previous_${log_group}"
    then mv    "previous_${log_group}" "${log_group}"
    fi

    shift 1

  done

  rm -r previous_log
  ' \
  '_' '{}' '+'
