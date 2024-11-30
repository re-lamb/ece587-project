#include "isa.asm"
; MUL/DIV tests

	clr d0
	mov #5, d1	; d1 = 5
	mov #25, d2	; d2 = 25
	div d1, d2	; 25 / 5 = 5
	seq d1, d2
	bf fail
	
	mod d1, d2	; 5 % 5 = 0
	seq d0, d2
	bf fail
	
	mov d1, d2	; d2 = 5
	mul d2, d2	; 5 * 5 = 25
	seq #25, d2	
	bf fail
	
	nop
	nop
	exit
	
fail:
    mov #0, d0
    not d0, d0
    exit		; exit -1 on fail
