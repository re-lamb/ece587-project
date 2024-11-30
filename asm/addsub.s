#include "isa.asm"
; ALU tests

; test add/sub(i/c/v)
    xor d0, d0              ; d0 = 0
    not d0, d1              ; d1 = -1
    add d0, d0              ; 0 + 0 = 0
    seq #0, d0              ; test
    bf fail                 ; and branch
    
    mov #1, d3             ; d3 = 1               
    add d0, d3              ; 0 + 1 = 1
    seq #1, d3
    bf fail
    
    add d1, d3              ; -1 + 1
    seq #0, d3                           
    bf fail   
                  
    mov d1, d2              ; d2 = -1
    add d0, d2              ; -1 + 0
    seq d1, d2        
    bf fail
    
    ld.w pool, d2           ; d2 = 0x5555
    ld.w pool + 2, d3       ; d3 = 0xaaaa
    add d2, d3              ; d3 = -1   
    seq d1, d3
    bf fail
    
    ld.w pool + 4, d2       ; d2 = 0x4000
    ld.w pool + 4, d3       ; d3 = 0x4000
    ld.w pool + 6, d4       ; d4 = 0x8000 
    add d2, d3              ; d3 = 0x8000
    seq d3, d4
    bf fail
    
    add d4, d4              ; 8000 + 8000 = 0
    seq d0, d4
    bf fail
    
    clrt
    addc  d3, d3            ; 8000 + 8000 = 0 (10000), T = 1
    bf fail
    
    addc d3, d3             ; 0 + 0 + T = 1, T = 0
    bt fail
    seq #1, d3              ; d3 == 1
    bf fail
    
    ld.w pool + 8, d2       ; d2 = 15
    ld.w pool + 10, d3      ; d3 = -8
    mov d2, d4 
    clrt
    addc d3, d2             ; d2 = 7, T = 1
    bf fail
    
    clrt
    mov d4, d2              ; d2 = 15
    addv d3, d2             ; d2 = 7, T = 0
    bt fail
	
	neg d3, d3				; d3 = 8;
	seq #8, d3
	bf fail
    
    nop
    nop
    nop
    exit
    
fail:
    mov #0, d0
    not d0, d0
    exit                    ; exit -1 on fail
    
pool:
#d16 0x5555, 0xaaaa, 0x4000, 0x8000, 15, -8



