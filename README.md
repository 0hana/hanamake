# hanamake

C and C++ test-driven-development framework


## License

AGPL (See COPYING)


## Made with

- GNU `binutils`, `coreutils`, `g++`, `gcc`, `gdb`, and `make`
- POSIX `sh` script
- `valgrind`


## How to use in 5 minutes

	SYNOPSIS
	
		Usage: hanamake [ -s <source-directory> ... ]
		     | hanamake debug [ <function-name> ... ]
		     | hanamake clean

> **WARNING:** `hanamake` is currently in alpha development.  
> Some features and functionality are incomplete.
>
> The only way to reliably use `hanamake` testing during alpha-development is with `hanamake clean` between each `hanamake` invokation.  
> Unfortunately, this prevents `hanamake debug` use.  

In any `.c` or `.cpp` file below directories specified with the `-s` option (default: `source`),  
`hanamake` will look for functions enclosed with: `hanamake_test( )`  
and check the validity of corresponding assertions enclosed with `hanamake_assert( )`.

For example, in C:

    hanamake_test(add)
    {
        // Test commutative property of addition
        hanamake_assert(add(1, 2) == 3);
        hanamake_assert(add(2, 1) == 3);
    }

`add` is a function that takes 2 `int` type inputs and returns 1 `int` output,  
and the assertions tell `hanamake` to check that 1 + 2 = 3 = 2 + 1   
(assuming `add` is straight-forward function name).

If none of the assertions fail (none of the expressions evaluate as false),  
then `hanamake` will notify you during the testing phase that the test for `add` passed.

Otherwise, it will notify you that the test for `add` failed,  
and record the locations of all failed assertions in a log file somewhere under `hanamade/log`.

For tests that fail, you can initiate `debug` mode via `hanamake debug` to re-run the failed tests in `gdb` with the failed assertions marked, and move through the logic step by step to help isolate the cause.

The main (if not only) `gdb` commands you'll *need* to know are:

- `r` or `run` the program
- `n` or `next` statement/line/instruction
- `s` or `step` into the function (instead of executing it and moving on)
- `c` or `continue` to the next breakpoint
- `p` or `print` a variable's value--you just type `p variable_name`  
  and it will tell you the current value
- `q` or `quit` the GNU debugger (`gdb`)

---

The main reason behind `gdb` integration via `debug` mode is friction.  
Running the tests, checking results, then working out where to start looking for bugs is a cumbersome loop.

Since `hanamake` runs a minimum of tests partly by working out inter-function dependency,
`hanamake` can also tell you where failures with greater consequences are, and thus where you should consider looking first.

And instead of making you look, since it already logged where the failures occured, it can just take you there and pause program execution just before failure via `gdb` breakpoints, potentially saving you hours if you had no idea where to start, and otherwise providing a systematic approach to eliminating run-time errors.

---

There are more features I could talk about that I spent a lot of time on, but if I've done this well, you'll appreciate them even if you're unaware.

The goal of `hanamake` is to be a brain-dead simple to use Unit & Regression testing tool and easy debugger experience that newcomers and veterans alike can enjoy with projects big and small.

That said, newcomers, students, interns, and beginners otherwise are the priority.  
I hope this helps you on your journey.

---

### Limitations

Any file or directory above or below a `<source-directory>` must not have tabs, spaces, or newlines in its name. Despite my best efforts to allow them (see [launch.sh](hanamake.source-code/launch.sh) and [launch-support](hanamake.source-code/launch-support)), the [build-support](hanamake.source-code/build-support) code (and [GNU makefile](hanamake.source-code/build-support/makefile) in particular) relies heavily on their absence.

Functions invoked via a function pointer variable are not detected.

Global variable mutation effects are not accounted for.

Tests for C (including `extern "C"`) and C++ functions must only appear in files with their respective extentions  

- `.c` for C and `extern "C"`
- `.cpp` for C++

and must use a slight variation in syntax for each as follows:

### C

	hanamake_test(function_name)
	{
	  ... setup code ...
	
	  hanamake_assert(boolean expression) ;
	
	  ... cleanup code (if needed) ...
	}

### C++

	hanamake_test(namespace::...function_name(parameter_type, ...))
	{
	  ... setup code ...
	
	  hanamake_assert(boolean expression) ;
	
	  ... cleanup code (if needed) ...
	}


The 2 variations really are almost identical:

***Conceptually***, you're just passing a function to the testing system.  
***In practice***, `hanamake` pre-mangles specified target C++ function signatures in `.cpp` files, hence the slight, but rigid difference.

This is needed to unambiguously tell the `hanamake` testing system which C or C++ function the test is for.

> It's worth noting that `hanamake_assert( )` returns its evaluated boolean, so it can be used in other expressions and `if(statements)`.

### Examples

Here is how I implemented a test for an endianness switching function in C  
that switches byte ordering between big and little endian order:

	#ifdef hanamake_test
	hanamake_test(endian_mirror)
	{
	  { uint8_t  Byte = /*---*/ 0x12
	  ; endian_mirror(sizeof(Byte), &(Byte))
	  ; hanamake_assert(Byte == 0x12)         // reversing the sequence of bytes
	  ;                                       // '12' is '12' ('12' is one byte)
	  }
	  { uint16_t Word = /*---*/ 0x1234
	  ; endian_mirror(sizeof(Word), (byte*)&(Word))
	  ; hanamake_assert(Word == 0x3412)       // reversing the sequence of bytes
	  ;                                       // '12','34' is '34','12'
	  }
	  { uint32_t Dword = /*---*/ 0x12345678
	  ; endian_mirror(sizeof(Dword), (byte*)&(Dword))
	  ; hanamake_assert(Dword == 0x78563412)  // reversing the sequence of bytes
	  ;                                       // '12','34','56','78' is
	  }                                       // '78','56','34','12'
	  { uint64_t Qword = /*---*/ 0x12345678AABBCCDD
	  ; endian_mirror(sizeof(Qword), (byte*)&(Qword))
	  ; hanamake_assert(Qword == 0xDDCCBBAA78563412)  // I'll let you work out
	  ;                                               // the rest ;)
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

What I'm really doing here is stating my expectations about what a byte sequence
reversal should look like.

If there's only 1 byte in the sequence, there's nothing to reverse.  
If there are 2 bytes in the sequence, it's just a swap of 2 values.  
The 4 and 8 byte sequences are just a couple of sanity checks.

The `Cstring` assert is a check that the middle byte in an odd number of bytes  
(13 -- we start from `0`, and including `1-12`, there are `13`),  
corresponding to  the letter `'W'` in  
`'H'` `'e'` `'l'` `'l'` `'o'` `' '` `'W'` `'o'` `'r'` `'l'` `'d'` `'\0'`  
is `Cstring[ 6]` (Text between dialogue `"` `"` quotations implicitly ends with a `'\0'` byte)

---

*In case you're wondering what an endian switching function might be used for:*  
*machine-agnostic general radix-sort algorithm.*

*You can detect endianness (albeit a little wastefully) with:*  
`#define little_endian (*(int16_t const * const)" " == ' ')`

*An improvement, relying on relatively low optimization capabilities from a compiler:*  
*(meaning this is virtually guaranteed to work wherever you use it)*  

    #define little_endian little_endian()
    static inline uint8_t little_endian { return (*(int16_t const * const)" " == ' '; }

---
