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

mode=alpha  # Default operating mode -- Execute Everything
            # Determine ultimate operating mode during 'validate()'

validate()
{
  # Make a temporary directory to store names of user specified directories
  # so we can quickly check for duplicates during the 'while' loop below

  duplicate="$(mktemp -d)"

  # Set a trap on function exit to remove our temporary files under ${duplicate}

  trap \
  '1>&2 printf "\n%s\n" "hanamake:  Exiting. (CODE ${?})"; rm -r ${duplicate}' \
  EXIT

  # Protect the hanamade directory from implicit or explicit <source-directory>
  # specification
  #
  # The user specifying the current directory,
  # or any of its ascendant directories,
  # (a directory collision error) will cause a CODE 6 exit
  # Specifying the hanamade directory causes a CODE 2 exit

  mkdir -p "${duplicate}$(dirname "$(realpath -- hanamade)")"
  > "${duplicate}$(realpath -- hanamade)" printf "%s\n" "hanamade"


  # Identify operating mode

  if test ${#} -gt 0

  # If the number of function parameters is greater than 0

  then  # operating mode is described by parameter 1 ("${1}")

    case "${1}" in  # see if "${1}" matches 1 of the following options:

      clean) mode=clean;;  # means: remove the hanamade directory and contents
      debug) mode=debug;;  # means: if test failure logs exist, enter debugger
         -s) mode=-s   ;;  # means: there are multiple source code directories
          *) mode=error;;  # means: invalid input (* means: none-of-the-above)

    esac
    shift 1

    if { test "${mode}" = clean && test ${#} -gt 0; } \
    || { test "${mode}" = -s    && test ${#} -eq 0; }

    # If mode is 'clean' and there are more than 0 remaining parameters

    then  # the input is invalid -- clean mode does not accept parameters

      mode=error

    fi

  fi

  if test "${mode}" = error

  # If mode is 'error'

  then  # the user made an error entering the command -- display usage and exit

    1>&2 printf "%s\n" "${Usage}"
    exit 1

  fi

  # So far so good
  # Loop through each user input command parameter specifying a
  # <source-directory> ...

  while test ${#} -gt 0 && test "${mode}" = -s

  # While there are unvalidated parameters and the mode is '-s'

  do  # the following

    if test "$(realpath -- "${1}")" = "$(realpath -- hanamade)"

    # If the real path of the <source-directory>
    # (specified with "${1}") is the hanamade directory

    then  # notify the user that 'hanamade' is reserved

      inform_hanamade_reserved

      exit 2

    elif test -f "${duplicate}$(realpath -- "${1}")"

    # Otherwise, if the <source-directory> is a duplicate to one we have already
    # processed (meaning it has a matching real path--see the 'else' code below)

    then  # notify the user that a duplicate <source-directory> is not permitted
          # and exit

      issue "cannot process duplicate <source-directory>" \
            "" \
            "'${1}' duplicates '$(cat "${duplicate}$(realpath -- "${1}")")'" \
            "" \
            "(They share realpath '$(realpath -- "${1}")')"

      exit 3

    elif ! test -e "${1}"

    # Otherwise, if the specified <source-directory> does not exist

    then  # notify the user and exit

      issue "specified <source-directory> '${1}' does not exist"

      exit 4

    elif ! test -d "${1}"

    # Otherwise, if the specified <source-directory> is not a directory

    then  # notify the user and exit

      issue "specified <source-directory> '${1}' is not a directory"

      exit 5

    else  # the specified <source-directory> is valid so far
          #
          # Mirror the <source-directory> real path under ${duplicate} and store
          # its original text as the sole line in that file for later detection
          # of duplicates in a code 3 situation or nesting in a code 6 situation
          #
          # (see the exit 3 issue above and exit 6 issue below)

      if 2>/dev/null mkdir -p "${duplicate}$(dirname "$(realpath -- "${1}")")" \
      && 2>/dev/null > "${duplicate}$(realpath -- "${1}")" printf "%s\n" "${1}"
      then :

        # Do nothing -- successfully made directory and link-info file

      else

        issue "cannot process a <source-directory> that is:" \
              "" \
              "- a descendant of a previously specified directory" \
              "- a descendant of the hanamade directory" \
              "- an ascendant of a previously specified directory" \
              "- an ascendant of the hanamade directory" \
              "" \
              "A consequence of these rules is that:" \
              "" \
              "  Niether the working directory nor any of its ascendants" \
              "  can be processed, as the working directory will always be" \
              "  made to contain the hanamade directory as the first order" \
              "  of business for the hanamake program" \
              "" \
              "  Further, the system root directory '/' (\"slash\")" \
              "  cannot be processed as it is ascendant to all others"

        exit 6

      fi

    fi

    shift 1  # Discard the first parameter, replacing it with the next
             # (i.e. replace the value of ${1} with ${2}, ${2} with ${3}, etc.)

  done  # End of '-s <source-directory>' processing loop


  if test "${mode}" = alpha

  # If no directories were specified

  then  # Check if the default <source-directory> 'source' exists

    if ! test -e source

    # If the default <source-directory> does not exist

    then  # notify the user and exit

      issue "default <source-directory> 'source' does not exist"

      exit 7

    elif ! test -d source

    # Otherwise, if default <source-directory> is not a directory

    then  # notify the user and exit

      issue "default <source-directory> 'source' is not a directory"

      exit 8

    fi

  fi


  # If there are no additional parameters and mode is debug

  if test "${mode}" = debug
  then

    if ! test -f hanamade/0hana-main.log
    then

      issue "no 'hanamade/0hana-main.log' -- nothing for 'debug' to target"

      exit 9

    else

      # Search through 'source-link' for all .c .cpp .h .hpp files
      # For each found, if it doesn't have a matching file
      # under 'previous-source-link', then user source has been changed
      #
      # (either a new/renamed file or content change)
      #
      # Then through 'previous-source-link' for all .c .cpp .h .hpp files
      # For each found, if it doesn't have a corresponding file
      # under 'source-link', then user source has been changed
      #
      # (a removed or renamed file)

      if test modified = "$(
        cd hanamade
        2>/dev/null find -P source-link -type l -exec sh -c \
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
          do  # For each current source file,

            if ! test -f "previous-${1}" \
            ||   test -n "$(diff  "${1}" "previous-${1}")"

            # If it does not have a previous version,
            # (new file)
            # OR its current version is different than its previous version
            # (modified)

            then printf "%s\n" "modified"
                 return  1  # causes inner-find to return non-zero

            # Then the source code-base has been modified
            # so debugging must wait until the code-base has been retested

            else  shift   1
            fi

          done
          '\'' \
          "inner-find debug source-link _modified_ files search" \{\} \+ \
          && shift  1 \
          || return 1  # causes outer-find to return non-zero

        done
        ' \
        "outer-find debug source-link _modified_ files search" '{}' '+'
      )" \
      || test deleted = "$(
        cd hanamade
        2>/dev/null find        \
        -P previous-source-link \
        \( -name '*.[ch]'       \
        -o -name '*.[ch]pp'     \
        \) -type f              \
        -exec sh -c             \
        '
          while test ${#} -gt 0
          do  # For each previous (version of) source file,

            if ! test -f "${1#previous-}"

            # If it does not have a current version

            then  printf "%s\n" "deleted"
                  return  2  # causes find to return non-zero

            # Then it was deleted (the code-base has been modified)
            # so debugging must wait until the code-base has been retested

            else  shift   1
            fi

          done
        ' \
        "find debug source-link _deleted_ files search" '{}' '+' \
      )"
      then

        issue \
          "'debug' mode cannot be used until your code modifications are tested"

        exit 10

      fi  # source change (CODE 10)
    fi  # no compiled-log (CODE 9)


    while test ${#} -gt 0

    # While there are unvalidated parameters and the mode is 'debug'

    do  # check to see if the specified <function-name> has a failure log

      if test -z "$(2>/dev/null find hanamade/log -name "${1}" -type f)"
      then

        issue "no failure log found for specified <function-name> '${1}'"

        exit 11

      fi

    done  # no failure log (CODE 11)

  fi  # 'debug' mode


  trap - EXIT  # disarms the trap

  rm -r "${duplicate}"  # remove temporary files
}


#  Execute command input validation

validate "${@}"
