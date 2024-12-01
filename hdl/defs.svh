/*
 * ECE587 Fall 2024 Final Project
 * R.E. Lamb
 *
 * common defs
 *
 */
`default_nettype none

`define FALSE   1'b0
`define TRUE    1'b1

`define XLEN    16
`define ALEN    `XLEN
`define MEMSZ   2 ** `ALEN

`define REGS    16
`define TREGS   16
`define PREGS   32
`define ARW     $clog2(`REGS)
`define PRW     $clog2(`PREGS)
`define TRW     $clog2(`TREGS)

`define ROBSZ   16
`define RBW     $clog2(`REGS)

`define CTL     0
`define ALU     1
`define STQ     2
`define LDQ     3
`define BR      4
`define EXC     5

typedef struct packed
{
  logic valid;
  logic done;
  logic exc;
  logic [`XLEN-1:0] inst;
  logic [1:0] bp_state;
  logic bp_hit;
  logic [`ALEN-1:0] pc;
  logic [`ALEN-1:0] npc;
  logic [`XLEN-1:0] imm;
  logic use_imm;
  logic [`ARW-1:0] rs1;
  logic [`PRW-1:0] p_rs1;
  logic [`ARW-1:0] rs2;
  logic [`PRW-1:0] p_rs2;
  logic [`ARW-1:0] rd;
  logic [`PRW-1:0] p_rd;
  logic [`PRW-1:0] rd_stale;
  logic [`TRW-1:0] t;
  logic [`TRW-1:0] p_t;
  logic [`TRW-1:0] t_stale;
  logic [5:0] func;
  logic [5:0] fu;
  logic [`RBW-1:0] rob_num;
  logic wb;
  logic wbt;
  logic read_rs1;
  logic read_rs2;
  logic read_t;
} Inst_t;

typedef struct packed
{
  logic valid;
  logic [`XLEN-1:0] inst;
  logic [1:0] bp_state;
  logic bp_hit;
  logic [`ALEN-1:0] pc;
  logic [`ALEN-1:0] npc;
} If_id_pkt_t;

typedef struct packed
{
  logic en;
  logic t_en;
  logic exc;
  logic [`RBW-1:0] idx;
  logic [`PRW-1:0] tag;
  logic [`TRW-1:0] t_tag;
} Cdb_pkt_t;

/*
typedef struct packed
{
  logic valid;
  logic [`XLEN-1:0] inst;
  logic [4:0] rd;
  logic [4:0] rd_old;
  logic [4:0] rs1;
  logic [4:0] rs2;
  logic [4:0] rob_num;
  logic [1:0] bp_state;
  logic bp_hit;
  logic [`ALEN-1:0] pc;
  logic [`ALEN-1:0] npc;
} Id_is_pkt_t;
*/

typedef enum logic [4:0] {
  op_add,
  op_sub,
  op_passb,    // movs
  op_and,
  op_not,
  op_or,
  op_xor,
  op_sll,
  op_srl,
  op_sra,
  op_rot,
  op_ext,
  op_mul,
  op_div,
  op_mod,
  op_bclr,
  op_bset,
  op_bnot,
  op_btst
  
} Alu_op_t;

typedef enum logic [15:0] {
  NOP    = 'b0000_0000_0000_0000,
  CLRT   = 'b0000_0000_0000_0001,
  SETT   = 'b0000_0000_0000_0010,
  NOTT   = 'b0000_0000_0000_0011,
  RTS    = 'b0000_0000_0000_0100,
  RTE    = 'b0000_0000_0000_0101,
  INTC   = 'b0000_0000_0000_0110,
  INTS   = 'b0000_0000_0000_0111,
  EBREAK = 'b0000_0000_0000_1000,
  EXIT   = 'b0000_0000_0000_1001,
  
  MOVT   = 'b0001_0???_0000_0000,
  DTD    = 'b0001_0???_0000_0001,
  DTA    = 'b0001_0???_0000_0010,
  BRAF   = 'b0001_0???_0000_0011,
  BSRF   = 'b0001_0???_0000_0100,
  JMP    = 'b0001_0???_0000_0101,
  JSR    = 'b0001_0???_0000_0110,
  SGZ    = 'b0001_0???_0000_0111,
  SGZU   = 'b0001_0???_0000_1000,
      
  MOV    = 'b0010_0???_0???_0000,
  MOVDA  = 'b0010_0???_0???_0001,
  MOVA   = 'b0010_0???_0???_0010,
  MOVAD  = 'b0010_0???_0???_0011,
  LDB    = 'b0010_0???_0???_0100,
  LDW    = 'b0010_0???_0???_0101,
  
  STB    = 'b0010_0???_0???_0111,
  STW    = 'b0010_0???_0???_1000,
        
  ADD    = 'b0010_0???_0???_1010,
  ADDC   = 'b0010_0???_0???_1011,
  ADDV   = 'b0010_0???_0???_1100,
  ADDA   = 'b0010_0???_0???_1101,
  ADDDA  = 'b0010_0???_0???_1110,
  SUB    = 'b0010_0???_0???_1111,
  SUBC   = 'b0010_0???_1???_0000,
  SUBV   = 'b0010_0???_1???_0001,
  SUBA   = 'b0010_0???_1???_0010,
  SUBDA  = 'b0010_0???_1???_0011,
  AND    = 'b0010_0???_1???_0100,
  TST    = 'b0010_0???_1???_0101,
  NEG    = 'b0010_0???_1???_0110,
  NEGC   = 'b0010_0???_1???_0111,
  NOT    = 'b0010_0???_1???_1000,
  OR     = 'b0010_0???_1???_1001,
  XOR    = 'b0010_0???_1???_1010,
  SEQ    = 'b0010_0???_1???_1011,
  SGE    = 'b0010_0???_1???_1100,
  SGEU   = 'b0010_0???_1???_1101,
  SGT    = 'b0010_0???_1???_1110,
  SGTU   = 'b0010_0???_1???_1111,
  EXTSB  = 'b0010_1???_0???_0000,
  EXTUB  = 'b0010_1???_0???_0010,
  SLL    = 'b0010_1???_0???_0100,
  SRL    = 'b0010_1???_0???_0101,
  SRA    = 'b0010_1???_0???_0110,
  ROT    = 'b0010_1???_0???_0111,
  
  MUL    = 'b0010_1???_0???_1001,
  DIV    = 'b0010_1???_0???_1100,
  MOD    = 'b0010_1???_1???_0101,
  
  BCLR   = 'b0010_1???_1???_1000,
  BSET   = 'b0010_1???_1???_1001,
  BNOT   = 'b0010_1???_1???_1010,
  BTST   = 'b0010_1???_1???_1011,
      
  BCLRI  = 'b0011_0???_????_????,
  BSETI  = 'b0011_0???_????_????,
  BNOTI  = 'b0011_0???_????_????,
  BTSTI  = 'b0011_0???_????_????,
  SLLI   = 'b0011_0???_????_????,
  SRLI   = 'b0011_0???_????_????,
  SRAI   = 'b0011_0???_????_????,
  ROTI   = 'b0011_0???_????_????,
    
  LDA    = 'b0100_0???_????_????,
  STA    = 'b0100_1???_????_????,
  LDBD   = 'b0101_0???_????_????,
  STBD   = 'b0101_1???_????_????,
  LDWD   = 'b0110_0???_????_????,
  STWD   = 'b0110_1???_????_????,
  
  ANDI   = 'b1000_0000_????_????,
  ORI    = 'b1000_0001_????_????,
  XORI   = 'b1000_0010_????_????,
  TSTI   = 'b1000_0011_????_????,
  
  MULUI  = 'b1000_0100_????_????,
  DIVUI  = 'b1000_0101_????_????,
  MODI   = 'b1000_0110_????_????,
  MULI   = 'b1000_1000_????_????,
  DIVI   = 'b1000_1001_????_????,
  
  BF     = 'b1000_1010_????_????,
  BT     = 'b1000_1011_????_????,
                              
  LDWP   = 'b1001_0???_????_????,
  LDAP   = 'b1010_0???_????_????,
                      
  ADDI   = 'b1011_0???_????_????,
  ADDIA  = 'b1011_1???_????_????,
  SEQI   = 'b1100_0???_????_????,
  MOVI   = 'b1100_1???_????_????,
                              
  BRA    = 'b1110_????_????_????,
  BSR    = 'b1111_????_????_????
} Instname;