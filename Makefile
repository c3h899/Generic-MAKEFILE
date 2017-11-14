# WHERE'S THE STUFF
SOURCEDIR := Source
LIBDIR := Libraries

# The name of the project (names the compiled binary)
BINARY_NAME = test

# COMPILER OPTIONS
COMPILE_OPTIONS = -pthread

#************************************************************************
# Support for Additional compile-time parameters
#************************************************************************
# override directive utilized for text assertions printed to end-user
# https://www.gnu.org/software/make/manual/make.html#Override-Directive

# [BUILD TYPE]
# Defaults to debug build configuration if not specified
# Supported options: debug, internal, release
# https://gcc.gnu.org/onlinedocs/gcc-4.2.4/gcc/Debugging-Options.html#Debugging-Options
# DO NOT EDIT BUILD_FILE without consideration of "clean" recipie
ifeq ($(build),release)
	override build = RELEASE
	LD_BUILD = 
	CPP_DEBUG = -g0
else
	ifeq ($(build),internal)
		override build = INTERNAL
		LD_BUILD = 
		CPP_DEBUG = -g
	else
		# DEFAULT CASE
		override build = DEBUG
		LD_BUILD = -Xlinker -M=$(BINARY_NAME).map -Xlinker --cref
		CPP_DEBUG = -pedantic -Wextra -Wconversion -g3
	endif
endif

# [OPTIMIZATIONS]
# Defaults to NO optimizations
# Supported options: O0, O1, O2, O3
ifeq ($(optimize),O3)
	override optimize = O3
	COMPILE_OPTIMIZATION = -O3
else
	ifeq ($(optimize),O2)
		override optimize = O2
		COMPILE_OPTIMIZATION = -O2
	else
		ifeq ($(optimize),O1)
			override optimize = O1
			COMPILE_OPTIMIZATION = -O1
		else
			# DEFAULT CASE
			override optimize = O0
			COMPILE_OPTIMIZATION = -O0
		endif
	endif
endif

#************************************************************************
# Settings below this point usually do not need to be edited
#************************************************************************

# [TERMINAL COLORIZATION]
COLOR_INFO_PRE = \033[4;94m
COLOR_INFO_POST = \033[0m

# [WINDOWS] Adjust for target build environments (force .exe suffix)
# NOTE (1): See LDFLAGS variable for additional notes
ifeq ($(OS),Windows_NT)
	OS_LINKER = -Xlinker --force-exe-suffix
endif

# Automatically create lists of the sources and objects

# VPATH
VPATH=$(SOURCEDIR):$(shell find $(LIBDIR) -maxdepth 1 -type d -printf '%f:')

#### GNU MAKE VARIABLES ####
# https://www.gnu.org/software/make/manual/html_node/Implicit-Variables.html

# [COMMON] "Extra flags to give to the C preprocessor and programs that use it (the C and Fortran compilers)."
CPPFLAGS = -Wall $(CPP_DEBUG) $(COMPILE_OPTIMIZATION) -MMD $(COMPILE_OPTIONS) -I$(SOURCEDIR) $(shell find $(LIBDIR) -maxdepth 1 -type d -printf ' -I%p')

# [CPP] "Extra flags to give to the C++ compiler."
CXXFLAGS = -fPIC -std=gnu++1z -fno-elide-constructors -fno-exceptions

# [C] "Extra flags to give to the C compiler."
CFLAGS =

# [LINKER] "Extra flags to give to compilers when they are supposed to invoke the linker"
LDFLAGS = -fPIC $(LD_BUILD) -Xlinker --warn-common $(OS_LINKER)
# [1] -Xlinker necessary for passing options to linker directly
# see: https://gcc.gnu.org/onlinedocs/gcc-4.6.1/gcc/Link-Options.html for details

# [LINKER] "Library flags or names given to compilers when they are supposed to invoke the linker"
LDLIBS = 

#### TOOLCHAIN ####
# Names for the compiler programs
CC = gcc
CXX = g++
LD = ld

# Version query commands
CC_VER = $(CC) $(shell $(CC) -dumpversion)
CXX_VER = $(CXX) $(shell $(CXX) -dumpversion)
LD_VER = $(shell $(LD) -v)

#### FIND ALL THE SOURCES ####
# Find Source Files in Source and Library Directory
C_FILES := $(shell find $(SOURCEDIR) -name '*.c')
CPP_FILES := $(shell find $(SOURCEDIR) -name '*.cpp')

C_LIBS := $(shell find $(LIBDIR) -name '*.c')
CPP_LIBS := $(shell find $(LIBDIR) -name '*.cpp')
OBJECTS := $(C_LIBS:.c=.o) $(C_FILES:.c=.o)
OBJECTS += $(CPP_LIBS:.cpp=.o) $(CPP_FILES:.cpp=.o)

#### MAKE RECIPIES ####

#.PHONY targets
.PHONY: all build-log clean dirs dummy-all from-source info version

all: | version dummy-all
	@printf "\n$(COLOR_INFO_PRE)($$(date --rfc-3339=seconds)) [COMPLETE]$(COLOR_INFO_POST)\n"

build-log:
	@rm -f BUILD
	@printf "($$(date --rfc-3339=seconds)) [BUILD]" >> BUILD
	@printf "\nBuild Information:" >> BUILD
	@printf "\n\tBuild Type: $(build)" >> BUILD
	@printf "\n\tOptimization: $(optimize)" >> BUILD
	@printf "\n\tTarget OS: $(OS)" >> BUILD
	@printf "\nBuild Tools:" >> BUILD
	@printf "\n\tCompiler (C): $(CC_VER)" >> BUILD
	@printf "\n\tCompiler (CPP): $(CXX_VER)" >> BUILD
	@printf "\n\tLinker: $(LD_VER)" >> BUILD

clean:
	@printf "\n$(COLOR_INFO_PRE)($$(date --rfc-3339=seconds)) [CLEAN]$(COLOR_INFO_POST)\n"
	@find . -type f -name "*.o" -delete
	@find . -type f -name "*.d" -delete
	@rm -f $(BINARY_NAME).map
	@rm -f $(BINARY_NAME) $(BINARY_NAME).exe
	@rm -f BUILD

dirs:
	@mkdir -p $(SOURCEDIR)
	@mkdir -p $(LIBDIR)
	
dummy-all: | info $(BINARY_NAME)
# Order-dependent to ensure information print-out is at top of console

from-source: | clean build-log dummy-all
# Order-dependent to ensure any existing compiled content is cleaned first.

info:
	@printf "\n$(COLOR_INFO_PRE)($$(date --rfc-3339=seconds)) [MAKE]$(COLOR_INFO_POST)"
	@printf "\nBuild Information:"
	@printf "\n\tBuild Type: $(build)"
	@printf "\n\tOptimization: $(optimize)"
	@printf "\n\tTarget OS: $(OS)"
	@printf "\nBuild Tools:"
	@printf "\n\tCompiler (C): $(CC_VER)"
	@printf "\n\tCompiler (CPP): $(CXX_VER)"
	@printf "\n\tLinker: $(LD_VER)"
	@printf "\n"

version:
	@printf "\n$(COLOR_INFO_PRE)($$(date --rfc-3339=seconds)) [VERSION CHECK]$(COLOR_INFO_POST)\n"
	@if $$(grep -q "$(build)" BUILD) && $$(grep -q "$(optimize)" BUILD); then\
		printf "Build version and optimization are consistent.\n";\
	else\
		make clean;\
		make build-log;\
	fi

#### ACTUAL INTERACTION WITH CODE (STARTS HERE) ####
$(BINARY_NAME): $(OBJECTS)
	@printf "\n$(COLOR_INFO_PRE)($$(date --rfc-3339=seconds)) [LINK BINARY] $@$(COLOR_INFO_POST)\n"
	$(CXX) $(CPP_DEBUG) -o $@ $(OBJECTS) $(LDFLAGS)
	@# Everything goes to hell if CC is called, not CXX

#### IMPLICIT RULES (DEFINED) ####
# Re-Define C for added verbosity
# Explicit use of (CXX) necessary for Cygwin compatibility
%.o : %.c
	@printf "\n$(COLOR_INFO_PRE)($$(date --rfc-3339=seconds)) [COMPILE C] $@$(COLOR_INFO_POST)\n"
	$(CC) -c $< $(CPPFLAGS) $(CFLAGS) -o $@
	
# Re-Define CPP for added verbosity [1/4]
%.o : %.cpp
	@printf "\n$(COLOR_INFO_PRE)($$(date --rfc-3339=seconds)) [COMPILE CPP] $@$(COLOR_INFO_POST)\n"
	$(CXX) -c $< $(CPPFLAGS) $(CXXFLAGS) -o $@

# Re-Define CPP for added verbosity [2/4]
%.o : %.cc
	@printf "\n$(COLOR_INFO_PRE)($$(date --rfc-3339=seconds)) [COMPILE CPP] $@$(COLOR_INFO_POST)\n"
	$(CXX) -c $< $(CPPFLAGS) $(CXXFLAGS) -o $@

# Re-Define CPP for added verbosity [3/4]
%.o : %.cxx
	@printf "\n$(COLOR_INFO_PRE)($$(date --rfc-3339=seconds)) [COMPILE CPP] $@$(COLOR_INFO_POST)\n"
	$(CXX) -c $< $(CPPFLAGS) $(CXXFLAGS) -o $@

# Re-Define CPP for added verbosity [4/4]
%.o : %.C
	@printf "\n$(COLOR_INFO_PRE)($$(date --rfc-3339=seconds)) [COMPILE CPP] $@$(COLOR_INFO_POST)\n"
	$(CXX) -c $< $(CPPFLAGS) $(CXXFLAGS) -o $@
