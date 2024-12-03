;
; ECE 587 Fall 2024 - Final project
; R.E. Lamb
;
; cond.s
;
; simple conditional tests:
;   sgz, sgzu, sge, sgeu, sgt, sgtu   
;
; assumes the following instructions are correct:
;   xor, not, neg, mov, bf, bt
;

#include "isa.asm"

    xor d0, d0      ; d0 = 0
    not d0, d1      ; d1 = -1
    neg d1, d2      ; d2 = 1

; sgz, sgzu - set greater than zero
    sgz d0          ; false
    bt fail
    sgzu d0         ; false for an unsigned zero too :-)
    bt fail

    sgz d1          ; nope
    bt fail
    sgzu d1         ; 0xffff unsigned
    bf fail

    sgz d2          ; true for both
    bf fail
    sgzu d2
    bf fail

; seq - equality (rr)
    seq d0, d0      ; anything with itself = true
    bf fail
    seq d1, d1      ; sign doesn't matter
    bf fail
    seq d2, d2
    bf fail

    seq d0, d1      ; nope
    bt fail
    seq d0, d2
    bt fail
    seq d1, d2
    bt fail

; sge, sgeu - greater than or equal (rr)
    sge d0, d0      ; 0 >= 0 -> t
    bf fail
    sge d1, d0      ; -1 >= 0 -> f
    bt fail
    sge d0, d1      ; 0 >= -1 -> t
    bf fail
    sge d1, d2      ; -1 >= 1 -> f
    bt fail
    sge d2, d1      ; 1 >= -1 -> t
    bf fail

    sgeu d0, d0     ; 0 >= 0 (unsigned) -> t
    bf fail
    sgeu d1, d0     ; -1 >= 0 (unsigned) -> t
    bf fail
    sgeu d0, d1     ; 0 >= -1 (unsigned) -> f
    bt fail
    sgeu d1, d2     ; -1 >= 1 (unsigned) -> t
    bf fail
    sgeu d2, d1     ; 1 >= -1 (unsigned) -> f
    bt fail

; sgt, sgtu - greater than (rr)
    sgt d0, d0      ; 0 > 0 -> f
    bt fail
    sgt d1, d0      ; -1 > 0 -> f
    bt fail
    sgt d0, d1      ; 0 > -1 -> t
    bf fail
    sgt d1, d2      ; -1 > 1 -> f
    bt fail
    sgt d2, d1      ; 1 > -1 -> t
    bf fail

    sgtu d0, d0     ; 0 > 0 (unsigned) -> f
    bt fail
    sgtu d1, d0     ; -1 > 0 (unsigned) -> t
    bf fail
    sgtu d0, d1     ; 0 > -1 (unsigned) -> f
    bt fail
    sgtu d1, d2     ; -1 > 1 (unsigned) -> t
    bf fail
    sgtu d2, d1     ; 1 > -1 (unsigned) -> f
    bt fail

    nop
    nop
    exit

fail:
    mov #0, d0
    not d0, d0
    exit            ; exit -1 on fail

