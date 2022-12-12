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


#uuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuu
# Identify target files
#nnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnn

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
    "makefile: find source_files" '{}' '+' \
   )


object_files := \
  $(foreach source, $(filter %.c,   $(source_files)), $(source:source-link/%.c=build/%.o)) \
  $(foreach source, $(filter %.cpp, $(source_files)), $(source:source-link/%.cpp=build/%.opp))


target_files := \
  $(foreach base, $(basename $(filter %.o,   $(object_files))), $(base).d   $(base).i   $(base).o   $(base).s   $(base).y) \
  $(foreach base, $(basename $(filter %.opp, $(object_files))), $(base).dpp $(base).ipp $(base).opp $(base).spp $(base).ypp \
                                                                                                    $(base).xpp $(base).zpp)


.PRECIOUS: $(if $(source_files), $(target_files), $(error missing source (.c or .cpp) files))


#uuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuu
# Screen for source directory collisions with build targets
#nnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnn

potential_directory_collisions := \
  $(shell \
    find -P source-link -type l -exec sh -c \
    ' : \
    ; while test $${#} -gt 0 \
    ; do : \
      ; find -H "$${1}" \
      \( -name '\''*.[diosy]'\'' \
      -o -name '\''*.[diosxyz]pp'\'' \
      -o -name '\''*.c.error'\'' \
      -o -name '\''*.cpp.error'\'' \
      \) -type d \
      ; shift 1 \
    ; done \
    ' \
    "makefile: find potential_directory_collisions" '{}' '+' \
   )


directory_collisions := \
$(strip \
  $(foreach directory \
  , $(potential_directory_collisions) \
  , $(shell : \
      ; name='$(directory)' \
      ; base="$${name%.*}" \
      ; suffix="$${name#$${base}.}" \
      \
      ; if test "$${suffix}" = "error" \
      \
      ; then conflict="$${name%.error}" \
      ; else conflict="$${base}.c$${suffix#?}" \
      ; fi \
      \
      ; test -f "$${conflict}" && printf "%s\n" '$(directory)' \
    ) \
  ) \
)

# The 'foreach' call above is inside a 'strip' call to prevent an assignment of
# spaces (ascii 0x20) characters around the potential directory names...
# 'make' can be quite obscure (-_-)


$(if $(directory_collisions) \
, $(info -------------------------------------------------------------------------------) \
  $(info ! BUILD ERROR :) \
  $(info ) \
  $(info The following source sub-directories have name collisions with build targets,) \
  $(info and are incompatible with the build system:) \
  $(info ) \
  $(foreach directory \
  , $(directory_collisions) \
  , $(info - $(shell realpath --relative-base=.. '$(directory:source-link/%=/%)')) \
  ) \
  $(info ) \
  $(info In general,) \
  $(info if there is a corresponding  .c  file,) \
  $(info sub-directory names of source directories must not end with) \
  $(info ) \
  $(info $()  .d  .i  .o  .s  .y  .c.error) \
  $(info ) \
  $(info Similarly,) \
  $(info if there is a corresponding  .cpp  file,) \
  $(info sub-directory names of source directories must not end with) \
  $(info ) \
  $(info $()  .dpp  .ipp  .opp  .spp  .xpp  .ypp  .zpp  .cpp.error) \
  $(info ) \
  $(error $(shell mkdir -p build)) \
)


#uuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuu
# Identify and Isolate target directories
#nnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnn

target_directories := $(sort $(dir $(object_files)))

$(shell mkdir -p $(target_directories))
$(shell mv build previous_build)
$(shell mkdir -p $(target_directories))


#uuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuu
# Transfer existing target files to current build
#
# NOTE:
#        'test -e' is for the *.i(pp) targets, which are actually directories
#        'test -e' tests for (e)ither a directory or normal file
#nnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnn

$(foreach target, \
  $(target_files), \
  $(shell test -e 'previous_$(target)' && mv 'previous_$(target)' '$(target)') \
)


#uuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuu
# Delete the remaining (now vestigial) build files
#
# If there are any files to delete, then also delete the 0hana-main.c file
# to force a new version to be made
#
# This will ensure the executable represents the current set of source files
#nnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnn

$(shell rm -r previous_build \
  $(if \
    $(shell find previous_build \( -name '*.[diosy]' -o -name '*.[diosxyz]pp' \)), \
    $(info Removing 0hana-main.c to ensure consistency with removed or renamed source files) \
    $(info ) \
    && rm -f 0hana-main.c \
  ) \
)


#uuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuu
# Identify and Isolate previous-names from PREVIOUS_previous-names (untargeted)
#nnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnn

target_directories := $(target_directories:build/%=previous-names/%)

$(shell mkdir -p $(target_directories))
$(shell mv previous-names PREVIOUS_previous-names)
$(shell mkdir -p $(target_directories) mangled-name normal-name)

target_directories  = $(error 'target_directories' variable is only defined in the makefile preamble)


#uuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuu
# Transfer existing previous-names files back to the current set
#     from PREVIOUS_previous-names
#
# The logic here is similar to the previous_build transfer and deletion above
#nnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnn

previous_names := $(filter %.y %.ypp,$(target_files:build/%=previous-names/%))

.PRECIOUS: $(previous_names)

$(foreach \
    previous_name, \
  $(previous_names), \
  $(shell test -f 'PREVIOUS_$(previous_name)' && mv 'PREVIOUS_$(previous_name)' '$(previous_name)') \
)


#uuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuu
# Delete the function names listed in PREVIOUS_previous-names/%.y(pp) from
# the 'mangled-name' and 'normal-name' directories
#nnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnn

DELETE_PREVIOUS_NAMES = \
	while read -r name \
	; do : \
	  ; if test "$$(dirname "$${name}")" = "mangled-name" \
	    || test "$$(dirname "$${name}")" =  "normal-name" \
	  ; then rm -f "$${name}" \
	  ; fi \
	; done

$(shell find PREVIOUS_previous-names -type f \
  \( -name '*.y' \
  -o -name '*.ypp' \
  \) -exec sh -c \
  ' : \
  ; while test $${#} -gt 0 \
  ; do : \
    ; cat "$${1}" | $(DELETE_PREVIOUS_NAMES) \
    ; shift 1 \
  ; done \
  ' \
  \
  'makefile: remove PREVIOUS_previous-names' '{}' '+' \
)
$(shell rm -r PREVIOUS_previous-names)


#uuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuu
#
#                    The makefile preamble is now complete
#
#nnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnn

# Negate make target assumptions

.SUFFIXES:

COMMON     := -g -Wall -Wextra -Wpedantic -Og
CFLAGS     := -x c              $(COMMON)
CPPFLAGS   := -x c++-cpp-output $(COMMON)
LINK_FLAGS := -pthread          $(COMMON)


###############################################################################

0hana-main: 0hana-main.c $(object_files)
	@echo '%  Compiling  : hanamade/$(@)'
	@gcc   $(LINK_FLAGS)   $(^) -o  $(@)


formulating_script := "$(hanamake_source_code)/build-support/formulating.sh"

0hana-main.c: $(target_files)
	@echo '---------------'
	@echo '+ Formulating : hanamade/$(@)'
	@sh    $(formulating_script)    $(@)


###############################################################################

build_to_build = hanamade/$(<) -> .../$(notdir $(@))

build/%.o: build/%.s
	@echo '- Mechanizing : $(build_to_build)'
	@gcc   -x assembler    $(<) -o  $(@) -c


build/%.opp: build/%.spp
	@echo '- Mechanizing : $(build_to_build)'
	@g++   -x assembler    $(<) -o  $(@) -c


###############################################################################

# Until a robust and reliable method is made to identify meaningful
# object changes between assembly files, the "one-function one-file"
# approach is only known way to generally achieve re-test minimization.
#
# In the meantime, remove and remake build/%.i(pp) directories per source update

remove_and_remake_script = \
  echo '- Subdividing : $(build_to_build)' \
  ; rm -r -f $(@) $(@:build/%=log/%) \
  ; mkdir -p $(@) $(@:build/%=log/%)

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
    ; if grep -q  "$${function_name}, @function" $(basename $(@))$(if $(filter %.i, $(@)),.s,.spp) \
    ; then touch $(@:build/%=log/%)/$${function_name}.log \
    ; else rm    $(@)/$${function_name} \
    ; fi \
  \
  ; done

build/%.i: build/%.s
	@$(remove_and_remake_script)
	@$(csplit_script)


build/%.ipp: build/%.spp
	@$(remove_and_remake_script)
	@$(csplit_script)


###############################################################################

hanamade_test_parameters := \
  FILE      ** const __hanamade_test__log_file, \
  char const * const __hanamade_test__log_path, \
  char const * const __hanamade_test__targetID

hanamade_assert_definition := \
  (expression) \
  ? \
  ( 1 ) \
  : \
  ( \
    ( \
      (void) \
      ( \
        (*__hanamade_test__log_file == NULL) && \
        (*__hanamade_test__log_file = fopen(__hanamade_test__log_path, "w")) && \
        (fprintf \
         ( *__hanamade_test__log_file \
         , "-------------------------------------------------------------------------------\n" \
           __FILE__ "\n"\
           "Failed target id:  %s\n" \
           "Failed assert(s):\n" \
         , __hanamade_test__targetID \
         ) \
        ) \
      ) \
    ) \
    , fprintf(*__hanamade_test__log_file, "\nLine No.  %i : (" \#expression ")\n", __LINE__) \
    __VA_OPT__(, \
      fprintf(*__hanamade_test__log_file, "Context:  " __VA_ARGS__), fprintf(*__hanamade_test__log_file, "\n") \
    ) \
    , 0 \
  )

source_to_build = $(shell realpath --relative-base=.. '$(<)') \
  -> hanamade/build/.../$(notdir $(@))

build/%.s: source-link/%.c build/%.d | $(filter %.y %.ypp,$(target_files))
	@echo '- Translating : $(source_to_build)'
	@rm -f $(@:.s=.c.error)
	@cpp -include /usr/include/stdio.h \
	  -D'hanamake_test(function_name)=void @function_name@__hanamade_test__@($(hanamade_test_parameters))' \
	  -D'hanamake_assert(expression, ...)=($(hanamade_assert_definition))' \
	  $(<) \
	| grep -o '@[$$A-Z_a-z][$$0-9A-Z_a-z]*@__hanamade_test__@' \
	| while read -r name \
	; do : \
	  ; name="$${name#@}" \
	  ; name="$${name%@__hanamade_test__@}" \
	  ; : ::::::::::::::::::::::::::::::::::::::::::: \
	  ; if ! test -f normal-name/"$${name}" \
	  ; then : \
	    ; >>$(@:.s=.c.error) echo "-------------------------------------------------------------------------------" \
	    ; >>$(@:.s=.c.error) echo "! BUILD ERROR : hanamake_test C function target" \
	    ; >>$(@:.s=.c.error) echo \
	    ; >>$(@:.s=.c.error) echo "                  $${name}" \
	    ; >>$(@:.s=.c.error) echo \
	    ; >>$(@:.s=.c.error) echo "                IS UNDEFINED" \
	    ; >>$(@:.s=.c.error) echo \
	    ; >>$(@:.s=.c.error) echo "                Targeted in:" \
	    ; >>$(@:.s=.c.error) echo \
	    ; >>$(@:.s=.c.error) echo "                  $$(realpath --relative-base=.. '$(<)')" \
	    ; >>$(@:.s=.c.error) echo \
	  ; fi \
	  ; : ::::::::::::::::::::::::::::::::::::::::::: \
	; done \
	; if test -f $(@:.s=.c.error) \
	; then exit 1 \
	; fi \
	; gcc     $(CFLAGS)    $(<) -o  $(@) -S \
	  -include /usr/include/stdio.h \
	  -D'hanamake_test(function_name)=void function_name##__hanamade_test__($(hanamade_test_parameters))' \
	  -D'hanamake_assert(expression, ...)=($(hanamade_assert_definition))'


build/%.spp: build/%.xpp
	@echo '- Translating : $(build_to_build)'
	@g++     $(CPPFLAGS)   $(<) -o  $(@) -S


###############################################################################

build/%.y: source-link/%.c build/%.d | $(previous_names)
	@echo '- Harmonizing : $(source_to_build)'
	@rm -f $(@:.y=.c.error)
	@cpp \
	  -D'hanamake_test(function_name)=void @function_name@__hanamade_test__@(void)' \
	  -D'hanamake_assert(expression, ...)=(0)' \
	  $(<) \
	| grep -o '@[$$A-Z_a-z][][ $$&()*,0-9:<>A-Z_a-z]*@__hanamade_test__@' \
	| while read -r name \
	; do : \
	  ; name="$${name#@}" \
	  ; name="$${name%@__hanamade_test__@}" \
	  ; : ::::::::::::::::::::::::::::::::::::::::::: \
	  ; if printf "%s" "$${name}" | grep -q '[^$$0-9A-Z_a-z][^$$0-9A-Z_a-z]*' \
	  ; then : \
	    ; >>$(@:.y=.c.error) echo "-------------------------------------------------------------------------------" \
	    ; >>$(@:.y=.c.error) echo "! BUILD ERROR : hanamake_test C function target name" \
	    ; >>$(@:.y=.c.error) echo \
	    ; >>$(@:.y=.c.error) echo "                  $${name}" \
	    ; >>$(@:.y=.c.error) echo \
	    ; >>$(@:.y=.c.error) echo "                IS NOT VALID" \
	    ; >>$(@:.y=.c.error) echo \
	    ; >>$(@:.y=.c.error) echo "                Names beginning with an underscore '_' or letter," \
	    ; >>$(@:.y=.c.error) echo "                followed by ascii-coded underscores, letters, and numbers" \
	    ; >>$(@:.y=.c.error) echo "                are valid." \
	    ; >>$(@:.y=.c.error) echo \
	    ; >>$(@:.y=.c.error) echo "                Targeted in:" \
	    ; >>$(@:.y=.c.error) echo \
	    ; >>$(@:.y=.c.error) echo "                  $$(realpath --relative-base=.. '$(<)')" \
	    ; >>$(@:.y=.c.error) echo \
	  ; fi \
	  ; : ::::::::::::::::::::::::::::::::::::::::::: \
	; done \
	; if test -f $(@:.y=.c.error) \
	; then exit 1 \
	; fi \
	; gcc     -x c -Og     $(<) -o  $(@) -S \
	  -D'hanamake_test(function_name)=void function_name##__hanamade_test__(void)' \
	  -D'hanamake_assert(expression, ...)=(0)' \
	  || exit 1 \
	; grep -x '[$$A-Z_a-z][$$0-9A-Z_a-z]*:' $(@) \
	| sed 's/:$$//' \
	| grep -v '__hanamade_test__$$' \
	| while read -r normal_name \
	; do : \
	  ; touch normal-name/"$${normal_name}" \
	  ; >>$(@:build/%=previous-names/%) printf "%s\n" "normal-name/$${normal_name}" \
	; done


build/%.xpp: source-link/%.cpp build/%.dpp | $(filter %.ypp,$(target_files))
	@echo '- Realizing X : $(source_to_build)'
	@ rm -f $(@:.xpp=.cpp.error) \
	; SURROGATE="$$(mktemp)" \
	; trap 'rm "$${SURROGATE}"' EXIT \
	; cpp -include /usr/include/stdio.h \
	  -D'hanamake_test(function_signature)=extern "C" void @function_signature@__hanamade_test__@($(hanamade_test_parameters))' \
	  -D'hanamake_assert(expression, ...)=($(hanamade_assert_definition))' \
	  $(<) \
	| tee $(@) > "$${SURROGATE}" \
	; grep -o '@[$$A-Z_a-z][ $$&()*,0-9:A-Z_a-z]*@__hanamade_test__@' "$${SURROGATE}" \
	| while read -r signature \
	; do : \
	  ; sed_safe_original="$$(printf "%s" "$${signature}" | sed -e 's/[*]/[*]/g' -e 's/[$$]/[$$]/g')" \
	  \
	  ; signature="$${signature#@}" \
	  ; signature="$${signature%@__hanamade_test__@}" \
	  \
	  ; signature_in_source_file="$${signature}" \
	  \
	  ; signature="$$(printf "%s" "$${signature}" \
	                 | sed -e 's/[\t]/ /g' \
	                       -e 's/[ ][ ]*/ /g' \
	                       -e 's/( /(/g' \
	                       -e 's/ )/)/g' \
	                       -e 's/ ,/,/g' \
	                       -e 's/,\([^ ]\)/, \1/g' \
	                       -e 's/ \([&*]\)/\1/g' \
	                       -e 's/\([&*]\)\([^&)*,]\)/\1 \2/g' \
	                       -e 's/\([&*]\) const\([),]\)/\1\2/g' \
	                 )" \
	  ; : ::::::::::::::::::::::::::::::::::::::::::: \
	  ; if ! test -f mangled-name/"$${signature}" \
	  ; then : \
	    ; >>$(@:.xpp=.cpp.error) echo "-------------------------------------------------------------------------------" \
	    ; >>$(@:.xpp=.cpp.error) echo "! BUILD ERROR : hanamake_test C++ function target" \
	    ; >>$(@:.xpp=.cpp.error) echo \
	    ; >>$(@:.xpp=.cpp.error) echo "                  $${signature_in_source_file}" \
	    ; >>$(@:.xpp=.cpp.error) echo \
	    ; >>$(@:.xpp=.cpp.error) echo "                IS UNDEFINED" \
	    ; >>$(@:.xpp=.cpp.error) echo \
	    ; >>$(@:.xpp=.cpp.error) echo "                mangled-name/<file> comparison form:" \
	    ; >>$(@:.xpp=.cpp.error) echo \
	    ; >>$(@:.xpp=.cpp.error) echo "                  $${signature}" \
	    ; >>$(@:.xpp=.cpp.error) echo \
	    ; >>$(@:.xpp=.cpp.error) echo "                Targeted in:" \
	    ; >>$(@:.xpp=.cpp.error) echo \
	    ; >>$(@:.xpp=.cpp.error) echo "                  $$(realpath --relative-base=.. '$(<)')" \
	    ; >>$(@:.xpp=.cpp.error) echo \
	  ; else : \
	    ; sed -i "s/$${sed_safe_original}/$$(cat mangled-name/"$${signature}")__hanamade_test__/g" $(@) \
	  ; fi \
	  ; : ::::::::::::::::::::::::::::::::::::::::::: \
	; done \
	; if test -f $(@:.xpp=.cpp.error) \
	; then : \
	  ; rm "$(@)" \
	  ; exit 1 \
	; fi


###############################################################################

build/%.ypp: build/%.zpp | $(previous_names)
	@echo '- Realizing Y : $(build_to_build)'
	@g++     $(CPPFLAGS)   $(<) -o  $(@) -S \
	  -Wno-unused-parameter \
	  -Wno-unused-value \
	  -Wno-unused-variable \
	  || exit 1 \
	; grep '^[$$A-Z_a-z][$$0-9A-Z_a-z]*:$$' $(@) \
	| sed  's/:$$//' \
	| while read -r mangled_name \
	; do : \
	  ; if ! printf "%s" "$${mangled_name}" | grep -qx '__hex_hash__[0-9A-Fa-f][0-9A-Fa-f]*__hanamade_test__' \
	  ; then : \
	    ; unmangled_name="$$(c++filt $${mangled_name})" \
	    ; if test "$${unmangled_name}" = "$${mangled_name}" \
	    ; then : \
	      ; touch normal-name/"$${mangled_name}" \
	      ; >>$(@:build/%=previous-names/%) printf "%s\n" normal-name/"$${mangled_name}" \
	    ; else : \
	      ; > mangled-name/"$${unmangled_name}" printf "%s\n" "$${mangled_name}" \
	      ; >>$(@:build/%=previous-names/%) printf "%s\n" mangled-name/"$${unmangled_name}" \
	    ; fi \
	  ; fi \
	; done


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
	; grep -o '@[$$A-Z_a-z][][ $$&()*,0-9:<>A-Z_a-z]*@__hanamade_test__@' "$${SURROGATE}" \
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
	    ; >>$(@:.zpp=.cpp.error) echo "                REQUIRES a parenthesized parameter type list '(type, ...)'" \
	    ; >>$(@:.zpp=.cpp.error) echo \
	    ; >>$(@:.zpp=.cpp.error) echo "                Targeted in:" \
	    ; >>$(@:.zpp=.cpp.error) echo \
	    ; >>$(@:.zpp=.cpp.error) echo "                  $$(realpath --relative-base=.. '$(<)')" \
	    ; >>$(@:.zpp=.cpp.error) echo \
	    ; continue \
	  ; fi \
	  ; if printf "%s" "$${signature}" | grep -q '[<>]' \
	  ; then : \
	    ; >>$(@:.zpp=.cpp.error) echo "-------------------------------------------------------------------------------" \
	    ; >>$(@:.zpp=.cpp.error) echo "! BUILD ERROR : hanamake_test C++ function target" \
	    ; >>$(@:.zpp=.cpp.error) echo \
	    ; >>$(@:.zpp=.cpp.error) echo "                  $${signature}" \
	    ; >>$(@:.zpp=.cpp.error) echo \
	    ; >>$(@:.zpp=.cpp.error) echo "                CANNOT USE a template parameter type list '<type, ...>'" \
	    ; >>$(@:.zpp=.cpp.error) echo \
	    ; >>$(@:.zpp=.cpp.error) echo "                If you need to test an instance of a template function," \
	    ; >>$(@:.zpp=.cpp.error) echo "                instantiate it inside a wrapper function and pass that" \
	    ; >>$(@:.zpp=.cpp.error) echo "                to 'hanamake_test( ... )'" \
	    ; >>$(@:.zpp=.cpp.error) echo \
	    ; >>$(@:.zpp=.cpp.error) echo "                For example:" \
	    ; >>$(@:.zpp=.cpp.error) echo \
	    ; >>$(@:.zpp=.cpp.error) echo "                  template <typename T>" \
	    ; >>$(@:.zpp=.cpp.error) echo "                  void print_generic(T data) { cout << data << endl; }" \
	    ; >>$(@:.zpp=.cpp.error) echo \
	    ; >>$(@:.zpp=.cpp.error) echo "                  void print_character(char C) { print_generic<char>(C); }" \
	    ; >>$(@:.zpp=.cpp.error) echo \
	    ; >>$(@:.zpp=.cpp.error) echo "                  hanamake_test(print_character(char)) { ... }" \
	    ; >>$(@:.zpp=.cpp.error) echo \
	    ; >>$(@:.zpp=.cpp.error) echo "                Targeted in:" \
	    ; >>$(@:.zpp=.cpp.error) echo \
	    ; >>$(@:.zpp=.cpp.error) echo "                  $$(realpath --relative-base=.. '$(<)')" \
	    ; >>$(@:.zpp=.cpp.error) echo \
	    ; continue \
	  ; fi \
	  ; if printf "%s" "$${signature}" | grep -q '[][]' \
	  ; then : \
	    ; >>$(@:.zpp=.cpp.error) echo "-------------------------------------------------------------------------------" \
	    ; >>$(@:.zpp=.cpp.error) echo "! BUILD ERROR : hanamake_test C++ function target" \
	    ; >>$(@:.zpp=.cpp.error) echo \
	    ; >>$(@:.zpp=.cpp.error) echo "                  $${signature}" \
	    ; >>$(@:.zpp=.cpp.error) echo \
	    ; >>$(@:.zpp=.cpp.error) echo "                CANNOT USE array bracket notation '[]' inside of" \
	    ; >>$(@:.zpp=.cpp.error) echo "                'hanamake_test( ... )'" \
	    ; >>$(@:.zpp=.cpp.error) echo \
	    ; >>$(@:.zpp=.cpp.error) echo "                For example:" \
	    ; >>$(@:.zpp=.cpp.error) echo \
	    ; >>$(@:.zpp=.cpp.error) echo "                  void function(type J[]);" \
	    ; >>$(@:.zpp=.cpp.error) echo "                  hanamake_test(function(type[])) { ... }" \
	    ; >>$(@:.zpp=.cpp.error) echo "                                             ^" \
	    ; >>$(@:.zpp=.cpp.error) echo \
	    ; >>$(@:.zpp=.cpp.error) echo "                should use an asterisk '*' instead:" \
	    ; >>$(@:.zpp=.cpp.error) echo \
	    ; >>$(@:.zpp=.cpp.error) echo "                  void function(type J[]);" \
	    ; >>$(@:.zpp=.cpp.error) echo "                  hanamake_test(function(type*)) { ... }" \
	    ; >>$(@:.zpp=.cpp.error) echo "                                             ^" \
	    ; >>$(@:.zpp=.cpp.error) echo \
	    ; >>$(@:.zpp=.cpp.error) echo "                Targeted in:" \
	    ; >>$(@:.zpp=.cpp.error) echo \
	    ; >>$(@:.zpp=.cpp.error) echo "                  $$(realpath --relative-base=.. '$(<)')" \
	    ; >>$(@:.zpp=.cpp.error) echo \
	    ; continue \
	  ; fi \
	  ; : ::::::::::::::::::::::::::::::::::::::::::: \
	  ; sed_input_signature="$$(printf "%s" "$${signature}" | sed -e 's/\*/\\*/g')" \
	  ; sed -i "s/@$${sed_input_signature}@__hanamade_test__@/__hex_hash__$$(printf "%s" "$${signature}" | xxd -p | tr -d '\n')__hanamade_test__/g" $(@) \
	; done \
	; if test -f $(@:.zpp=.cpp.error) \
	; then : \
	  ; rm "$(@)" \
	  ; exit 1 \
	; fi


###############################################################################

#uuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuu
# This part is a little complicated:
#
# The previous-names/% files are actually created by the build/%.y(pp) recipes
# --
# NOT HERE by their own makefile recipes
# --
# and are used to keep the set of defined function names in the 'mangled-name'
# and 'normal-name' directories consistent with those defined in source files
#
#------------------------------------------------------------------------------
# For any source file that was updated,
# the corresponding build/%.y(pp) makefile recipe that is invoked will
# not only create a build/%.y(pp) file,
# but also the files in the 'mangled-name' and 'normal-name' directories
# corresponding to the functions defined in that source file
#
# Unmanaged, this would only add to the set of defined function names,
# problematic when that set of names shrinks--suddenly undefined names
# are reported as defined in hanamake's record keeping system, but
# undefined by the GNU compiler--bit of a headache
#
# So we use the 'previous-names' files to delete a source file's previously
# defined set of function names BEFORE writing the new ones down in the
# 'mangled-name' and 'normal-name' directories
#
# This prevents undefined function names from existing in the defined names
# directories ('mangled-name' and 'normal-name'),
# but invites a new problem:
#
# If 2 files [A] and [B] are updated,
# and [A] newly defines a function name previously defined by [B]
# --
# thus in [B]'s previous-names file
# --
# and [A] updates the name BEFORE [B] deletes the name,
# then the name will appear to be undefined during %.s(pp) file generation
#
#------------------------------------------------------------------------------
# To solve this new problem,
# all previous-names files are listed as 'order-only' prerequisites of
# all build/%.y(pp)  files,
# and previous-names targets are given their corresponding source files as
# dependencies
#
# Since the previous-names files are actually generated by the build/%.y(pp)
# makefile recipes, we can use implicit pattern matching rules for
# for the previous-names/% files to delete their entries when a corresponding
# source file is updated
#
# This combination results in all previously defined names for updated source
# files being deleted BEFORE the invokation of build/%.y(pp) makefile recipes
# --
# which create the files in the 'mangled-name' and 'normal-name' directories
# --
# preventing the data race (creation vs. deletion) problem mentioned above
#nnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnn

previous-names/%.y: source-link/%.c
	@if test -f "$(@)" \
	; then : \
	  ; cat     "$(@)" | $(DELETE_PREVIOUS_NAMES); rm "$(@)" \
	; fi


previous-names/%.ypp: source-link/%.cpp
	@if test -f "$(@)" \
	; then : \
	  ; cat     "$(@)" | $(DELETE_PREVIOUS_NAMES); rm "$(@)" \
	; fi


###############################################################################

build/%.d: source-link/%.c
	@echo '- Prescanning : $(source_to_build)'
	@# Create additional makefile target dependencies for build/%.[sy] files
	@# so that if their #included files are updated, they will be remade
	@cpp $(<) -MF $(@) -MM -MP -MT '$(@:.d=.s) $(@:.d=.y)'


build/%.dpp: source-link/%.cpp
	@echo '- Prescanning : $(source_to_build)'
	@# Create additional makefile target dependencies for build/%.[xz]pp files
	@# so that if their #included files are updated, they will be remade
	@cpp $(<) -MF $(@) -MM -MP -MT '$(@:.dpp=.xpp) $(@:.dpp=.zpp)'


###############################################################################

-include $(filter %.d %.dpp, $(target_files))
