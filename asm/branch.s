;
; ECE 587 Fall 2024 - Final project
; R.E. Lamb
;
; branch.s
;
; tests:
;   jmp, jsr, bra, braf, bsr, bsrf, rts, bf, bt
;
; assumes the following instructions are correct:
;   xor, not, seq, mov, ld.w, bf, bt
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
; TODO:
;   if the only semantic distinction is whether to use Am as an
;   offset from PC or absolute; could simplify to three forms
;   of each case:
;
;       br a7           -> jmp <areg>
;       br @(a7,PC)     -> braf <areg>
;       br <label>      -> bra <label>
;
;   if bf/bt are the ONLY conditionals, do we have any space to
;   encode other forms?  or do a bsrf/bsrt version?
;
;   it might be helpful to extend "lda" to add
;       lda label           -> use 1101_* for 12-bit offset, implicit to A0?
;                              (or could customasm compute addr of 'label'
;                              and write equiv "lda @((pc-label), pc),a0"?)
;       lda @(disp,An),Am
;       lda @(disp,PC),Am   -> pseudo "lda <areg>" == lda @(0,pc),am ?
;

#include "isa.asm"

    nop
    nop
    xor d0, d0  ; return 0
    exit

; risc-v:
; 
; # test jal/jalr
;     addi t0, zero, -1   # init pass/fail result
;     addi t1, zero, 1
;     addi t2, zero, 3
;     auipc a0, 0         # am i storing the correct pc?
;     jal a1, L0
; L0:
;     addi a0, a0, 8
;     bne a0, a1, fail
;     beq a0, a1, L2      # if predicted pc matched
;     j fail              # do a forward jump
; L1:
;     addi t1, t1, 1      # ..and then return. forwards.
;     jr ra
; L2:
;     addi t1, zero, 2    # now give backwards a go..
;     jal L1
;     bne t1, t2, fail
;  
;     li a3, 2060         # test largest possible negative imm
;     jal a2, L3
; L3:
;     add a2, a2, a3
;     jalr ra, a2, -2048
;     j fail
;     
;     li a3, -2035        # test largest possible positive imm
;     jal a2, L4          # also using a half align immediate!
; L4:
;     add a2, a2, a3
;     jalr ra, a2, 2047
;     j fail
;     
;     li a3, -2034        # test that LSB is discarded after 
;     jal a2, L5          # addition
; L5:
;     add a2, a2, a3
;     jalr ra, a2, 2047
;     j fail
;     
