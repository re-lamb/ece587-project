/*
 * ECE587 Fall 2024 Final Project
 * R.E. Lamb
 *
 * ALU functions
 */

#include <limits.h>
#include "defs.h"

int16_t aluop(int16_t a, int16_t b, InstNum func)
{
    int16_t f = 0;
    int16_t oldt = tbit;
    uint utmp;
    int tmp;

    int shamt = (b & 0x0f);     // shift amount - one reserved for 32-bit impl.
    if (debug && (func == sll || func == srl || func == sra || func == rot))
        printf("Shift amt: %d\n", shamt);

    switch (func)
    {
        case nop:
        case mov:
            f = b;
            break;

        case add:
            f = a + b;
            break;

        case addc:
            f = a + b + tbit;
            utmp = (uint16_t)a + (uint16_t)b + tbit;
            tbit = (utmp > USHRT_MAX) ? 1 : 0;
            break;

        case addv:
            f = a + b;
            tmp = a + b;
            tbit = (tmp > SHRT_MAX || tmp < SHRT_MIN) ? 1 : 0;
            break;

        case sub:
            f = a - b;
            break;

        case subc:
            f = a - b - tbit;
            utmp = a - b - tbit;
            tbit = (a < (b + tbit)) ? 1 : 0;
            break;

        case subv:
            f = a - b;
            tmp = a - b;
            tbit = (tmp > a) ? 1 : 0;
            break;

        case and:
            f = a & b;
            break;

        case tst:
            tbit = (a & b) ? 0 : 1;
            break;

        case neg:
            f = 0 - b;
            break;

        case negc:
            f = 0 - b - tbit;
            utmp = 0 - b;
            tbit = (0 < (b + tbit)) ? 1 : 0;
            break;

        case not:
            utmp = ~(uint16_t)b;
            f = utmp;
            break;

        case or:
            f = a | b;
            break;

        case xor:
            f = a ^ b;
            break;

        case seq:
            tbit = (a == b) ? 1 : 0;
            break;

        case sge:
            tbit = (b >= a) ? 1 : 0;
            break;

        case sgeu:
            tbit = ((uint16_t)b >= (uint16_t)a) ? 1 : 0;
            break;

        case sgt:
            tbit = (b > a) ? 1 : 0;
            break;

        case sgtu:
            tbit = ((uint16_t)b > (uint16_t)a) ? 1 : 0;
            break;

        case sgz:
            tbit = (a > 0) ? 1 : 0;
            break;

        case sgzu:
            tbit = ((uint16_t)a > 0) ? 1 : 0;
            break;

        case exts:
            f = (b & 0x80) ? (b | 0xff00) : b;
            break;

        case extu:
            f = b & 0x00ff;
            break;

        case sll:
            f = a << shamt;
            break;

        case srl:
            // coerce to uint16, gcc won't sign extend
            f = (uint16_t)a >> shamt;
            break;

        case sra:
            // gcc sign extends here! (int16_t)a
            f = a >> shamt;
            break;

        case rot:
            // gcc aggressively sign extends if you don't coerce it here
            utmp = ((uint16_t)a << 16) | (uint16_t)a;
            f = (utmp >> shamt) & 0xffff;
            break;

        case bclr:
            f = (a & ~(1 << shamt));
            break;

        case bset:
            f = (a | (1 << shamt));
            break;

        case bnot:
            f = (a & (1 << shamt)) ? (a & ~(1 << shamt)) : (a | (1 << shamt));
            break;

        case btst:
            tbit = (a & (1 << shamt)) ? 1 : 0;
            break;

        case clrt:
            tbit = 0;
            break;

        case sett:
            tbit = 1;
            break;

        case nott:
            tbit = !tbit;
            break;

        case mul:
            f = a * b;
            break;

        case divs:
            if (b == 0)
            {
                // TODO: this will cause an exception later!!
                fprintf(stderr, "DIVIDE BY ZERO\n");
                f = 0;
            }
            else
            {
                f = a / b;
            }
            break;

        case mod:
            if (b == 0)
            {
                // TODO: this will cause an exception later!!
                fprintf(stderr, "MOD BY ZERO\n");
                f = 0;
            }
            else
            {
                f = a % b;
            }
            break;

        case mulu:
            f = (uint16_t)a * (uint16_t)b;
            break;

        case divu:
            if (b == 0)
            {
                // TODO: this will cause an exception later!!
                fprintf(stderr, "DIVIDE BY ZERO\n");
                f = 0;
            }
            else
            {
                f = (uint16_t)a / (uint16_t)b;
            }
            break;

        case dt:
            f = a - 1;
            tbit = (f == 0) ? 1 : 0;
            break;

        default:
            fprintf(stderr, "Bad ALU function: %d\n", func);
    }

    if (debug) {
        printf("ALU: %s %d, %d => %d (0x%04X)  T: %d -> %d\n",
            instnames[func], a, b, f, f, oldt, tbit);
    }
    return f;
}
