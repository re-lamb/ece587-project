/*
 * ECE587 Fall 2024 Final Project
 * R.E. Lamb
 *
 * usage: sim [-h] [-dvi] [-b bkpt] [-p pc] [-s stack] [[-f] filename]
 *
 * args:
 *      -h          print usage message
 *      -d          enable debug output
 *      -v          enable verbose output
 *      -i          interactive (single step)
 *      -b          bkpt set a breakpoint
 *      -p pc       set the initial program counter
 *      -f file     read from 'file'
 */

#include "defs.h"
#include <termios.h>

#define MAXLINELEN  60

uint8_t *mem;

// sim flags
int debug = 0;
int verbose = 0;
int interactive = 0;
int breakpoint = 0;

uint16_t breakAddr = 0;

char defmem[] = "program.mem";
char *memfile = NULL;

// for interactive mode
struct termios orig_termios;

// allocate memory to load the program memory input file, bails if it can't.
uint8_t *loadfile(FILE *fp)
{
    char *line;
    char buf[MAXLINELEN];
    char junk[MAXLINELEN];

    uint addr, low, hi, value;
    int lc = 0;

    // allocate the (currently) fixed memory block
    if ((mem = malloc(MEMSZ)) == NULL)
    {
        fprintf(stderr, "could not allocate %d bytes\n", MEMSZ);
        exit(-1);
    }

    // read and parse one line at a time
    while ((line = fgets(buf, MAXLINELEN, fp)) != NULL)
    {
        lc++;
        int len = strlen(line);

        if (sscanf(line, " %s | %x | %x %x ; %s\n", junk, &addr, &hi, &low, junk) != 5)
        {
            // ignore the header line:  "outp | addr | data (base 16)"
            // ignore labels:           "6c:0 |   6c |       ; fail:" (ends in ':')
            // and don't complain about blank lines.
            if (len <= 1 || buf[len - 2] == ':' || strncmp(buf, " outp", 5) == 0) continue;

            // whine about everything else
            fprintf(stderr, "Bad input at line %d ignored: '%s'\n", lc, line);
            continue;
        }

        // make sure the address is in range
        if (addr > MEMSZ-1)
        {
            fprintf(stderr, "Address 0x%X out of range at line %d\n", addr, lc);
            continue;
        }

        // assemble a little endian word
        value = (hi << 8) | low;

        // use the store function to copy into main mem
        memstore(addr, 2, value);
    }

    return mem;
}

// restore the original term settings 
void setcooked() 
{
    tcsetattr(STDIN_FILENO, TCSAFLUSH, &orig_termios);
}

// interactive sets raw mode without echo 
void setraw()
{
    tcgetattr(STDIN_FILENO, &orig_termios);
    atexit(setcooked);

    struct termios raw = orig_termios;
    raw.c_lflag &= ~(ECHO | ICANON);
    tcsetattr(STDIN_FILENO, TCSAFLUSH, &raw);
}


int main(int argc, char *argv[])
{   
    int opt;
    uint16_t pc = 0;

    FILE *file;
    char *memfile = NULL;

    while ((opt = getopt(argc, argv, "hdvib:p:f:")) != -1)
    {
        switch (opt)
        {
            case 'v':
                verbose = 1;
                break;

            case 'd':
                debug = 1;
                break;

            case 'i':
                interactive = 1;
                verbose = 1;
                break;

            case 'b':
                breakpoint = 1;
                breakAddr = (uint16_t)strtol(optarg, NULL, 0);  // auto-detect radix
                break;

            case 'p':
                pc = (uint16_t)strtol(optarg, NULL, 0);         // auto-detect radix
                break;

            case 'f':
                memfile = optarg;
                break;
        
            case 'h':
            default:
                fprintf(stderr, "Usage: sim [-h] [-idv] [-b bkpt] [-p pc] [[-f] filename]\n");
                exit(1);
        }
    }

    // any unparsed options? Assume it's a filename... 
    if (optind < argc)
    {
        memfile = argv[optind];
    }

    // if no file given, read from the default 
    if (memfile == NULL)
    {
        memfile = defmem;
    }
 
    if (debug)
    {
        printf("argc=%d, optind=%d, memfile=%s\n", argc, optind, memfile);
        printf("debug=%d, verbose=%d, interactive=%d, breakpoint=%d (%x)\n",
                debug, verbose, interactive, breakpoint, breakAddr);
        printf("pc=0x%X\n", pc);
    }

    // verify input is readable 
    file = fopen(memfile, "r");
    
    if (!file)
    {
        fprintf(stderr, "Could not open file %s\n", memfile);
        exit(1);
    }
    
    // load it 
    mem = loadfile(file);
    fclose(file);

    // run it 
    setraw();
    int status = run(pc);
    setcooked();
    exit(status);
}