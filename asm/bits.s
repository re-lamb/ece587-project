;
; ECE 587 Fall 2024 - Final project
; R.E. Lamb
;
; bits.s
;
; bit flippin tests:
;   bset bclr bnot btst (both reg and imm types)
;
; assumes the following instructions are correct:
;   xor, not, seq, mov, ld.w, bf, bt, dt
;

#include "isa.asm"

    xor d0, d0              ; d0 = 0
    not d0, d1              ; d1 = -1
    mov #1, d2              ; d2 = 1

    ; test basic set, clear, and invert
    bset #0, d0             ; d0 = 1
    seq d0, d2              ; test
    bf fail                 ; and branch

    bclr #0, d0             ; d0 = 0
    seq #0, d0
    bf fail

    bnot #0, d0             ; d0 = 1
    seq d0, d2
    bf fail
    bnot #0, d0             ; d0 = 0
    seq #0, d0
    bf fail

    btst #0, d2             ; true
    bf fail
    btst #0, d0             ; false
    bt fail

    ; check upper range
    ld.w pool, d3           ; 0x8000
    mov d3, d4
    bnot #15, d4            ; d4 = 0
    btst #15, d4
    bt fail

    ld.w pool+2, d4         ; 0x7fff
    bset #15, d4            ; d4 = -1
    seq d1, d4
    bf fail

    ; walk through d4 (0xffff) and clear each bit
    ; uses a register rather than the imm
    mov #15, d5
clrloop:
    bclr d5, d4             ; clear bits 15:1
    dt d5                   ; dec & test counter
    bf clrloop              ; loop if not yet 0

    seq d2, d4              ; should be 1
    bf fail
    bclr d5, d4             ; clear bit 0
    seq d0, d4              ; now test d4 == 0
    bf fail

    ; now reset all the bits in d4, one by one
    mov #15, d5             ; reset counter
setloop:
    bset d5, d4             ; set the next bit in d4
    dt d5                   ; bump the counter
    bf setloop              ; repeat

    bnot #0, d4             ; toggle 0xfffe -> 0xffff
    seq d1, d4
    bf fail

    ; invert a more interesting pattern
    mov #15, d5             ; once more with feeling
    ld.w pool+4, d4         ; 0x5555
    ld.w pool+6, d6         ; 0xaaaa
fliploop:
    bnot d5, d4             ; flip it good
    dt d5
    bf fliploop

    bnot #0, d4             ; catch the last one
    seq d4, d6              ; all bits inverted? 
    bf fail

    nop
    nop
    mov #0, d0              ; exit 0 on pass
    exit

fail:
    mov #0, d0
    not d0, d0
    exit                    ; exit -1 on fail

pool:
#d16 0x8000, 0x7fff, 0x5555, 0xaaaa

