;
; ECE 587 Fall 2024 - Final project
; R.E. Lamb
;
; muldiv.s - test the multiply/divide instructions
;            (in the C sim, part of the ALU; in the
;            Verilog model/hardware, to be a separate
;            execution unit)
;
; tests:
;   mul, div, mod (and variants)
;
; assumes the following instructions are correct:
;   xor, not, seq, mov, ld.w, bf, bt, clrt
;

#include "isa.asm"

    clr d0
    mov #5, d1      ; d1 = 5
    mov #25, d2     ; d2 = 25
    div d1, d2      ; 25 / 5 = 5
    seq d1, d2
    bf fail

    mod d1, d2      ; 5 % 5 = 0
    seq d0, d2
    bf fail

    mov d1, d2      ; d2 = 5
    mul d2, d2      ; 5 * 5 = 25
    seq #25, d2 
    bf fail

    nop
    nop
    exit

fail:
    mov #0, d0
    not d0, d0
    exit            ; exit -1 on fail

