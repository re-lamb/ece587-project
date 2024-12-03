;
; ECE 587 Fall 2024 - Final project
; R.E. Lamb
;
; simple.s
;
; straight ahead short test with no branches or
; loads/stores, for debugging initial bringup of
; the verilog model.  needs waaay more thought to
; specifically test for various hazards
;

#include "isa.asm"

    xor d0, d0              ; d0 = 0
    not d0, d1              ; d1 = -1
    mov #1, d2              ; d2 = 1
    clr d3                  ; d3 = 0
    mova d2, a2             ; a2 = 1    access addr regs
    adda d1, a2             ; a2 = 0    math?
    add d0, d0              ; 0 + 0 = 0
    add d2, d3              ; 0 + 1 = 1
    add d1, d3              ; -1 + 1 = 0
    mov d1, d4              ; d4 = -1
    add d0, d4              ; 1 - 0 = -1
    sett                    ; t = 1
    addc d0, d4             ; -1 + 0 + 1 = 0
    sub d2, d3              ; d3 = -1   
    sett                    ; t = 1
    subc d0, d3             ; 0 - (-1) - 1 = 0
    neg d2, d4              ; d4 = -1
    nott
    negc d1, d3             ; i'm just guessin now
    xor d1, d4
    nop
    nop
    exit

