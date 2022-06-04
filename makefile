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
    && rm -f build/0hana-main.c \
  ) \
)

# Negate make target assumptions
.SUFFIXES:
CFLAGS   := -g -Wall -Wextra -Wpedantic
CPPFLAGS := -g -Wall -Wextra -Wpedantic

# Execute
run: build/0hana-main
	@echo 'generated build structure:' && tree build && echo 'vs' && tree source

clean:
	@rm -r build && echo 'All build files removed.'

# General build instructions
build/0hana-main: $(object_files) build/0hana-main.c
	@echo 'testing pseudo-$(@) generation'
	@touch $(@)

build/%.o:   source/%.c
	@echo 'testing $(@) generation'
	@gcc  $(CFLAGS)  $(<) -o $(@) -c

build/%.opp: source/%.cpp
	@echo 'testing $(@) generation'
	@g++ $(CPPFLAGS) $(<) -o $(@) -c

build/0hana-main.c: $(object_files)
	@echo 'testing pseudo-$(@) generation'
	@touch $(@)
