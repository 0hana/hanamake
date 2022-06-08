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

#include "0hana/types.h"

int16_t const * const big_endian = ((int16_t const * const)" ");

void endian_mirror
( size_t bytes
, byte * datum
)
{
  while ( bytes-- > 1 )
  {
    byte X         = datum[bytes];
    datum[bytes--] = *datum;
    *datum++       = X;
  }
}

#ifdef hanamake_test
hanamake_test(endian_mirror)
{
  { byte Byte = /*-------*/ 0x12
  ; endian_mirror(sizeof(Byte), &(Byte))
  ; hanamake_assert(Byte == 0x12)
  ;
  }
  { uint16_t Word = /*---*/ 0x1234
  ; endian_mirror(sizeof(Word), (byte*)&(Word))
  ; hanamake_assert(Word == 0x3412)
  ;
  }
  { uint32_t Dword = /*---*/ 0x12345678
  ; endian_mirror(sizeof(Dword), (byte*)&(Dword))
  ; hanamake_assert(Dword == 0x78563412)
  ;
  }
  { uint64_t Qword = /*---*/ 0x12345678AABBCCDD
  ; endian_mirror(sizeof(Qword), (byte*)&(Qword))
  ; hanamake_assert(Qword == 0xDDCCBBAA78563412)
  ;
  }
  { char Cstring[] = "Hello World!"
  ; endian_mirror(sizeof(Cstring), (byte*)Cstring)
  ; hanamake_assert(Cstring[ 0] == '\0')
  ; hanamake_assert(Cstring[ 1] ==  '!')
  ; hanamake_assert(Cstring[ 2] ==  'd')
  ; hanamake_assert(Cstring[ 3] ==  'l')
  ; hanamake_assert(Cstring[ 4] ==  'r')
  ; hanamake_assert(Cstring[ 5] ==  'o')
  ; hanamake_assert(Cstring[ 6] ==  'W')
  ; hanamake_assert(Cstring[ 7] ==  ' ')
  ; hanamake_assert(Cstring[ 8] ==  'o')
  ; hanamake_assert(Cstring[ 9] ==  'l')
  ; hanamake_assert(Cstring[10] ==  'l')
  ; hanamake_assert(Cstring[11] ==  'e')
  ; hanamake_assert(Cstring[12] ==  'H')
  ;
  }
}
#endif//test
