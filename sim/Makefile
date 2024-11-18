#
# ECE 587 Fall 2024 - Final project
# R.E. Lamb
#
# build ISA simulator 
#

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

# build the sim
all: sim

# clean up
clean:
	@rm -f $(OBJS) $(PROG)
