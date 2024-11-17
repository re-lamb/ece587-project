#
# ECE 587 Fall 2024 - Final project
# R.E. Lamb
#
# Makefile for the test suite
#

PROG=../sim/sim
ASM=customasm
ASMFLAGS=-f annotated,base:16,group:2

TESTSRC=$(wildcard *.s)
TESTOBJ=$(TESTSRC:%.s=%.mem)
TESTS=$(wildcard *.mem)

%.mem : %.s
	$(ASM) $< $(ASMFLAGS) -o $@

all: $(TESTOBJ)

check: $(TESTS)
	@for f in $(TESTS); do 					\
		echo "";							\
		echo -n "Running test $$f...";		\
		$(PROG) -d $$f >> test.log 2>&1;	\
		if [ $$? -eq 0 ]; then				\
			echo "PASS";					\
		else								\
			echo "FAIL";					\
		fi									\
	done

clean:
	@rm -f *.mem test.log
	
