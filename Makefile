#
# ECE 587 Fall 2024 - Final project
# R.E. Lamb
#
# top level Makefile
#

help:
	@echo "targets:"
	@echo "	all   - build everything"
	@echo "	sim   - build ISA simulator"
	@echo "	asm   - build assembler"
	@echo "	vsim  - build verilated simulator"
	@echo "	check - run ISA simulator tests"
	@echo "	clean - clean all"

# build simulator and tests
all: sim asm vsim

#
# build the simulator, assembler, and verilated simulator
#
sim: FORCE
	@cd sim && $(MAKE) all

asm: FORCE
	@cd asm && $(MAKE) all
	
vsim: FORCE
	@cd hdl && $(MAKE) Vsim		

check: FORCE
	@cd asm && $(MAKE) check

# clean up
clean:
	@cd sim && $(MAKE) clean
	@cd asm && $(MAKE) clean
	@cd hdl && $(MAKE) clean
	
FORCE:

