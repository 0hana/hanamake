#  Copyright (C) 2022 Hanami Zero
#
#  This file is part of hanamake,
#  a collection of C and C++ development utilities.
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

> ${1} echo \
"\
/* Copyright (C) 2022 Hanami Zero

   This file is part of hanamake,
   a collection of C and C++ development utilities.

   hanamake is free software: you can redistribute it and/or modify
   it under the terms of the GNU Affero General Public License --
   the superset of version 3 of the GNU General Public License --
   as published by the Free Software Foundation.

   hanamake is distributed in the hope that it will be useful,
   but WITHOUT ANY WARRANTY; without even the implied warranty
   of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
   See the GNU Affero General Public License for more details.

   You should have received a copy of the GNU Affero General Public License
   along with hanamake. If not, see <https://www.gnu.org/licenses/>. */
"

# Insert system header files
>>${1} echo \
"\
#include <stdio.h>
"

# Insert unit test declarations
test_names="$(basename -a ${2} | grep '^\$hanamake_test\$')"
for name in ${test_names}
do
>>${1} echo "void ${name}"
>>${1} echo "( FILE      ** const \$hanamake_test\$log_file"
>>${1} echo ", char const * const \$hanamake_test\$log_path"
>>${1} echo ") ;"
>>${1} echo
done

# Get number of code objects
>>${1} echo "#define code_objects $(echo ${2} | wc -w)"

# Define code object information structure for access in dispatcher loop
>>${1} echo \
"\
enum code_object_status { passed, failed, updated, depends };

struct code_object_info
{
  char   const * const name;
  /*----------------------*/
  char   const * const log_path;
  FILE         *       log_file;
  /*--------------------------*/
  size_t const * const dependency;
  size_t const         dependencies;
  /*------------------------------*/
  void        (* const \$hanamake_test\$)
  ( FILE      ** const \$hanamake_test\$log_file
  , char const * const \$hanamake_test\$log_path
  ) ;
  /*------------------------------------------*/
  enum code_object_status status;
}

coi[code_objects] =
{\
"

# Identify longest code object name for test output formatting (relative right justify names)
hanamake_test_prefix_length=$(printf '$hanamake_test$' | wc -m)
translation_length=8
longest_base=0
for name in $(basename -a ${2})
do
	name_length=$(printf ${name} | wc -m)
	if test -n "$(echo   ${name} | grep '^\$hanamake_test\$')"
	then name_length=$((${name_length} - ${hanamake_test_prefix_length} + ${translation_length}))
	fi
	if test ${name_length} -gt ${longest_base}
	then longest_base=${name_length}
	fi
done

# Initialize the code object information ("coi") array
for identity in ${2}
do
	base=$(basename ${identity})
	base_length=$(printf ${base} | wc -m)
	# name string
	if test -n "$(echo ${base} | grep '^\$hanamake_test\$')"
	then
	base_length=$((${base_length} - ${hanamake_test_prefix_length} + ${translation_length}))
	>>${1} echo "  { \"$(for i in $(seq $((${longest_base} - ${base_length}))); do printf ' '; done)$(echo "${base}  <TEST>" | sed 's/^\$hanamake_test\$//')\""
	else
	>>${1} echo "  { \"$(for i in $(seq $((${longest_base} - ${base_length}))); do printf ' '; done)${base}\""
	fi

	>>${1} echo "  , \"${identity}.log\""  # log_path string
	>>${1} echo "  , NULL"                 # log_file FILE pointer
	>>${1} echo "  , NULL"                 # dependency
	>>${1} echo "  , 0"                    # dependencies

	if test -n "$(echo ${base} | grep '^\$hanamake_test\$')"
	then
	>>${1} echo "  , ${base}"              # \$hanamake_test\$ function pointer
	else
	>>${1} echo "  , NULL"                 # \$hanamake_test\$ function NULL pointer (not a test)
	fi

	>>${1} echo "  , failed"               # code object status (default: failed)

	>>${1} echo "  } ,"
	>>${1} echo
done

>>${1} printf '%s' \
"\
} ;

int main(void)
{
	printf(\"\nScanning for updates ... \");

	/* Check for source file updates
	   (empty logs in build/%.i(pp) produced by make)
	*/

	for(size_t index = 0; index < code_objects; index++)
	{
		/* Log file presence indicates either source update or prior test failure
		*/
		if((coi[index].log_file = fopen(coi[index].log_path, \"r\")))
		{
			/* Getting an End Of File (EOF) value at the beginning of
			   the file means its empty, and the corresponding source file was updated

				 Getting any other value means the file is non-empty, indicating a prior
				 testing failure (which is the default assumption, so no action is taken)
			*/
			if(fgetc(coi[index].log_file) == EOF) coi[index].status = updated;

			/* Close and reassign NULL to log_file to avoid interfering with testing,
			   which uses a   non-NULL    log_file value to detect a failed test.
			*/
			fclose(coi[index].log_file);
			coi[index].log_file = NULL;
		}
		/* No log file means no update nor failure -- an implicit pass
		*/
		else coi[index].status = passed;
	}


	printf(\"done\n\");


	/* Code stub: Run topological dependency analysis
	   setting non-updated objects that depend on objects
	   with status: 'updated' OR 'depends' to 'depends'
	*/

	/* Identify required testing based on direct (source file update)
	   and indirect (dependency on direct update) updates
	*/

	char tests_required_to_run = 0;

	for(size_t index = 0; index < code_objects; index++)
	{
		switch(coi[index].status)
		{
			case updated: printf(\"  %s  [ source file updated ]\n\",   coi[index].name);

				if(coi[index].\$hanamake_test\$) tests_required_to_run++;
				break;

			case depends: printf(\"  %s  [ depends on ]\n\", /*------*/ coi[index].name);

				if(coi[index].\$hanamake_test\$) tests_required_to_run++;
				break;

			case  failed: printf(\"  %s  [ failed last time ]\n\", /**/ coi[index].name);

				if(coi[index].\$hanamake_test\$) tests_required_to_run++;
				break;

			case  passed: /* do nothing */

				break;
		}
	}


	/* Execute required tests and report results
	*/


	if(tests_required_to_run > 0) printf(\"\nRunning tests:\n\n\");
	else printf(\"\nNo tests to run.\n\");

	printf(\"  ...\");

	for(size_t index = 0; index < code_objects; index++)
	{
		if(coi[index].\$hanamake_test\$ != NULL && coi[index].status != passed)
		{
			coi[index].\$hanamake_test\$(&(coi[index].log_file), coi[index].log_path);

			if(coi[index].log_file != NULL)
			{
				printf(\"\b\b\b%s  [ FAILED ] -- see  %s\n  ...\", coi[index].name, coi[index].log_path);
				coi[index].status = failed;
			}

			else
			{
				printf(\"\b\b\b%s  [ PASSED ]\n  ...\", coi[index].name);
				coi[index].status = passed;
			}
		}
	}

	printf(\"\b\b\b   \nTesting Complete.\n\n\");

	return 0;
}
"
