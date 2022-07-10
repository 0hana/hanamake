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

#  Define an error printing function to notify the user of an issue

issue()
{
  1>&2 printf "hanamake:  %s\n" "${1}"
  shift 1

  while test ${#} -gt 0
  do

  1>&2 printf "           %s\n" "${1}"
  shift 1

  done

  # Example:
  #
  # issue "parameter 1 text" "parameter 2 text" ... "parameter N text"
  #
  # hanamake:  parameter 1 text
  #            parameter 2 text
  #            ...
  #            parameter N text
}


#  Define a function to inform the user upon pertinent issue
#  that the name 'hanamade' is reserved

inform_hanamade_reserved()
{
  # Note that back-slash ('\') denotes a line continuation

  issue \
    "the file-path name 'hanamade' is reserved by hanamake." \
    "" \
    "However, if you need to use that name for some reason," \
    "the POSIX shell scripts that require it--" \
    "" \
    "'$(realpath -- "${0}")'" \
    "'$(command -v hanamake).source-code/alpha-support/stage-'[1-5]'.sh'" \
    "" \
    "--can be patched to use a different name. Note that" \
    "THIS IS NIETHER SUPPORTED NOR RECOMMENDED NOR A GRANT OF PERMISSION." \
    "" \
    "Disclaimer aside," \
    "such a patch might be automated via a stream edit:" \
    "" \
    "sed -i.bup -s 's/ hanamade/ some-other-name/g' \\" \
    "'$(realpath -- "${0}")' \\" \
    "'$(command -v hanamake).source-code/alpha-support/stage-'[1-5]'.sh'" \
    "" \
    "And if later needed, undone by backup restoration:" \
    "" \
    'restore_hanamake_backups()' \
    '{ while test ${#} -gt 0; do mv "${1}".bup "${1}"; shift 1; done; }' \
    "" \
    "restore_hanamake_backups \\" \
    "'$(realpath -- "${0}")' \\" \
    "'$(command -v hanamake).source-code/alpha-support/stage-'[1-5]'.sh'"
}


#  Reserve 'hanamade' directory for iterative multi-execution
#  build and testing efficiency, organization, clean-up, and user debug mode

if ! 2>/dev/null mkdir -p hanamade  # If 'hanamade' directory does not exist
                                    # and we cannot make it
then                                # Then inform the user of the issue and exit

  trap '1>&2 printf "\n%s\n" "hanamake:  Exiting. (CODE ${?})"' EXIT

  # Upon encountering an 'exit' command, run the above trap code first

  if test -f hanamade

  # If there is a file with the name 'hanamade' in their current directory

  then  # provide contextual information to the user before exiting

    issue "unable to make the 'hanamade' directory in current directory," \
          "non-directory file 'hanamade' already exists." \
          ""

    inform_hanamade_reserved

    exit 255

  else  # the user might not have write-access for their current directory

    issue "unable to make the 'hanamade' directory in current directory," \
          "do you have permission to write here?"

    exit 254

  fi

fi
