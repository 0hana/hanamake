#  Copyright (C) 2022 Hanami Zero
#
#  This file is part of hanamake,
#  a beginner-friendly unit testing framework utility for C and C++
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

.DELETE_ON_ERROR:


# Identify target files

source_files := \
  $(shell \
    find -P source-link -type l -exec sh -c \
    ' : \
    ; while test $${#} -gt 0 \
    ; do : \
      ; find -H "$${1}" \( -name '\''*.c'\'' -o -name '\''*.cpp'\'' \) -type f \
      ; shift 1 \
    ; done \
    ' \
    "makefile-find source_files" '{}' '+' \
   )


object_files := \
  $(foreach source, $(filter %.c,   $(source_files)), $(source:source-link/%.c=build/%.o)) \
  $(foreach source, $(filter %.cpp, $(source_files)), $(source:source-link/%.cpp=build/%.opp))


target_files := \
  $(foreach base, $(basename $(filter %.o,   $(object_files))), $(base).d   $(base).i   $(base).o   $(base).s   $(base).y) \
  $(foreach base, $(basename $(filter %.opp, $(object_files))), $(base).dpp $(base).ipp $(base).opp $(base).spp $(base).ypp\
                                                                                                    $(base).xpp $(base).zpp)


.PRECIOUS: $(if $(source_files), $(target_files), $(error missing source (.c or .cpp) files))


# Identify and Isolate target directories

target_directories := $(sort $(dir $(object_files)))
$(shell mkdir -p $(target_directories))
$(shell mv build previous_build)
$(shell mkdir -p $(target_directories))


# Transfer existing target files to current build

$(foreach target, \
  $(target_files), \
  $(shell test -e 'previous_$(target)' && mv 'previous_$(target)' '$(target)') \
)
#    the 'test -e' is for the *.i(pp) targets, which are actually directories
#        'test -e' tests for (e)ither a directory or normal file

$(shell rm -r previous_build \
  $(if \
    $(shell find previous_build \( -name '*.[diosy]' -o -name '*.[diosxyz]pp' \)), \
    $(info Removing 0hana-main.c to ensure consistency with removed or renamed source files) \
    $(info ) \
    && rm -f 0hana-main.c \
  ) \
)


# Negate make target assumptions

.SUFFIXES:
COMMON     := -g -Wall -Wextra -Wpedantic -Og
CFLAGS     := -x c              $(COMMON)
CPPFLAGS   := -x c++-cpp-output $(COMMON)
LINK_FLAGS :=                   $(COMMON)


# Special build variables

hanamade_test_parameters := \
  FILE      ** const __hanamade_test__log_file, \
  char const * const __hanamade_test__log_path

hanamade_assert_definition := \
  (expression) \
  ? \
  ( ((void)((*__hanamade_test__log_file == NULL) && remove(__hanamade_test__log_path))), 1 ) \
  : \
  ( \
    ( \
      (void) \
      ( \
        (*__hanamade_test__log_file == NULL) && \
        (*__hanamade_test__log_file = fopen(__hanamade_test__log_path, "w")) && \
        (fprintf(*__hanamade_test__log_file, __FILE__ "\nFailed assert(s):\n")) \
      ) \
    ) \
    , fprintf(*__hanamade_test__log_file, "\nLine   \#  %i : (" \#expression ")\n", __LINE__) \
    __VA_OPT__(, \
      fprintf(*__hanamade_test__log_file, "Context:  " __VA_ARGS__), fprintf(*__hanamade_test__log_file, "\n") \
    ) \
    , 0 \
  )


# General build instructions
0hana-main: $(object_files) 0hana-main.c
	@echo '%  Compiling  : hanamade/$(@)'
	@echo '---------------'
	@gcc    $(LINK_FLAGS)  $(^) -o  $(@)


source_to_build = $(shell realpath --relative-base=.. '$(<)') \
  -> hanamade/build/.../$(notdir $(@))

build_to_build = hanamade/$(<) -> .../$(notdir $(@))


build/%.o: build/%.s
	@echo '- Mechanizing : $(build_to_build)'
	@gcc   -x assembler    $(<) -o $(@) -c


# The first  gcc checks to see if the user is missing #include <stdio.h>
# The second gcc includes <stdio.h> and defines the hanamake macros in .c

build/%.s: source-link/%.c normal-name
	@echo '- Translating : $(source_to_build)'
	@rm -f $(@:.s=.c.error)
	@cpp -include /usr/include/stdio.h \
	  -D'hanamake_test(function_signature)=extern "C" void @function_signature@__hanamade_test__@($(hanamade_test_parameters))' \
	  -D'hanamake_assert(expression, ...)=($(hanamade_assert_definition))' \
	  $(<) \
	| grep -o '@[$$A-Z_a-z][][ $$&()*,.0-9:A-Z_a-z]*@__hanamade_test__@' \
	| while read -r signature \
	; do : \
	  ; signature="$${signature#@}" \
	  ; signature="$${signature%@__hanamade_test__@}" \
	  ; : ::::::::::::::::::::::::::::::::::::::::::: \
	  ; if ! test -f normal-name/"$${signature}"\
	  ; then : \
	    ; >>$(@:.s=.c.error) echo "-------------------------------------------------------------------------------" \
	    ; >>$(@:.s=.c.error) echo "! BUILD ERROR : hanamake_test C function target" \
	    ; >>$(@:.s=.c.error) echo \
	    ; >>$(@:.s=.c.error) echo "                  $${signature}" \
	    ; >>$(@:.s=.c.error) echo \
	    ; >>$(@:.s=.c.error) echo "                IS UNDEFINED" \
	    ; >>$(@:.s=.c.error) echo \
	    ; >>$(@:.s=.c.error) echo "                Source of error:" \
	    ; >>$(@:.s=.c.error) echo \
	    ; >>$(@:.s=.c.error) echo "                  '$$(realpath --relative-base=.. '$(<)')'"\
	    ; >>$(@:.s=.c.error) echo \
	    ; exit 1 \
	  ; fi \
	  ; : ::::::::::::::::::::::::::::::::::::::::::: \
	; done
	@gcc      $(CFLAGS)    $(<) -o $(@) -S \
	  -include /usr/include/stdio.h \
	  -D'hanamake_test(function_name)=void function_name##__hanamade_test__($(hanamade_test_parameters))' \
	  -D'hanamake_assert(expression, ...)=($(hanamade_assert_definition))'

build/%.y: source-link/%.c build/%.d
	@echo '-  Yip! Yip!  : $(source_to_build)'
	@rm -f $(@:.y=.c.error)
	@cpp \
	  -D'hanamake_test(function_signature)=extern "C" void @function_signature@__hanamade_test__@(void)' \
	  -D'hanamake_assert(expression, ...)=(0)' \
	  $(<) \
	| grep -o '@[$$A-Z_a-z][][ $$&()*,.0-9:A-Z_a-z]*@__hanamade_test__@' \
	| while read -r signature \
	; do : \
	  ; signature="$${signature#@}" \
	  ; signature="$${signature%@__hanamade_test__@}" \
	  ; : ::::::::::::::::::::::::::::::::::::::::::: \
	  ; parameters="($${signature#*(}" \
	  ; namespaces="$${signature%$${parameters}}" \
	  ; namespaces="$${namespaces%::*}" \
	  ; if test "$${signature}" != "$${namespaces}" \
	  ; then : \
	    ; >>$(@:.y=.c.error) echo "-------------------------------------------------------------------------------" \
	    ; >>$(@:.y=.c.error) echo "! BUILD ERROR : hanamake_test C function target" \
	    ; >>$(@:.y=.c.error) echo \
	    ; >>$(@:.y=.c.error) echo "                  $${signature}" \
	    ; >>$(@:.y=.c.error) echo \
	    ; >>$(@:.y=.c.error) echo "                CANNOT have a" \
	    ; >>$(@:.y=.c.error) echo \
	    ; >>$(@:.y=.c.error) echo "                - parenthesized parameter type list '(type, ...)'" \
	  	; >>$(@:.y=.c.error) echo "                - double-colon '::' delimited namespace" \
	    ; >>$(@:.y=.c.error) echo \
	    ; >>$(@:.y=.c.error) echo "                Source of error:" \
	    ; >>$(@:.y=.c.error) echo \
	    ; >>$(@:.y=.c.error) echo "                  '$$(realpath --relative-base=.. '$(<)')'"\
	    ; >>$(@:.y=.c.error) echo \
	  ; exit 1 \
	  ; fi \
	  ; : ::::::::::::::::::::::::::::::::::::::::::: \
	; done
	@gcc      $(CFLAGS)    $(<) -o $(@) -S \
	  -Wno-unused-value \
	  -D'hanamake_test(function_name)=void function_name##__hanamade_test__(void)' \
	  -D'hanamake_assert(expression, ...)=(0)'


normal-name: mangled-name $(filter %.y, $(target_files))
	@echo "- Writing Map : %.y -> $(@)"
	@rm -rf $(@)
	@mkdir  $(@)
	@for file in $(filter-out mangled-name, $(^)) \
	; do : \
	  ; grep '^[$$A-Z_a-z][$$0-9A-Z_a-z]*:$$' $${file} \
	  | sed 's/:$$//' \
	  | while read -r normal_name; do touch $(@)/"$${normal_name}"; done \
	; done
	@ls -1A mangled-name \
	| grep -vx '__hex_hash__[0-9A-Fa-f][0-9A-Fa-f]*__hanamade_test__' \
	| grep -x '[$$A-Z_a-z][$$0-9A-Z_a-z]*' \
	| while read -r normal_name \
	; do : \
	  ; touch $(@)/"$${normal_name}" \
	; done


build/%.d: source-link/%.c
	@echo '- Prescanning : $(source_to_build)'
	@# Create additional makefile target dependencies for build/%.s files
	@# so that if their #include "files" are updated, they will be remade
	@cpp $(<) -MF $(@) -MM -MP -MT $(@:.d=.s)


build/%.opp: build/%.spp
	@echo '- Mechanizing : $(build_to_build)'
	@g++   -x assembler    $(<) -o $(@) -c


build/%.spp: build/%.xpp
	@echo '- Translating : $(build_to_build)'
	@g++     $(CPPFLAGS)   $(<) -o $(@) -S


build/%.xpp: source-link/%.cpp mangled-name
	@echo '- Realizing X : $(source_to_build)'
	@ rm -f $(@:.xpp=.cpp.error) \
	; SURROGATE="$$(mktemp)" \
	; trap 'rm "$${SURROGATE}"' EXIT \
	; cpp -include /usr/include/stdio.h \
	  -D'hanamake_test(function_signature)=extern "C" void @function_signature@__hanamade_test__@($(hanamade_test_parameters))' \
	  -D'hanamake_assert(expression, ...)=($(hanamade_assert_definition))' \
	  $(<) \
	| tee $(@) > "$${SURROGATE}" \
	; grep -o '@[$$A-Z_a-z][][ $$&()*,.0-9:A-Z_a-z]*@__hanamade_test__@' "$${SURROGATE}" \
	| while read -r signature \
	; do : \
	  ; signature="$${signature#@}" \
	  ; signature="$${signature%@__hanamade_test__@}" \
	  ; : ::::::::::::::::::::::::::::::::::::::::::: \
	  ; if ! test -f mangled-name/"$${signature}" \
	  ; then : \
	    ; >>$(@:.xpp=.cpp.error) echo "-------------------------------------------------------------------------------" \
	    ; >>$(@:.xpp=.cpp.error) echo "! BUILD ERROR : hanamake_test C++ function target" \
	    ; >>$(@:.xpp=.cpp.error) echo \
	    ; >>$(@:.xpp=.cpp.error) echo "                  $${signature}" \
	    ; >>$(@:.xpp=.cpp.error) echo \
	    ; >>$(@:.xpp=.cpp.error) echo "                IS UNDEFINED" \
	    ; >>$(@:.xpp=.cpp.error) echo \
	    ; >>$(@:.xpp=.cpp.error) echo "                Source of error:" \
	    ; >>$(@:.xpp=.cpp.error) echo \
	    ; >>$(@:.xpp=.cpp.error) echo "                  '$$(realpath --relative-base=.. '$(<)')'"\
	    ; >>$(@:.xpp=.cpp.error) echo \
	    ; rm "$(@)" \
	    ; exit 1 \
	  ; fi \
	  ; : ::::::::::::::::::::::::::::::::::::::::::: \
	  ; sed -i "s/@$${signature}@__hanamade_test__@/$$(2>/dev/null cat mangled-name/"$${signature}")__hanamade_test__/g" $(@) \
	; done


build/%.ypp: build/%.zpp
	@echo '- Realizing Y : $(build_to_build)'
	@g++     $(CPPFLAGS)   $(<) -o $(@) -S -Wno-unused-value


build/%.zpp: source-link/%.cpp build/%.dpp
	@echo '- Realizing Z : $(source_to_build)'
	@ rm -f $(@:.zpp=.cpp.error)
	@ SURROGATE="$$(mktemp)" \
	; trap 'rm "$${SURROGATE}"' EXIT \
	; cpp \
	  -D'hanamake_test(function_signature)=extern "C" void @function_signature@__hanamade_test__@(void)' \
	  -D'hanamake_assert(expression, ...)=(0)' \
	  $(<) \
	| tee $(@) > "$${SURROGATE}" \
	; grep -o '@[$$A-Z_a-z][][ $$&()*,.0-9:A-Z_a-z]*@__hanamade_test__@' "$${SURROGATE}" \
	| while read -r signature \
	; do : \
	  ; signature="$${signature#@}" \
	  ; signature="$${signature%@__hanamade_test__@}" \
	  ; : ::::::::::::::::::::::::::::::::::::::::::: \
	  ; parameters="($${signature#*(}" \
	  ; if test "$${signature%$${parameters}}" = "$${signature}" \
	  ; then : \
	    ; >>$(@:.zpp=.cpp.error) echo "-------------------------------------------------------------------------------" \
	    ; >>$(@:.zpp=.cpp.error) echo "! BUILD ERROR : hanamake_test C++ function target" \
	    ; >>$(@:.zpp=.cpp.error) echo \
	    ; >>$(@:.zpp=.cpp.error) echo "                  $${signature}" \
	    ; >>$(@:.zpp=.cpp.error) echo \
	    ; >>$(@:.zpp=.cpp.error) echo "                REQUIRES a" \
	    ; >>$(@:.zpp=.cpp.error) echo \
	    ; >>$(@:.zpp=.cpp.error) echo "                - parenthesized parameter type list '(type, ...)'"\
	    ; >>$(@:.zpp=.cpp.error) echo \
	    ; >>$(@:.zpp=.cpp.error) echo "                Source of error:" \
	    ; >>$(@:.zpp=.cpp.error) echo \
	    ; >>$(@:.zpp=.cpp.error) echo "                  '$$(realpath --relative-base=.. '$(<)')'"\
	    ; >>$(@:.zpp=.cpp.error) echo \
	    ; rm "$(@)" \
	    ; exit 1 \
	  ; fi \
	  ; : ::::::::::::::::::::::::::::::::::::::::::: \
	  ; sed -i "s/@$${signature}@__hanamade_test__@/__hex_hash__$$(printf "$${signature}" | xxd -p)__hanamade_test__/g" $(@) \
	; done


mangled-name: $(filter %.ypp, $(target_files))
	@echo '- Writing Map : %.ypp -> mangled-name'
	@rm -rf $(@)
	@mkdir  $(@)
	@for file in $(^) \
	; do : \
	  ; grep '^[$$A-Z_a-z][$$0-9A-Z_a-z]*:$$' $${file} \
	  | sed 's/:$$//' \
	  | while read -r mangled_name \
	  ; do : \
	    ; > $(@)/"$$(c++filt $${mangled_name})" printf "$${mangled_name}" \
	  ; done \
	; done


build/%.dpp: source-link/%.cpp
	@echo '- Prescanning : $(source_to_build)'
	@# Create additional makefile target dependencies for build/%.spp files
	@# so that if their #include "files" are updated, they will be remade
	@cpp $(<) -MF $(@) -MM -MP -MT $(@:.dpp=.spp)


formulating_script := "$(hanamake_source_code)/build-support/formulating.sh"


0hana-main.c: $(filter %i %.ipp, $(target_files))
	@echo '---------------'
	@echo '+ Formulating : hanamade/$(@)'
	@sh    $(formulating_script)    $(@)


# Until a robust and reliable method is made to identify meaningful
# object changes between assembly files, the "one-function one-file"
# approach is only known way to generally achieve re-test minimization.
#
# In the meantime, remove and remake build/%.i(pp) directories per source update

remove_and_remake_script = \
  echo '- Subdividing : $(build_to_build)'; rm -rf $(@) && mkdir $(@)


# Split build/%.s(pp) files into partial assembly files under build/%.i(pp)

csplit_script = \
  csplit --prefix='$(@)/csplit_' --suffix-format='%%_%i.x' --silent $(<) \
  $$(echo \
    $$(grep      '^[$$A-Z_a-z][$$0-9A-Z_a-z]*:$$' $(<) \
      | sed  's/\(^[$$A-Z_a-z][$$0-9A-Z_a-z]*:$$\)/\/^\1$$\//' \
      ) \
    | sed 's/\/\(\^[$$A-Z_a-z][$$0-9A-Z_a-z]*:\$$\)\//%\1%/' \
    ) \
  ; for csplit_file in $(@)/csplit_*.x \
  ; do function_name="$$(head -n 1 $${csplit_file} | sed 's/://')" \
  \
    ; mv $${csplit_file} $(@)/$${function_name} \
    ; if grep -q     "$${function_name}, @function" \
    $(basename $(@))$(if $(filter %.i, $(@)),.s,.spp) \
    ; then mkdir -p $(@:build/%=log/%) \
      &&   touch    $(@:build/%=log/%)/$${function_name}.log \
    ; else rm       $(@)/$${function_name} \
    ; fi \
  \
  ; done


build/%.i: build/%.s
	@$(remove_and_remake_script)
	@$(csplit_script)


build/%.ipp: build/%.spp
	@$(remove_and_remake_script)
	@$(csplit_script)


-include $(filter %.d %.dpp, $(target_files))
