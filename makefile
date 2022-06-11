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

.PHONY: clean run

# Identify target files
source_files := \
  $(shell 2>/dev/null find source \( -name '*.c' -o -name '*.cpp' \) -type f)

object_files := \
  $(foreach source, $(filter %.c,   $(source_files)), $(source:source/%.c=build/%.o)) \
  $(foreach source, $(filter %.cpp, $(source_files)), $(source:source/%.cpp=build/%.opp))

target_files := \
  $(foreach base, $(basename $(filter %.o,   $(object_files))), $(base).d   $(base).i   $(base).o   $(base).s) \
  $(foreach base, $(basename $(filter %.opp, $(object_files))), $(base).dpp $(base).ipp $(base).opp $(base).spp)

.PRECIOUS: $(if $(source_files), $(target_files), $(error missing source (.c or .cpp) files))

# Identify and Isolate target directories
target_directories := $(sort $(dir $(object_files)))
$(shell mkdir -p $(target_directories))
$(shell mv build previous_build)
$(shell mkdir -p $(target_directories))

# Transfer existing target files to current build
$(foreach target, $(target_files), $(shell test -e 'previous_$(target)' && mv 'previous_$(target)' '$(target)'))
$(shell test -f previous_build/0hana-main   && mv previous_build/0hana-main   build/0hana-main)
$(shell test -f previous_build/0hana-main.c && mv previous_build/0hana-main.c build/0hana-main.c)
$(shell rm -r   previous_build \
  $(if \
    $(shell find previous_build \( -name '*.[dios]' -o -name '*.[dios]pp' \)), \
    $(info Removing build/0hana-main.c to ensure consistency with removed or renamed source files) \
    $(info ) \
    && rm -f build/0hana-main.c \
  ) \
)

# Negate make target assumptions
.SUFFIXES:
CFLAGS     := -x c   -g -Wall -Wextra -Wpedantic
CPPFLAGS   := -x c++ -g -Wall -Wextra -Wpedantic
LINK_FLAGS :=        -g -Wall -Wextra -Wpedantic

# Execute
run: build/0hana-main
	@echo '-- EXECUTING --'
	@$(<)

clean:
	@rm -r build && echo 'All build files removed.'

# Special build variables
hanamake_test_parameters := \
  FILE      ** const __hanamake_test__log_file, \
  char const * const __hanamake_test__log_path

hanamake_assert_definition := \
  (expression) \
  ? \
  ( ((void)((*__hanamake_test__log_file == NULL) && remove(__hanamake_test__log_path))), 1 ) \
  : \
  ( \
    ( \
      (void) \
      ( \
        (*__hanamake_test__log_file == NULL) && \
        (*__hanamake_test__log_file = fopen(__hanamake_test__log_path, "w")) && \
        (fprintf(*__hanamake_test__log_file, __FILE__ "\nFailed assert(s):\n")) \
      ) \
    ) \
    , fprintf(*__hanamake_test__log_file, "\nLine   \#  %i : (" \#expression ")\n", __LINE__) \
    __VA_OPT__(, \
      fprintf(*__hanamake_test__log_file, "Context:  " __VA_ARGS__), fprintf(*__hanamake_test__log_file, "\n") \
    ) \
    , 0 \
  )

# The first  gcc checks to see if the user is missing #include <stdio.h>
# The second gcc includes <stdio.h> and defines the hanamake macros in .c(pp)
ASM_INCLUSIONS = \
  -Wno-unused-value \
  -D'hanamake_test(test_name)=$(if $(filter %.spp,$(<)), extern "C") \
     void __hanamake_test__\#\#test_name(void)' \
  -D'hanamake_assert(expression, ...)=(0)'; \
  $(if $(filter %.spp, $(<)), g++ $(CPPFLAGS), gcc $(CFLAGS)) $(<) -o $(@) -S \
  -include /usr/include/stdio.h \
  -D'hanamake_test(test_name)=$(if $(filter %.spp,$(<)), extern "C") \
     void __hanamake_test__\#\#test_name($(hanamake_test_parameters))' \
  -D'hanamake_assert(expression, ...)=($(hanamake_assert_definition))'

# General build instructions
build/0hana-main: $(object_files) build/0hana-main.c
	@echo '+  Compiling  : $(@)'
	@gcc    $(LINK_FLAGS)  $(^) -o $(@)

build/%.o: build/%.s
	@echo '- Mechanizing : $(<) -> $(@)'
	@gcc   -x assembler    $(<) -o $(@) -c

build/%.s: source/%.c build/%.d
	@echo '- Translating : $(<) -> $(@)'
	@gcc      $(CFLAGS)    $(<) -o $(@) -S $(ASM_INCLUSIONS)

build/%.d: source/%.c
	@echo '- Prescanning : $(<) -> $(@)'
	@# Create additional makefile target dependencies for build/%.s files
	@# so that if their #include "files" are updated, they will be remade
	@cpp $(<) -MF $(@) -MM -MP -MT $(@:.d=.s)

build/%.opp: build/%.spp
	@echo '- Mechanizing : $(<) -> $(@)'
	@g++   -x assembler    $(<) -o $(@) -c

build/%.spp: source/%.cpp build/%.dpp
	@echo '- Translating : $(<) -> $(@)'
	@g++     $(CPPFLAGS)   $(<) -o $(@) -S $(ASM_INCLUSIONS)

build/%.dpp: source/%.cpp
	@echo '- Prescanning : $(<) -> $(@)'
	@# Create additional makefile target dependencies for build/%.spp files
	@# so that if their #include "files" are updated, they will be remade
	@cpp $(<) -MF $(@) -MM -MP -MT $(@:.dpp=.spp)

build/0hana-main.c: $(filter %.i %.ipp, $(target_files))
	@echo '- Formulating : $(@)'
	@sh      formulating.sh        $(@) \
	"\
	$$(for directory in $(^)\
	  ; do :\
	    ; for file in $$(ls -1A $${directory} | grep -v '.log$$')\
	    ; do echo "$${file}/$${directory}/$${file}"\
	    ; done\
	  ; done\
	  | LC_COLLATE=C sort -k1 -t/\
	  | sed 's/^[$$0-9A-Z_a-z][$$0-9A-Z_a-z]*\///'\
	  )\
	"

# Until a robust and reliable method is made to identify meaningful
# object changes between assembly files, the "one-function one-file"
# approach is only known way to generally achieve re-test minimization.
#
# In the meantime, remove and remake build/%.i(pp) directories per source update
remove_and_remake_script = \
  echo '- Subdividing : $(<) -> $(@)'; rm -rf $(@) && mkdir $(@)

# Split build/%.s(pp) files into partial assembly files under build/%.i(pp)
csplit_script = \
  csplit --prefix='$(@)/csplit_' --suffix-format='%%_%i.x' --silent $(<) \
  $$(echo \
    $$(grep      '^[_A-Za-z0-9$$][_A-Za-z0-9$$]*:$$' $(<) \
      | sed  's/\(^[_A-Za-z0-9$$][_A-Za-z0-9$$]*:$$\)/\/^\1$$\//' \
      ) \
    | sed 's/\/\(\^[_A-Za-z0-9$$][_A-Za-z0-9$$]*:\$$\)\//%\1%/' \
    ) \
  ; for csplit_file in   $(@)/csplit_*.x \
  ; do function_name="$$(head -n 1 $${csplit_file} | sed 's/://')" \
  \
    ; mv $${csplit_file} $(@)/$${function_name} \
    ; touch $(@)/$${function_name}.log \
  \
  ; done

build/%.i: build/%.s
	@$(remove_and_remake_script)
	@$(csplit_script)

build/%.ipp: build/%.spp
	@$(remove_and_remake_script)
	@$(csplit_script)

-include $(filter %.d %.dpp, $(target_files))
