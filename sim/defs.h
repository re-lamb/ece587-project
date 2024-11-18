/*
 * ECE587 Fall 2024 Final Project
 * R.E. Lamb
 *
 * Global definitions
 */

#ifndef _DEFS_
#define _DEFS_

#include <stdio.h>
#include <stdint.h>
#include <stdlib.h>
#include <string.h>
#include <stdbool.h>
#include <unistd.h>

#define MEMSZ       0x10000
#define NUMREGS     16

#define XLEN        16
#define SIGNBIT(x)  (1 << (x))  
#define AREG(x)     (x + 8)

#define RA          8

typedef enum opform
{
    nr, r, rr, ri5, ri8, rri5, i5, i8, i12, undef
} OpFormat;

typedef enum optype
{
    control, aluRtype, aluItype, memOp, branch, envcall
} OpType;

typedef enum instnum
{
    nop,    clrt,   sett,   nott,   rts,    rte,    intc,   ints,
    movt,   dt,     braf,   bsrf,   jmp,    jsr,    sgz,    sgzu,
    mov,    ldb,    ldw,    stb,    stw,    add,    addc,   addv,
    sub,    subc,   subv,   and,    tst,    neg,    negc,   not,
    or,     xor,    seq,    sge,    sgeu,   sgt,    sgtu,   exts,
    extu,   sll,    srl,    sra,    rot,    bclr,   bset,   bnot,
    btst,   bf,     bt,     bra,    bsr,    ebreak, exitprog,   
    unknown
} InstNum;

typedef struct decodedInst
{
    uint opcode;
    OpFormat form;
    InstNum func;
    OpType type;
    int rd;
    int rs1;
    int rs2;
    short imm;
    bool wbr;
} Instruction;

extern int debug;
extern int verbose;
extern int breakpoint;
extern int interactive;
extern uint16_t breakAddr;
extern uint8_t *mem;
extern char *instnames[];
extern char *regnames[];
extern int16_t tbit;

int16_t memload(uint16_t addr, uint8_t size);
void memstore(uint16_t addr, uint8_t size, int16_t value);
Instruction decode(uint16_t value);
int run(uint16_t startPC);

int16_t regread(int r);
void regwrite(int r, int16_t val);
void dumpregs();

int16_t aluop(int16_t a, int16_t b, InstNum func);
int16_t loadop(int16_t addr, int16_t offset, InstNum func);
void storeop(int16_t addr, int16_t offset, InstNum func, int16_t value);
int envop(Instruction inst);

#endif