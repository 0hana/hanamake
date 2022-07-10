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

#ifndef _0hana_types_

#include <stddef.h>
#include <stdint.h>

typedef uint8_t byte;
extern  int16_t const * const big_endian;
#define little_endian ((*big_endian) == ' ')

void endian_mirror
( size_t bytes
, byte * datum
) ;

#define _0hana_L_PARENTHESIS_ (
#define _0hana_R_PARENTHESIS_ )
#define _0hana_unconst_
#define guard(type, name, /* function parameters */ ...) \
	union \
	{ \
		type \
		__VA_OPT__(_0hana_un)##const##__VA_OPT__(_) \
		__VA_OPT__(_0hana_L_PARENTHESIS_* const) name \
		__VA_OPT__(_0hana_R_PARENTHESIS_)__VA_OPT__((__VA_ARGS__)); \
		type \
		__VA_OPT__(_0hana_L_PARENTHESIS_*) name##_0hana_unconst_ \
		__VA_OPT__(_0hana_R_PARENTHESIS_)__VA_OPT__((__VA_ARGS__)); \
	}
#define relax(variable) variable##_0hana_unconst_

#define _0hana_types_
#endif//_0hana_types_
