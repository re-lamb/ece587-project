#
# ECE 587 Fall 2024 - Final project
# R.E. Lamb
#

# build simulator and tests

PROG=sim
INCLUDES=defs.h
SOURCES=$(wildcard *.c)
OBJS=$(SOURCES:.c=.o)

CC=gcc -Wall


#
# Build the simulator
#	
sim: $(OBJS) $(INCLUDES)
	$(CC) -o $(PROG) $(OBJS)

#
# Generate .mem file from an assembler .s file
#
TESTDIR=../asm

tests: FORCE
	@cd $(TESTDIR) && $(MAKE) all 

check: FORCE
	@cd $(TESTDIR) && $(MAKE) check

# build the sim
all: sim tests

# clean up
clean:
	@rm -f $(OBJS) $(PROG)
	@cd $(TESTDIR) && $(MAKE) clean

FORCE:

