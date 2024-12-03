;
; ECE 587 Fall 2024 - Final project
; R.E. Lamb
;
; shift.s
;
; tests:
;   sll, srl, sra, rot (reg and imm versions)
;
; assumes the following instructions are correct:
;   xor, not, seq, mov, ld.w, bf, bt, clrt
;

#include "isa.asm"

    clr d0          ; d0 = 0
    not d0, d1      ; d1 = -1
    neg d1, d2      ; d2 = 1

    ; shift left
    ld.w pool, d3   ; d3 = 0x8000
    sll #1, d3      ; make it 0!
    seq d0, d3      ; trust but verify
    bf fail

    ld.w pool+2, d3 ; d3 = 0x5555
    ld.w pool+4, d4 ; d4 = 0xaaaa
    sll #1, d3      ; d3 == d4
    seq d3, d4      ; check it
    bf fail

    ; shift right - logical
    mov d2, d3      ; d3 = 1
    srl #1, d3      ; make it 0!
    seq d0, d3
    bf fail

    ld.w pool+2, d3 ; d3 = 0x5555
    ld.w pool+4, d4 ; d4 = 0xaaaa
    srl #1, d4      ; d4 == d3
    seq d3, d4      ; check it - NO sign ext!
    bf fail

    ; marching bits
    mov d2, d3      ; d3 = 1
    mov d3, d4      ; d4 = 1
    mov #16, d5     ; d5 = loop 16 times
sl_loop:
    sll #1, d3      ; shift it
    add d4, d4      ; do it the old fashioned way
    seq d3, d4      ; make sure they agree
    bf fail
    dt d5           ; bump counter
    bf sl_loop      ; again!

    seq d0, d3      ; should be zero now
    bf fail

    ; right logical
    ld.w pool, d3   ; d3 = 0x8000
    mov d3, d4      ; d4 = 0x8000
    mov #15, d5     ; d5 = loop 15 times
rl_loop:
    srl #1, d3      ; shift it
    sub d3, d4      ; successful srl is a div by 2...
    seq d3, d4      ; sub and make sure they agree
    bf fail
    dt d5           ; bump counter
    bf rl_loop      ; again!

    seq d2, d3      ; should be a 1 now
    bf fail

    ; right arith
    ld.w pool, d1   ; d1 = 0x8000
    ld.w pool+2, d3 ; d3 = 0x5555
    ld.w pool+4, d4 ; d4 = 0xaaaa
    sra d2, d4      ; d4 -> 0xd555
    xor d3, d4      ; d4 -> 0x8000
    seq d1, d4      ; check that it sign extended!
    bf fail

    sra #14, d1     ; sign ext d1 -> 0xfffe
    not d1, d1      ; flip it
    seq d1, d2      ; is it a 1?
    bf fail

    ; rotate
    ; reg form, d2=1 bit, make sure odd rots work
    ld.w pool+2, d3 ; d3 = 0x5555
    ld.w pool+4, d4 ; d4 = 0xaaaa
    mov d4, d5      ; save
    rot d2, d4      ; d4 rot 1 bit -> 0x5555
    seq d3, d4      ; and?
    bf fail
    rot d2, d4      ; d4 rot 1 again -> 0xaaaa!
    seq d5, d4      ; verify
    bf fail

    ; now do some even ones using the imm form
    mov d3, d4      ; set d4 -> 0x5555
    mov #4, d5      ; loop over four nibbles
rot_loop:
    rot #4, d4      ; d4 rotated 4 bits is... d4!
    seq d3, d4      ; check it
    bf fail
    dt d5           ; do it four times
    bf rot_loop

    ; more?

    nop
    nop
    mov #0, d0      ; exit 0 on pass
    exit

pool:
#d16 0x8000, 0x5555, 0xaaaa

fail:
    mov #0, d0
    not d0, d0
    exit            ; exit -1 on fail

