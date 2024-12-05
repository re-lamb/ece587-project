;
; ECE 587 Fall 2024 - Final project
; R.E. Lamb
;
; branch.s
;
; tests:
;   bf, bt, br, bsr, jmp, jsr, rts
;
; assumes the following instructions are correct:
;   xor, not, seq, mov, lda, ld.w
;
; note: if bf, bt don't work, NONE of the tests work...
;
; jmp     Am              Am -> PC
; jsr     Am              PC -> A0, Am -> PC
;   jmp/jsr are unconditional branches to an absolute addr
;
; braf    Am              Am + PC -> PC
; bsrf    Am              PC -> A0, Am + PC -> PC
;   braf/bsrf are unconditional branches using a register offset
;
; bra     label           disp*2 + PC -> PC
; bsr     label           PC -> A0, disp*2 + PC -> PC
;   bra/bsr are unconditional branches using an imm offset
;

#include "isa.asm"

    ; d7 will contain a test # on exit
    clr d7              ; clear it
    clr d0

    ; a2 is the absolute addr of fail: for error jumps
    lda pool, a2

    ; check conditional bt
    sett                ; set T
    bt L0               ; branch true

    movt d7             ; save t into d1
    clr d0
    not d0, d0          ; return -1
    exit

L0:
    ; check conditional bf
    clrt                ; clear T
    bf L1

    movt d7             ; save t into d1
    clr d0
    not d0, d0          ; return -1
    exit

L1:
    ; try a branch
    mov #2, d1          ; save test # into d1
    sett                ; set T flag
    br L2
    bt fail             ; nope

L2:
    ; try a branch to subroutine
    mov #3, d1          ; save test # into d1
    sett                ; set T flag
    bsr T1
    bt fail             ; should be clear

    ; try a jump (abs)
    mov #4, d7          ; jump/ret succeeded
    lda pool+4, a1      ; load target T0's absolute addr
    sett                ; set T flag
    bsr L3              ; hack to get PC into A0
L3:
    add #4, a0          ; ** offset return addr **
    jmp a1              ; go!
    bt fail             ; should return here with T clear

    ; jsr should do the same thing with less ugliness
    mov #5, d7          ; set test #
    mova d0, a0         ; clear return addr
    lda pool+4, a1      ; addr of T0 subroutine
    sett
    jsr a1
    bt fail             ; check it

    ; more... 

    nop
    nop
    xor d0, d0          ; return 0
    exit

pool:
#d16 240, 250, 2000

#addr 240
fail:
    clr d0
    not d0, d0          ; return -1
    exit

#addr 246
    mov #0x5a, d7       ; guard for short jumps
    mov #0x55, d7       ; guard for short jumps
#addr 250
T0:
    clrt                ; clear T
    rts                 ; return to a0+2

    mov #0xa0, d7       ; guard for long jumps
    mov #0xa5, d7       ; guard for long jumps

#addr 1996
    mov #0x7a, d7       ; guard for short jumps
    mov #0x75, d7       ; guard for short jumps
#addr 2000
T1:
    clrt                ; clear T
    rts

    mov #0xaa, d7       ; guard for long jumps
    mov #0xaf, d7       ; guard for long jumps

#addr 2044
    ; prevent runaways?
    exit

