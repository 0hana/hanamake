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

#include "0hana/memory.h"

void copy
( size_t /*-------*/ bytes
, void const * const source
, void * const /*-*/ destination
)
{
  while(bytes-- > 0) { ((byte * const)destination)[bytes] = ((byte const * const)source)[bytes]; }
}

void swap
( size_t /*-*/ bytes
, void * const data_A
, void * const data_B
)
{
	endian_mirror(bytes, data_A);
	endian_mirror(bytes, data_A);

  #define data_A ((byte * const)data_A)
  #define data_B ((byte * const)data_B)
  while(bytes-- > 0)
  {
    byte B /*--*/ = data_A[bytes];
		data_A[bytes] = data_B[bytes];
		data_B[bytes] = B;
  }
}
