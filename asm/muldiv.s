#include "isa.asm"
; MUL/DIV tests

	clr d0
	movi #5, d1		; d1 = 5
	movi #25, d2	; d2 = 25
	div.w d1, d2	; 25 / 5 = 5
	seq d1, d2
	bf fail
	
	mod.w d1, d2	; 5 % 5 = 0
	seq d0, d2
	bf fail
	
	mov d1, d2		; d2 = 5
	mul.w d2, d2	; 5 * 5 = 25
	seq #25, d2	
	bf fail
	
	nop
	nop
	exit
	
fail:
    movi #0, d0
    not d0, d0
    exit                    ; exit -1 on fail
