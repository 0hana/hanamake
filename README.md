# hanamake

C and C++ test-driven-development framework


## License

AGPL (See COPYING)


## Made with

- GNU `binutils`, `coreutils`, `g++`, `gcc`, `gdb`, and `make`
- POSIX `sh` script
- `valgrind`


## How to use

	SYNOPSIS
	
		Usage: hanamake [ -s <source-directory> ... ]
		     | hanamake debug [ <function-name> ... ]
		     | hanamake clean

> **WARNING:** `hanamake` is currently in alpha development.  
> Numerous features and functionality are not ready for use.
>
> The only way to reliably use `hanamake` during alpha-development is with `hanamake clean` between each `hanamake` invokation.  
> C++ support is extremely limited as of this writing (e.g. no support for any namespaced or overloaded function).
>
> The remainder of alpha-development is primarily focused on addressing the complexities of supporting C++.  
> However, the plan for achieving this involves completely separating C and C++ build systems,  
> which has delayed full C support as well.
>
> The benefit of decoupling does extend beyond C++ support though.  
> It should make adding Java support much simpler in a post-release update.

In either the `source` or any directory specified with the `-s` option  
(e.g. `hanamake -s my-source-code-directory-1 my-source-code-directory-2 ...`)  
you can write a function unit tests in a `.c` or `.cpp` file as follows:

	hanamake_test(function_name)
	{
	  ... setup code ...
	
	  hanamake_assert(boolean expression) ;
	
	  ... cleanup code (if needed) ...
	}

As a specific example,  
here is how I implemented a test for an endianness switching function  
that switches byte ordering between big and little endian order:

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

`hanamake` automatically detects such test definitions and runs them on your code.
- `hanamake_test(name)` identifies a test for a particular function
- `hanamake_assert(boolean)` determines whether or not a test passes:
  - any assert over a value of 0 decides the test result as a failure
    and the expression, line number, and file of the failure point are logged
    so the function is marked for retesting on the next invokation of `hanamake`
    (under `hanamade/log`)
