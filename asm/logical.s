;
; ECE 587 Fall 2024 - Final project
; R.E. Lamb
;
; logical.s
;
; basic ALU tests:
;   not, and, andi, or, ori, xor, xori, tst, tsti,
;   neg, negc, exts.b, extu.b
;
; assumes the following instructions are correct:
;   seq, mov, ld.w, bf, bt, clrt
;

#include "isa.asm"

    mov #0, d0          ; d0 = 0
    ld.w pool, d1       ; d1 = -1
    mov #1, d2          ; d2 = 1

    and d0, d0          ; 0 & 0 = 0
    tst d0, d0          ; 16-bit test
    bf fail
    tst #0, d0          ; 8-bit test
    bf fail

    and d2, d0          ; 0 & 1 = 0
    tst d2, d0
    bf fail
    tst #0, d0
    bf fail

    and d2, d2          ; 1 & 1 = 1
    seq #1, d2
    bf fail

    and d1, d2          ; -1 & 1 = 1
    seq #1, d2          ; d2 still == 1
    bf fail
    tst d1, d2          ; 16-bit (-1 & 1 == 0)?
    bt fail

    not d0, d3          ; d3 = -1 (ones comp)
    seq d1, d3
    bf fail

    neg d2, d3          ; d3 = -1 (twos comp)
    seq d1, d3
    bf fail

    neg d3, d3          ; d3 = 1 (twos comp)
    seq d2, d3
    bf fail

    negc d1, d3         ; d3 = 0 - (-1) - 1 = 0
    bt fail             ; (t should equal 0)

    negc d1, d3         ; d3 = 0 - (-1) - 0 = 1
    seq d2, d3
    bf fail

    clrt
    negc d2, d3         ; d3 = 0 - 1 - 0 = -1
    seq d1, d3
    bf fail

    ld.w pool+2, d3     ; d3 = 0x5555
    ld.w pool+4, d4     ; d4 = 0xaaaa
    and d3, d4          ; d3 & d4 = 0
    seq d0, d4
    bf fail

    ld.w pool+4, d4     ; d4 = 0xaaaa again
    not d3, d5          ; d5 = 0xaaaa
    seq d5, d4          ; check it
    bf fail

    xor d3, d5          ; d5 = 0x5555 ^ 0xaaaa = -1
    seq d1, d5          ; check it
    bf fail

    xor d3, d5          ; d5 = 0x5555 ^ 0xffff = 0xaaaa
    seq d4, d5          ; again
    bf fail

    or d3, d5           ; set d5 to -1
    seq d1, d5
    bf fail

    ld.w pool+6, d3     ; d3 = 0x8000
    ld.w pool+8, d4     ; d4 = 0x7fff
    mov d4, d5
    or d3, d5           ; d5 = -1
    seq d1, d5
    bf fail

    ; andi/ori/xori are byte ops that zero extend
    ; they use d0 implicitly (but the asm requires showing it?)
    or #0, d0           ; 0 | 0 = 0
    seq #0, d0
    bf fail

    or #1, d0           ; 0 | 1 = 1
    seq #1, d0
    bf fail

    and #1, d0          ; 1 & 1 = 1
    seq #1, d0
    bf fail

    xor #1, d0          ; 0x0001 ^ 0x01 = 0
    seq #0, d0
    bf fail

    xor #1, d0          ; 0x0000 ^ 0x01 = 1
    seq #1, d0
    bf fail

    mov d1, d0          ; d0 = 0xffff
    seq d1, d0          ; check it
    bf fail
    and #0xff, d0       ; 0x00ff & 0xffff = 0x00ff
    tst d1, d0          ; 16-bit tst is not zero
    bt fail
    tst #0xff, d0       ; 8-bit tst is not zero
    bt fail

    not d0, d0          ; d0 = 0xff00
    and #0xff, d0       ; 0x00ff & 0xff00 = 0
    tst d1, d0          ; 16-bit tst is zero, so true
    bf fail
    tst #0xff, d0       ; 8-bit tst is zero, so true
    bf fail

    ; some sign and zero extend tests
    or #0xff, d0        ; d0 = 0x00ff
    not d0, d0          ; d0 = 0xff00
    extu d2, d0         ; zero ext to whack upper byte (d0 = 1)
    seq d2, d0          ; check it
    bf fail

    or #0xff, d0        ; d0 = 0x00ff
    exts d0, d0         ; sign ext to restore upper byte (d0 = -1)
    seq d1, d0
    bf fail

    ; more?

    nop
    nop
    mov #0, d0          ; exit 0 on pass
    exit

fail:
    mov #0, d0
    not d0, d0
    exit                ; exit -1 on fail

pool:
#d16 0xffff, 0x5555, 0xaaaa, 0x8000, 0x7fff

