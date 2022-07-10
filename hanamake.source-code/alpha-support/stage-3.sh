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

if test -d source-link  # Does a directory named 'source-link' exist?
then rm -r source-link  # Then remove it and all its contents
fi

#  If hanamake was run previously, there should be a directory containing
#  symbolic links to all the then specified source directories--delete it
#  to remake anew (via 'link_sources()')


link_sources()
{
(
  cd ..  # We need to be outside hanamade in case a relative path was specified

  if test "${mode}" = -s
  then

    shift 1  # remove the initial '-s' parameter

    while test ${#} -gt 0

    # While the number of specified <source-directories> is greater than 0

    do  # the following

      mkdir -p "hanamade/source-link$(dirname "$(realpath -- "${1}")")"
      ln -s "$(realpath -- "${1}")" "hanamade/source-link$(realpath -- "${1}")"

      shift 1

    done

  else  # no directories were specified, default to 'source'

    mkdir hanamade/source-link  # Make source-link directory

    ln -s ../../source hanamade/source-link/source

    # From within source-link,
    # go back to hanamade,
    # then to ../hanamade,
    # and link to source

  fi
)
}


#  Link together all user specified <source-directories>
#  (Or the default 'source' if none were specified)
link_sources "${@}"
