#include "Vsim.h"
#include <stdio.h>

int main (int argc, char **argv, char **env)
{
    Verilated::commandArgs(argc, argv);
    Vsim* top = new Vsim;
    
    top->a = 1;
    top->b = 2;
    top->eval();
    printf("res = %d\n", top->f);
    
    delete top;
    exit(EXIT_SUCCESS);
}
