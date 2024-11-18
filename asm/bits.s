; bit flippin tests
; bset bclr bnot btst

#include "isa.asm"

    xor d0, d0              ; d0 = 0
    not d0, d1              ; d1 = -1
	movi #1, d2				; d2 = 1
	
	bset #0, d0				; d0 = 1
    seq d0, d2              ; test
    bf fail                 ; and branch
	bclr #0, d0				; d0 = 0
	seq #0, d0			
	bf fail
	
	mov d2, d3				; d3 = 1
	slli #3, d3				; d3 = 8
    bset #3, d4				; d4 = 8
	add d3, d4				; d4 = 16
	clrt		
	btst #4, d4				; T = 0 -> 1 	
	bf fail
	sett
	btst #5, d4				; T = 1 -> 0
	bt fail
	
	bnot #5, d4				; d4 = 48
	btst #5, d4				; T = 0 -> 1
	bf fail
	
	clrt
	mov d1, d3				; d3 = -1
	bclr #0, d3				; d3 = -2
	seq #-2, d3
	bf fail
	
    nop
    nop
    nop
    exit
    
fail:
    movi #0, d0
    not d0, d0
    exit                    ; exit -1 on fail
    
pool:
#d16 0x5555, 0xaaaa, 0x4000, 0x8000, 15, -8



