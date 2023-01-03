#!/bin/sh
#  Copyright (C) 2022 Hanami Zero
#
#  This file is part of lit,
#  a C and C++ development utility.
#
#  lit is free software: you can redistribute it and/or modify
#  it under the terms of the GNU Affero General Public License --
#  the superset of version 3 of the GNU General Public License --
#  as published by the Free Software Foundation.
#
#  lit is distributed in the hope that it will be useful,
#  but WITHOUT ANY WARRANTY; without even the implied warranty
#  of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
#  See the GNU Affero General Public License for more details.
#
#  You should have received a copy of the GNU Affero General Public License
#  along with lit. If not, see <https://www.gnu.org/licenses/>.

print()
{
  printf   'lit.bvt:  %s\n' "${1}"
  shift

  while test ${#} -gt 0
  do

    printf '          %s\n' "${1}"
    shift

  done

  #uuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuu
  # Example:
  #
  # print "parameter 1 text" "parameter 2 text" ... "parameter N text"
  #
  # lit.bvt:  parameter 1 text
  #           parameter 2 text
  #           ...
  #           parameter N text
  #nnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnn
}


#uuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuu
# Set exit, interruption, and termination signal traps          (SUB-ZERO CODES)
#nnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnn

cleanup=''

trap \
'
X=${?}
eval "${cleanup}"
if test ${X} -ne 0
then

  1>&2 printf "\n%s\n\n" "lit.bvt:  exiting. (CODE ${X})"

fi
' \
EXIT


trap '1>&2 print "INTerrupt signal received"; exit 254' INT
trap '1>&2 print "TERMinate signal received"; exit 255' TERM


#uuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuu
# Check for command syntax error                                        (CODE 1)
#nnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnn

continuous_mode='false'


if test ${#} -gt 0
then

  if test  ${#} -gt 1 \
  || test "${1}" != 'continuous'
  then

    1>&2 print 'encountered command syntax error'
    1>&2 printf '\n%s\n' 'usage:  lit.bvt [ continuous ]'
    exit 1

  else continuous_mode='true'
  fi

fi


#uuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuu
# Check for missing (lit) installation                                  (CODE 2)
#nnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnn

if test -z "$(command -v lit)"
then

  1>&2 print 'lit is not installed (`command -v lit` returned a null string)'
  exit 2

fi


#uuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuu
# Check for failed lit.bvt process directory creation                   (CODE 3)
#nnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnn

cleanup='
if test -n "${bvt_process_directory-}"
then rm -r "${bvt_process_directory}"
fi
'


bvt_process_directory=\
"$(mktemp -d --tmpdir lit.bvt.${$}.XXXXXXXXXX || 1>&2 printf '\n')"


if test -z "${bvt_process_directory}"
then

  1>&2 print 'could not create lit.bvt process directory'
  exit 3

fi


#uuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuu
# Check for write failure in lit.bvt process directory                  (CODE 4)
#nnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnn

if ! >"${bvt_process_directory}/writable" printf '%s\n' 'true'
then

  1>&2 print 'could not write inside of lit.bvt process directory' \
             ''                                                    \
             "  ${bvt_process_directory}"
  exit 4

fi


#uuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuu
# Check for result directory creation failure                           (CODE 5)
#nnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnn

if ! mkdir "${bvt_process_directory}/result"
then

  1>&2 print 'could not create lit.bvt result directory' \
             ''                                          \
             "  ${bvt_process_directory}/result"
  exit 5

fi


#uuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuu
# Idenfify tests and make respective operating and result directories   (CODE 6)
#                                                                     + (CODE 7)
#nnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnn

test_names="$(ls -1A "$(command -v lit).code/smoke-test" | sort -n -k 1 -t .)"


for test_name in ${test_names}
do

  if ! mkdir "${bvt_process_directory}/${test_name}"
  then

    1>&2 print 'could not create lit.bvt test directory' \
               ''                                        \
               "  ${bvt_process_directory}/${test_name}"
    exit 6

  fi

done


for test_name in ${test_names}
do

  if ! mkdir "${bvt_process_directory}/result/${test_name}"
  then

    1>&2 print 'could not create lit.bvt test result directory' \
               ''                                               \
               "  ${bvt_process_directory}/result/${test_name}"
    exit 7

  fi

done


#uuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuu
# Execute tests and record their process ID numbers
#nnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnn

cleanup='
for test_process_ID in ${test_process_IDs-} ${test_monitor_process_IDs-}
do

  1>/dev/null ps -o pid -p ${test_process_ID} && \
  2>/dev/null kill         ${test_process_ID}

done
rm -r bvt.data 2>/dev/null
mv "${bvt_process_directory}" bvt.data
'  # the 1st cleanup suffix is replaced by the 2nd
   # and changes behavior from removal to renaming

test_process_IDs=''
test_monitor_process_IDs=''

if test "${continuous_mode}" = 'true'; then print 'initiating.' ''; fi


for test_name in ${test_names}
do

  result_directory="${bvt_process_directory}/result/${test_name}"
  (
    cd "${bvt_process_directory}/${test_name}" || exit 128

    trap \
    '
    X=${?}
    if test ${X} -eq 0
    then >'"${result_directory}/passfail"' printf "%s\n" "passed"
    else >'"${result_directory}/passfail"' printf "%s\n" "FAILED"
         >'"${result_directory}/exitcode"' printf "%s\n" "${X}"
    fi
    ' \
    EXIT


    wait_for_test()          # output may still appear out of order since
    {                        # test monitors are separate processes
      while test ${#} -gt 0
      do

        ! test -f "${bvt_process_directory}/result/${1}/passfail" && \
          sleep 1                                                 || \
          shift

      done
    }


    . "$(command -v lit).code/smoke-test/${test_name}"
  )                           \
  1>"${result_directory}/fd1" \
  2>"${result_directory}/fd2" \
  &

  test_process_IDs="${test_process_IDs} ${!}"


  #uuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuu
  # Spawn test monitor processes to report test results during continuous mode
  #nnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnn

  if test "${continuous_mode}" = 'true'
  then
    (
      while ! test -f "${result_directory}/passfail"; do sleep 1; done
      print "$(cat "${result_directory}/passfail")  ${test_name}"
    ) \
    &

    test_monitor_process_IDs="${test_monitor_process_IDs}  ${!}"

  fi

done
touch "${bvt_process_directory}/testing_in_progress"


#uuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuu
# Display a live progress update based on the continuous_mode setting
#nnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnn

cleanup='
if test -n "${update_monitor_process_ID-}"
then  kill  ${update_monitor_process_ID}
fi
'"${cleanup}"  # cleanup suffix handles leftover test processes and
               # data transfer

update_monitor_process_ID=''
update_monitor()
{
  dots=0
  test_count="$(ls -1A "$(command -v lit).code/smoke-test" | wc -l)"
  while test -f "${bvt_process_directory}/testing_in_progress"
  do

    result_count=0
    clear
    print 'initiating.'
    printf '%s\n' \
'
uuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuu
'
    for test_name in ${test_names}
    do

      result_directory="${bvt_process_directory}/result/${test_name}"

      if test -f "${result_directory}/passfail"
      then

        result_count=$((result_count + 1))
        print "$(cat "${result_directory}/passfail")  ${test_name}"

      fi

    done

    print "$(for dot in $(seq ${dots}); do printf '.'; done)"
    printf '%s\n' \
'
nnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnn
'
    print "progress. $((result_count * 100 / test_count))%"

    $(command -v sleep) 0.05
    dots=$(( (dots + 1) % 4 ))

  done
}

if test "${continuous_mode}" = 'false'
then

  update_monitor &
  update_monitor_process_ID=${!}

fi


#uuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuu
# Wait for test processes to complete
#nnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnn

if test -n "${test_process_IDs}"
then  wait  ${test_process_IDs};           test_process_IDs=''
fi
rm "${bvt_process_directory}/testing_in_progress"

if test -n "${test_monitor_process_IDs}"
then  wait  ${test_monitor_process_IDs};   test_monitor_process_IDs=''
fi

if test -n "${update_monitor_process_ID}"
then  wait  ${update_monitor_process_ID};  update_monitor_process_ID=''
fi


#uuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuu
# Finalize and display results
#nnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnn

if test "${continuous_mode}" = 'true'
then printf '\n'
else

  clear
  print 'initiating.'
  printf '%s\n' \
'
uuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuu
'
  for test_name in ${test_names}
  do

    result_directory="${bvt_process_directory}/result/${test_name}"

    if test -f "${result_directory}/passfail"
    then

      print "$(cat "${result_directory}/passfail")  ${test_name}"

    fi

  done

  printf '%s\n' \
'
nnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnn
'
fi


failed='false'
for test_name in ${test_names}
do

    result_directory="${bvt_process_directory}/result/${test_name}"

    if test "$(cat "${result_directory}/passfail")" = 'FAILED'
    then

      failed='true'

    fi

done


if test "${failed}" = 'true'
then print 'complete.' '' 'test failure(s) occurred -- see bvt.data/result'
else print 'complete.' '' 'all tests passed'
fi
