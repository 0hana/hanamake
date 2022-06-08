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
} ;
"
