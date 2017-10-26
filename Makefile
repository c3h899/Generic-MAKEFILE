# WHERE'S THE STUFF
SOURCEDIR := Source
LIBDIR := Libraries

# The name of the project (names the compiled binary)
BINARY_NAME = circle_box

# COMPILER OPTIONS
COMPILE_OPTIONS = -pthread
COMPILE_OPTIMIZATION = -O0

# [DEBUGGING] Settings
LINK_DEBUG = -g3
#https://gcc.gnu.org/onlinedocs/gcc-4.2.4/gcc/Debugging-Options.html#Debugging-Options

#************************************************************************
# Settings below this point usually do not need to be edited
#************************************************************************

# [WINDOWS] Adjust for target build environments (force .exe suffix)
# NOTE (1): See LDFLAGS variable for additional notes
ifeq ($(OS),Windows_NT)
	WIN_LINKER = -Xlinker --force-exe-suffix
endif

# Automatically create lists of the sources and objects

# VPATH
VPATH=$(SOURCEDIR):$(shell find $(LIBDIR) -maxdepth 1 -type d -printf '%f:')

#### GNU MAKE VARIABLES ####
# https://www.gnu.org/software/make/manual/html_node/Implicit-Variables.html

# [COMMON] "Extra flags to give to the C preprocessor and programs that use it (the C and Fortran compilers)."
CPPFLAGS = -Wall  $(COMPILE_OPTIMIZATION) -MMD $(COMPILE_OPTIONS) -I$(SOURCEDIR) $(shell find $(LIBDIR) -maxdepth 1 -type d -printf ' -I%p')

# [CPP] "Extra flags to give to the C++ compiler."
CXXFLAGS = -fPIC -std=gnu++1z -fno-elide-constructors -fno-exceptions

# [C] "Extra flags to give to the C compiler."
CFLAGS =

# [LINKER] "Extra flags to give to compilers when they are supposed to invoke the linker"
LDFLAGS = -fPIC -Xlinker -M=$(BINARY_NAME).map -Xlinker --cref -Xlinker --warn-common $(WIN_LINKER)
# [1] -Xlinker necessary for passing options to linker directly
# see: https://gcc.gnu.org/onlinedocs/gcc-4.6.1/gcc/Link-Options.html for details

# [LINKER] "Library flags or names given to compilers when they are supposed to invoke the linker"
LDLIBS = 

#### GNU MAKE TOOLS ####
# Names for the compiler programs
CC = gcc
CXX = g++
LD = ld

#### FIND ALL THE SOURCES ####
# Find Source Files in Source and Library Directory
C_FILES := $(shell find $(SOURCEDIR) -name '*.c')
CPP_FILES := $(shell find $(SOURCEDIR) -name '*.cpp')

C_LIBS := $(shell find $(LIBDIR) -name '*.c')
CPP_LIBS := $(shell find $(LIBDIR) -name '*.cpp')
OBJECTS := $(C_LIBS:.c=.o) $(C_FILES:.c=.o)
OBJECTS += $(CPP_LIBS:.cpp=.o) $(CPP_FILES:.cpp=.o)

#### MAKE RECIPIES ####
all: $(BINARY_NAME)
	@printf "\n($$(date --rfc-3339=seconds)) [MAKE ALL]\n\n"

$(BINARY_NAME): $(OBJECTS)
	@printf "\n($$(date --rfc-3339=seconds)) [LINK BINARY] $@\n"
	$(CXX) $(LINK_DEBUG) -o $@ $(OBJECTS) $(LDFLAGS)
	@# Everything goes to hell if CC is called, not CXX

#### IMPLICIT RULES (DEFINED) ####
# Re-Define C for added verbosity
%.o : %.c
	@printf "\n($$(date --rfc-3339=seconds)) [COMPILE C] $@\n"
	$(CC) -c $< $(CPPFLAGS) $(CFLAGS) -o $@
	
# Re-Define CPP for added verbosity [1/4]
%.o : %.cpp
	@printf "\n($$(date --rfc-3339=seconds)) [COMPILE CPP] $@\n"
	$(CXX) -c $< $(CPPFLAGS) $(CXXFLAGS) -o $@

# Re-Define CPP for added verbosity [2/4]
%.o : %.cc
	@printf "\n($$(date --rfc-3339=seconds)) [COMPILE CPP] $@\n"
	$(CXX) -c $< $(CPPFLAGS) $(CXXFLAGS) -o $@

# Re-Define CPP for added verbosity [3/4]
%.o : %.cxx
	@printf "\n($$(date --rfc-3339=seconds)) [COMPILE CPP] $@\n"
	$(CXX) -c $< $(CPPFLAGS) $(CXXFLAGS) -o $@

# Re-Define CPP for added verbosity [4/4]
%.o : %.C
	@printf "\n($$(date --rfc-3339=seconds)) [COMPILE CPP] $@\n"
	$(CXX) -c $< $(CPPFLAGS) $(CXXFLAGS) -o $@

#### MAKE CLEAN ####
clean:
	@printf "\n($$(date --rfc-3339=seconds)) [CLEAN]\n"
	find . -type f -name "*.o" -delete
	find . -type f -name "*.d" -delete
	rm -f $(BINARY_NAME) $(BINARY_NAME).exe
