/*
 * ECE587 Fall 2024 Final Project
 * R.E. Lamb
 *
 * instruction decoder
 */

#include "defs.h"

Instruction decode(uint16_t value)
{
    Instruction this;

    uint opcode = (value & 0xf000) >> 12;
    uint m = (value >> 8) & 0x7;
    uint n = (value >> 4) & 0x7;
    
    uint funct1 = (value & 0x800);
    uint funct4 = (value & 0x70) >> 4 | (value & 0x800) >> 8;
    uint funct6 = (value & 0x0f) | (value & 0x80) >> 3 | (value & 0x800) >> 6;
    
    this.opcode = opcode;
    this.form = undef;
    this.func = unknown;
    this.type = aluRtype;
    this.rd = m;
    this.rs1 = m;
    this.rs2 = n;
    this.imm = 0;
    this.wbr = false;

    switch (opcode)
    {
        case 0:
            this.form = nr;
            
            switch (funct6)
            {
                case 0:
                    this.func = nop;    // nop
                    break;

                case 1:
                    this.func = clrt;   // clear T flag
                    break;

                case 2:
                    this.func = sett;   // set T flag
                    break;

                case 3:
                    this.func = nott;   // invert T flag
                    break;

                case 4:
                    this.type = branch;
                    this.func = rts;    // return from subroutine
                    this.rs1 = RA;      // a0 = return address
                    break;

                case 5:
                    this.type = branch;
                    this.func = rte;    // return from exception
                    break;

                case 6:
                    this.type = control;
                    this.func = intc;   // disable interrupt
                    break;

                case 7:
                    this.type = control;
                    this.func = ints;   // enable interrupt
                    break;
                    
                case 8:
                    this.type = envcall;
                    this.func = ebreak;
                    break;
                    
                case 9:
                    this.type = envcall;
                    this.func = exitprog;
                    break;
            }
            break;


        case 1:
            this.form = r;
            
            switch (funct6)
            {
                case 0:
                    this.func = movt;   // mov T to Dm
                    this.wbr = true;
                    break;

                case 1:
                    this.func = dt;     // decrement and test Dm
                    this.wbr = true;
                    break;

                case 2:
                    this.func = dt;     // decrement and test Am
                    this.rs1 = AREG(m);
                    this.rd = AREG(m);
                    this.wbr = true;
                    break;

                case 3:
                    this.type = branch;
                    this.func = braf;   // PC + Am branch
                    this.rs1 = AREG(m);
                    break;

                case 4:
                    this.type = branch;
                    this.func = bsrf;   // PC + Am branch subroutine
                    this.rs1 = AREG(m);
                    this.rd = RA;
                    this.wbr = true;
                    break;

                case 5:
                    this.type = branch;
                    this.func = jmp;    // jump to Am
                    this.rs1 = AREG(m);
                    break;

                case 6:
                    this.type = branch;
                    this.func = jsr;    // jump to subroutine Am
                    this.rs1 = AREG(m);
                    this.rd = RA;
                    this.wbr = true;
                    break;

                case 7:
                    this.func = sgz;    // set T if Dm > 0 signed
                    break;
                    
                case 8:
                    this.func = sgzu;   // set T if Dm > 0 unsigned
                    break;
            }  
            break;

        case 2:
            this.form = rr;
            this.wbr = true;

            switch (funct6)
            {
                case 0:                 
                    this.func = mov;    // mov Dn to Dm
                    break;

                case 1:
                    this.func = mov;    // mov Dn to Am
                    this.rd = AREG(m);
                    break;

                case 2:
                    this.func = mov;    // mov An to Am
                    this.rs2 = AREG(n);
                    this.rd = AREG(m);
                    break;

                case 3:
                    this.func = mov;    // mov An to Dm
                    this.rs2 = AREG(n);
                    break;
                    
                case 4:
                    this.type = memOp;
                    this.func = ldb;    // byte mov @(An) to Dm
                    this.rs2 = AREG(n);
                    break;
                    
                case 5: 
                    this.type = memOp;
                    this.func = ldw;    // word mov @(An) to Dm
                    this.rs2 = AREG(n);
                    break;
                    
                // case 6 - ld.l
                    
                case 7:
                    this.type = memOp;
                    this.func = stb;    // byte mov Dn to @(Am)
                    this.rs1 = AREG(m);
                    this.wbr = false;
                    break;
                    
                case 8:
                    this.type = memOp;
                    this.func = stw;    // word mov Dn to @(Am)
                    this.rs1 = AREG(m);
                    this.wbr = false;
                    break;
                
                // case 9 - st.l
                    
                case 10:
                    this.func = add;    // add Dm + Dn
                    break;
                    
                case 11:
                    this.func = addc;   // add Dm + Dn + T, c -> T
                    break;
                    
                case 12:
                    this.func = addv;   // add Dm + Dn, v -> T
                    break;
                    
                case 13:
                    this.func = add;    // adda Am + An
                    this.rs1 = AREG(m);
                    this.rs2 = AREG(n);
                    this.rd = AREG(m);
                    break;
                    
                case 14:
                    this.func = add;    // adda Dm + An
                    this.rs1 = AREG(m);
                    this.rd = AREG(m);
                    break;
                    
                case 15:
                    this.func = sub;    // sub Dm - Dn
                    break;
                    
                case 16:
                    this.func = subc;   // sub Dm - Dn - T, b -> T
                    break;
                    
                case 17:
                    this.func = subv;   // sub Dm - Dn, u -> T
                    break;
                    
                case 18:
                    this.func = sub;    // suba Am - An
                    this.rs1 = AREG(m);
                    this.rs2 = AREG(n);
                    this.rd = AREG(m);
                    break;
                    
                case 19:
                    this.func = sub;    // suba Am - Dn
                    this.rs1 = AREG(m);
                    this.rd = AREG(m);
                    break;
                
                case 20:
                    this.func = and;    // and Dm & Dn
                    break;
                    
                case 21:
                    this.func = tst;    // tst Dm & Dn -> T
                    this.wbr = false;
                    break;
                
                case 22:
                    this.func = neg;    // 0 - Dn to Dm
                    break;
                
                case 23:
                    this.func = negc;   // 0 - Dn - T to Dm
                    break;
                    
                case 24:
                    this.func = not;    // ~Dn to Dm
                    break;
                    
                case 25:
                    this.func = or;     // Dm | Dn to Dm
                    break;
                    
                case 26:
                    this.func = xor;    // Dm ^ Dn to Dm
                    break;
                
                case 27:
                    this.func = seq;    // Dm == Dn -> T
                    this.wbr = false;
                    break;  
                
                case 28:
                    this.func = sge;    // Dn >= Dm signed -> T
                    this.wbr = false;
                    break;
                    
                case 29:
                    this.func = sgeu;   // Dn >= Dm unsigned -> T
                    this.wbr = false;
                    break;
                    
                case 30:
                    this.func = sgt;    // Dn > Dm signed -> T
                    this.wbr = false;
                    break;
                
                case 31:
                    this.func = sgtu;   // Dn > Dm unsigned -> T
                    this.wbr = false;
                    break;
                    
                case 32:
                    this.func = exts;   // Dn sign ext. to Dm
                    break;
                
                // case 33 - exts.w
                
                case 34:
                    this.func = extu;   // Dn zero ext. to Dm
                    break;
                
                // case 35 - extu.w
                
                case 36:
                    this.func = sll;    // Dm << Dn to Dm
                    break;
                    
                case 37:
                    this.func = srl;    // Dm >> Dn to Dm
                    break;
                    
                case 38:
                    this.func = sra;    // Dm >> Dn, sign ext. to Dm
                    break;
                    
                case 39:
                    this.func = rot;    // Dm rotate by Dn to Dm
                    break;
                    
                case 40:
                    this.func = mulb;  
                    break;
                    
                case 41:
                    this.func = mulw;  
                    break;
                
                // case 42: mul.l
                
                case 43:
                    this.func = divb;  
                    break;
                    
                case 44:
                    this.func = divw;  
                    break;
                    
                // case 45: div.l
                
                case 46:
                    this.func = mulub;  
                    break;
                    
                case 47:
                    this.func = muluw;  
                    break;
                    
                // case 48: mulu.l
                
                case 49:
                    this.func = divub;  
                    break;
                    
                case 50:
                    this.func = divuw;  
                    break;
                    
                // case 51: divu.l
                
                case 52:
                    this.func = modb;  
                    break;
                    
                case 53:
                    this.func = modw;  
                    break;
            }
            break;

        case 3:
            this.form = ri5;
            this.type = aluItype;
            this.wbr = true;
            this.imm = (value & 0x0f);
            if (value & SIGNBIT(7)) this.imm |= 0xfff0;
            
            switch (funct4) 
            {
                case 0:
                    this.func = bclr;   // Dm[imm] = 0
                    break;
                
                case 1:
                    this.func = bset;   // Dm[imm] = 1
                    break;
                    
                case 2:
                    this.func = bnot;   // ~Dm[imm]
                    break;
                    
                case 3:
                    this.func = btst;   // Dm[imm] -> T
                    this.wbr = false;
                    break;
                    
                case 4:
                    this.func = sll;    // Dm << imm to Dm
                    break;
                    
                case 5:
                    this.func = srl;    // Dm >> imm to Dm
                    break;
                    
                case 6:
                    this.func = sra;    // Dm << imm sign ext to Dm
                    break;
                    
                case 7:
                    this.func = rot;    // Dm rotated by imm to Dm
                    break;      
            }
            break;
        
        case 4:
            this.form = rri5;
            this.type = memOp;
            this.imm = (value & 0x0f);
            if (value & SIGNBIT(7)) this.imm |= 0xfff0;
            
            if (funct1) {
                this.func = stw;        // store Am to (An + imm)
                this.rs1 = AREG(m);
                this.rs2 = AREG(n);
            } else {
                this.func = ldw;        // ld An + imm to Am
                this.rs2 = AREG(n);
                this.rd = AREG(m);
                this.wbr = true;
            }
            break;
            
        case 5:
        case 6:
            this.form = rri5;
            this.type = memOp;
            this.imm = (value & 0x0f);
            if (value & SIGNBIT(7)) this.imm |= 0xfff0;
            
            if (funct1) {
                this.func = (opcode == 5) ? stb : stw;
                this.rs2 = AREG(n);
            } else {
                this.func = (opcode == 5) ? ldb : ldw;
                this.rs2 = AREG(n);
                this.wbr = true;
            }
            break;
        
        // case 7 - 32-bit ld/st
        
        case 8:
            funct4 = (value & 0x0f00) >> 8;
            
            this.form = i8;
            this.type = aluItype;
            this.rs1 = 0;
            this.rd = 0;
            
            this.wbr = true;
            this.imm =  (value & 0xff);
            int16_t ext = (value & SIGNBIT(7)) ? this.imm |= 0xff00 : this.imm;

            switch (funct4) 
            {
                case 0:
                    this.func = and;    // D0 & imm to D0
                    break;
                
                case 1:
                    this.func = or;     // D0 | imm to D0
                    break;
                    
                case 2:
                    this.func = xor;    // D0 ^ imm to D0
                    break;
                    
                case 3:
                    this.func = tst;    // D0 & imm -> T
                    this.wbr = false;
                    break;
                    
                case 4:
                    this.func = muluw;  // D0 * imm to D0
                    break;
                    
                case 5:
                    this.func = divuw;  // D0 / imm to D0
                    break;
                    
                case 6:
                    this.func = modw;   // D0 % imm to D0
                    break;
                    
                // case 7: rsvd
                
                case 8:
                    this.func = mulw;   // D0 * imm to D0
                    this.imm = ext;
                    break;
                    
                case 9:
                    this.func = divw;   // D0 / imm to D0
                    this.imm = ext;
                    break;
                
                case 10:
                    this.type = branch;
                    this.func = bf;     // branch false
                    this.imm = ext;
                    this.wbr = false;
                    break;
                    
                case 11:
                    this.type = branch;
                    this.func = bt;     // branch true
                    this.imm = ext;
                    this.wbr = false;
                    break;
            }
            break;

        case 9:
            this.form = ri8;
            this.type = memOp;
            this.imm = (value & 0x00ff);
            if (value & SIGNBIT(7)) this.imm |= 0xff00;
            
            if (funct1 == 0) 
            {
                this.func = ldw;        // load pc + imm to Dm
                this.wbr = true;
            }
            break;
        
        case 10:
            this.form = ri8;
            this.type = memOp;
            this.imm = (value & 0x00ff);
            if (value & SIGNBIT(7)) this.imm |= 0xff00;
            
            if (funct1 == 0) 
            {
                this.func = ldw;        // load pc + imm to Am
                this.rd = AREG(m);
                this.wbr = true;
            }
            break;
            
        case 11:
            this.form = ri8;
            this.type = aluItype;
            this.wbr = true;
            this.imm = (value & 0x00ff);
            if (value & SIGNBIT(7)) this.imm |= 0xff00;

            this.func = add;            // add imm + Dm/Am
            if (funct1) this.rd = AREG(m);
            break;
            
        case 12:
            this.form = ri8;
            this.type = aluItype;
            this.imm = (value & 0x00ff);
            
            if (funct1 == 0) 
            {
                this.func = seq;        // set T to (Dm == imm(sign ext.))
                if (value & SIGNBIT(7)) this.imm |= 0xff00;
            }
            else
            {
                this.func = mov;        // imm(zero ext.) to Dm
                this.wbr = true;
            }
            break;
        
        // case 13 - reserved 
        
        case 14:
        case 15:
            this.form = i12;
            this.type = branch;
            this.imm = (value & 0x0fff);
            if (value & SIGNBIT(11)) this.imm |= 0xf000;
            
            if (opcode == 14) 
            {
                this.func = bra;        // branch to PC + imm
            }
            else 
            {
                this.func = bsr;        // branch to PC + imm, PC -> RA
                this.rd = RA;
                this.wbr = true;
            }
            break;

        default:
            fprintf(stderr, "Unimplemented opcode 0x%02X\n", this.form);
            break;
    }
    
    /*
    if (debug)
    {
        printf("    op: 0x%02X  func: %d (%s)", this.form, this.func, instnames[this.func]);
        printf("    rd: %d  rs1: %d  rs2: %d\n", this.rd, this.rs1, this.rs2);
        printf("   imm: %d (0x%04X)  wb: %s\n", this.imm, this.imm, this.wbr ? "t" : "f");
        printf("    f1: 0x%04X  f4: 0x%04X  f6: 0x%04X\n", funct1, funct4, funct6);
     }
     */
     
    if (this.func == unknown)
    {
        fprintf(stderr, "Unknown instruction 0x%04X!\n", value);
        exit(-1);
    }
    
    return this;
}
