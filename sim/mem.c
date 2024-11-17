/*
 * ECE587 Fall 2024 Final Project
 * R.E. Lamb
 *
 * Memory subsystem
 */

#include "defs.h"

int16_t loadop(int16_t addr, int16_t offset, InstNum func)
{
    int16_t ret;

    switch (func)
    {
        case ldb:
            ret = memload(addr + offset, 1);
	    break;

        case ldw:
			offset <<= 1;
            ret = memload(addr + offset, 2);
	    break;

        default:
            fprintf(stderr, "Illegal load op: %d\n", func);
            exit(-1);
            break;
    }

    if (debug) printf("Load:  (0x%04X) => 0x%04X\n", (uint16_t)(addr + offset), (uint16_t)ret);
    return ret;
}

void storeop(int16_t addr, int16_t offset, InstNum func, int16_t value)
{
    switch (func)
    {
        case stb:
            memstore(addr + offset, 1, value);
            break;

        case stw:
			offset <<= 1;
            memstore(addr + offset, 2, value);
            break;
    
        default:
            fprintf(stderr, "Illegal store op: %d\n", func);
            exit(-1);
            break;
    }

    if (debug) printf("Store: 0x%04X => (0x%04X)\n", (uint16_t)value, (uint16_t)(addr + offset));
}

int16_t memload(uint16_t addr, uint8_t size)
{
    int16_t ret;

	// oops this isn't possible - save for 32-bit impl
    if ((addr + size-1) >= MEMSZ)
    {
        fprintf(stderr, "Load from 0x%04X out of range\n", (uint16_t)addr);
        exit(-1);
    }
    
    /* Abuse the compiler instead of shifting and masking */
    switch (size) 
    {
        case 1:
            ret = (uint16_t)mem[addr];
            break;

        case 2:
            ret = *(uint16_t*)&mem[addr];
            break;

        default:
            fprintf(stderr, "Illegal load request (%d bytes) at 0x%04X\n", size, addr);
            exit(-1);
    }
	
	// if (debug) fprintf(stderr, "Load request (%d bytes) at 0x%04X, val 0x%04X\n", size, addr, (uint16_t)ret);
    return (int16_t)ret;
}

void memstore(uint16_t addr, uint8_t size, int16_t value)
{
    if ((addr + size-1) >= MEMSZ)
    {
        fprintf(stderr, "Store to 0x%04X out of range\n", addr);
        exit(-1);
    }

    switch (size) 
    {
        case 1:
            mem[addr] = (uint8_t)value;
            break;

        case 2:
            *(uint16_t*)&mem[addr] = (uint16_t)value;
            break;

        default:
            fprintf(stderr, "Illegal store request (%d bytes) at 0x%04X\n", size, addr);
            exit(-1);
    }
	
	// if (debug) fprintf(stderr, "Store request (%d bytes) at 0x%04X, val 0x%04X\n", size, addr, (uint16_t)value);
}
