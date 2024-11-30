/*
 * ECE587 Fall 2024 Final Project
 * R.E. Lamb
 *
 * Simulator guts
 */

#include "defs.h"

Statistics stats;

char *regnames[] = {
    "d0", "d1", "d2", "d3", "d4", "d5", "d6", "d7",
    "a0", "a1", "a2", "a3", "a4", "a5", "a6", "a7"
};

char *instnames[] = {
    "nop",      "clrt",     "sett",     "nott",     "rts",      "rte",      "intc",     "ints",
    "movt",     "dt",       "braf",     "bsrf",     "jmp",      "jsr",      "sgz",      "sgzu",
    "mov",      "ld.w",     "ld.b",     "st.w",     "st.b",     "add",      "addc",     "addv",
    "sub",      "subc",     "subv",     "and",      "tst",      "neg",      "negc",     "not",
    "or",       "xor",      "seq",      "sge",      "sgeu",     "sgt",      "sgtu",     "exts",
    "extu",     "sll",      "srl",      "sra",      "rot",      "mul",      "mulu",     "div",
    "divu",     "mod",      "bclr",     "bset",     "bnot",     "btst",     "bf",       "bt",
    "bra",      "bsr",      "ebreak",   "exit",     "unknown"
};

int16_t reg[NUMREGS];
int16_t tbit;

int16_t regread(int r)
{
    if (r >= 0 && r < NUMREGS)
    {
        if (debug) printf("Read: %s = %d (0x%04X)\n", regnames[r], reg[r], (uint16_t)reg[r]);
        return reg[r];
    }
    else
    {
        fprintf(stderr, "Register %d read out of range\n", r);
        exit(-1);
    }
}

void regwrite(int r, int16_t val)
{
    if (r >= 0 && r < NUMREGS)
    {
        reg[r] = val;
        if (debug) printf("Write: %s = %d (0x%04X)\n", regnames[r], reg[r], (uint16_t)reg[r]);
    }
    else
    {
        fprintf(stderr, "Register %d write out of range\n", r);
        exit(-1);
    }
}

uint16_t branchop(uint16_t pc, int16_t rs1, int16_t rs2, Instruction inst)
{
    int16_t nextpc = (int16_t)pc;
    bool taken = true;

    switch (inst.func)
    {
        case braf:                      // pc relative branches
        case bsrf:
            nextpc += rs1;
            stats.brType[uncond]++;
            break;

        case jmp:                       // absolute branches
        case jsr:
            nextpc = rs1;
            stats.brType[uncond]++;
            break;

        case bf:                        // conditional pc relative
            if (!tbit)
            {
                nextpc += (inst.imm << 1);
                stats.brType[condTaken]++;
            }
            else
            {
                nextpc += 2;
                taken = false;
                stats.brType[condNotTaken]++;
            }
            break;

        case bt:
            if (tbit)
            {
                nextpc += (inst.imm << 1);
                stats.brType[condTaken]++;
            }
            else
            {
                nextpc += 2;
                taken = false;
                stats.brType[condNotTaken]++;
            }
            break;

        case bra:                       // unconditional pc relative
        case bsr:
            nextpc += (inst.imm << 1);
            stats.brType[uncond]++;
            break;

        case rts:
            nextpc = rs1 + 2;
            stats.brType[uncond]++;
            break;

        // case rte: - TODO: add exception return

        default:
            fprintf(stderr, "Illegal branch op %d @0x%04X\n", inst.func, pc);
            exit(-1);
            break;
    }

    if (debug) printf("%s %staken: 0x%04X\n", instnames[inst.func], taken ? "" : "not ", nextpc);

    return (uint16_t)nextpc;
}

uint execute(uint16_t pc, Instruction inst)
{
    int16_t rs1 = regread(inst.rs1);
    int16_t rs2 = regread(inst.rs2);
    int16_t result = 0;
    int16_t nextpc = pc + 2;

    stats.count++;

    switch (inst.type)
    {
        case aluRtype:
            result = aluop(rs1, rs2, inst.func);                    // send inst to alu
            if (inst.wbr) regwrite(inst.rd, result);                // wb if necessary
            stats.byType[alu]++;
            break;

        case aluItype:
            result = aluop(rs1, inst.imm, inst.func);               // same for immediate ops
            if (inst.wbr) regwrite(inst.rd, result);
            stats.byType[alu]++;
            break;

        case memOp:

            if (inst.wbr)                                           // if wb, it's a load
            {
                if (inst.opcode == 9 || inst.opcode == 10)          // pc replaces An for pc-rel
                {
                    rs2 = pc;
                }
                regwrite(inst.rd, loadop(rs2, inst.imm, inst.func));
            }
            else                                                    // ..else it's a store
            {
                storeop(rs2, inst.imm, inst.func, rs1);
            }
            stats.byType[lsu]++;
            break;

        case branch:                                                // calculate branch/jump target
            nextpc = branchop(pc, rs1, rs2, inst);

            if (inst.wbr) regwrite(inst.rd, pc);                    // write RA for subroutine calls
            stats.byType[bru]++;
            break;

        case control:
            regwrite(inst.rd, nextpc);
            nextpc = (int)pc + inst.imm;
            stats.byType[pseudo]++;
            break;

        case envcall:
            if (inst.func == ebreak)
            {
                interactive = 1;
                printf("EBREAK @ 0x%04X\n", (uint16_t)pc);
            }
            stats.byType[pseudo]++;
            break;

        default:
            printf("Unimplemented: %s op\n", instnames[inst.func]);
            stats.byType[illegal]++;
            break;
    }

    return (uint16_t)nextpc;
}

void dumpregs()
{
    printf("Registers:");

    for (int i = 0; i < NUMREGS; i++)
    {
        if (i % 4 == 0)
        {
            printf("\n");
        }
        printf("%3s: 0x%04X  ", regnames[i], (uint16_t)reg[i]);
    }

    printf("\n");
}

/* Debugging */
void dumpmem(uint8_t *mem)
{
    uint a;

    printf("Memory dump:\n");
    for (a = 0; a < 0x10; a++)
    {
    /*
        printf("byte u[%08X] = %08X\n", a, memload(mem, a, 1, true));
        printf("byte  [%08X] = %08X\n", a, memload(mem, a, 1, false));
        printf("half u[%08X] = %08X\n", a, memload(mem, a, 2, true));
        printf("half  [%08X] = %08X\n", a, memload(mem, a, 2, false));
        printf("word  [%08X] = %08X\n", a, memload(mem, a, 4, true));
    */
    }
}

void initstats()
{
    int i;

    stats.count = 0;
    for (i = illegal; i <= pseudo; i++) stats.byType[i] = 0;
    for (i = condTaken; i <= uncond; i++) stats.brType[i] = 0;
    if (debug || verbose) fprintf(stderr, "Statistics initialized.\n");
}

#define PCT(x)  (((double)stats.byType[x] / (double)stats.count) * 100.0)

void dumpstats()
{
    // bail if we didn't actually run any instructions!
    if (stats.count == 0) return;

    printf("Statistics:\n");
    printf("  Total instructions executed: %d\n", stats.count);
    printf("\n  Breakdown by instruction type:\n");
    printf("    Illegal: %d\n", stats.byType[illegal]);
    printf("    ALU type:    %d\t%3.03f%%\n", stats.byType[alu], PCT(alu));
    printf("    MulDiv type: %d\t%3.03f%%\n", stats.byType[muldiv], PCT(muldiv));
    printf("    Branch type: %d\t%3.03f%%\n", stats.byType[bru], PCT(bru));
    printf("    Load/Store:  %d\t%3.03f%%\n", stats.byType[lsu], PCT(lsu));
    printf("    Pseudo type: %d\t%3.03f%%\n", stats.byType[pseudo], PCT(pseudo));
    printf("\n  Branch instruction results:\n");
    printf("    Conditional, taken:   %d\tnot taken: %d\n", stats.brType[condTaken], stats.brType[condNotTaken]);
    printf("    Unconditional, taken: %d\n", stats.brType[uncond]);

    // calculate anything else interesting to compare to the OoO version?
}

int run(uint16_t startPC)
{
    char c;
    int done;

    uint16_t pc = startPC;

    initstats();

    printf("Starting simulation @ PC=0x%04X\n", (uint16_t)pc);

    while (1)
    {
        /* Check for misaligned PC */
        if ((pc & 0x1) != 0)
        {
            fprintf(stderr, "Misaligned access @ PC=0x%04X, aborting\n", (uint16_t)pc);
            exit(-1);
        }


        Instruction inst = decode(memload(pc, 2));

        if (verbose || debug)
        {
            printf("\nInstruction @ PC=0x%04X: 0x%04X\n", (uint16_t)pc, (uint16_t)memload(pc, 2));

            if (debug)
            {
                printf("opcode: 0x%02X  func: %d (%s)", inst.opcode, inst.func, instnames[inst.func]);
                printf("    rd: %s  rm: %s  rn: %s\n", regnames[inst.rd], regnames[inst.rs1], regnames[inst.rs2]);
                printf("   imm: %d (0x%04X)  wb: %s\n", inst.imm, (uint16_t)inst.imm, inst.wbr ? "t" : "f");
            }
        }

        if (breakpoint && (breakAddr == pc))
        {
            interactive = 1;
            debug = 1;
            printf("Breakpoint at 0x%04X\n", (uint16_t)pc);
        }

        if (interactive)
        {
            done = 0;

            while (!done)
            {
                printf("\n-- More? c)ontinue, d)isable bkpt, r)egs, q)uit: ");
                fflush(stdout);

                read(STDIN_FILENO, &c, 1);

                switch (c)
                {
                    case '?':
                    case 'h':
                        printf("Help\n");
                        printf("c - continue execution (no stepping)\n");
                        printf("d - disable the breakpoint if set\n");
                        printf("r - dump the current registers\n");
                        printf("q - quit the program immediately\n");
                        printf("\nPress space or enter to step.\n");
                        break;

                    case 'q':
                        printf("Quit\n");
                        inst.func = exitprog;
                        done = 1;
                        break;

                    case ' ':
                    case '\n':
                        printf("\n");
                        done = 1;
                        break;

                    case 'd':
                        breakpoint = 0;
                        printf("\nBreakpoint disabled.\n");
                        break;

                    case 'r':
                        dumpregs();
                        break;

                    case 'c':
                        interactive = 0;
                        printf("\nContinuing...\n");
                        done = 1;
                        break;

                    default:
                        printf("???\n");
                        break;
                }
            }
        }

        if (inst.func == exitprog)
        {
            /* Dump the stats */
            printf("Execution completed @ PC=0x%04X\n", (uint16_t)pc);
            dumpregs();
            dumpstats();
            return (int)reg[0];     // reg d0 contains exit status
        }

        pc = execute(pc, inst);
        if (verbose && !debug) dumpregs();
    }
}
