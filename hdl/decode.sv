/*
 * ECE587 Fall 2024 Final Project
 * R.E. Lamb
 *
 * instruction decode unit
 */

module decode(
  input clk,
  input rst,
  input If_id_pkt_t[1:0] if_id_pkt,           // two fetched instructions

  input [1:0] rob_rdy,                        // rob entry available
  input [1:0][3:0] next_rob,                  // rob idx

  input [1:0][3:0] rs_rdy,                    // rs ready bits

  input [1:0] freelist_rdy,                   // free reg available
  input [1:0][4:0] next_free,                 // next free reg mapping

  input [1:0] freelist_t_rdy,                 // per-inst t-bit mapping as well
  input [1:0][3:0] next_free_t,

  input [3:0][4:0] map_rd_data,               // read 4 register mappings
  input [3:0] map_t_rd_data,                  // and t-bit mappings
  
  output [1:0] dec_stall,                     // output stall to ifu

  output [1:0] rob_wr_en,                     // rob entry enable
  output [3:0] rs_en,                         // rs entry enable

  output [1:0] freelist_en,                   // grab names from free list
  output [1:0] freelist_t_en,

  output [1:0] map_wr_en,                     // remap written regs
  output [4:0][1:0] map_wr_data,              // ..with new alias
  output map_t_wr_en,
  output [3:0] map_t_wr_data,

  output [3:0][3:0] map_rd_addr,              // rs1/rs2/rd lookup in map table

  output Inst_t [1:0] issue_pkt
);
  Inst_t [1:0] decode_inst;

  // decode raw instruction
  inst_decoder dec0(if_id_pkt[0].inst, decode_inst[0]);
  inst_decoder dec1(if_id_pkt[1].inst, decode_inst[1]);

  assign map_rd_addr[0] = decode_inst[0].rs1;
  assign map_rd_addr[1] = decode_inst[0].rs2;
  assign map_rd_addr[2] = decode_inst[1].rs1;
  assign map_rd_addr[3] = decode_inst[1].rs2;

  assign dec_stall[0] = (if_id_pkt[0].valid | !rob_rdy[0]         |             // no rob entry
                         issue_pkt[0].wb && !freelist_rdy[0]      |             // no free reg
                         issue_pkt[0].wb_t && !freelist_t_rdy[0]  |             // no free t reg
                         !rs_rdy[0][issue_pkt[0].fu]);                          // no free rs

  assign dec_stall[1] = (dec_stall[0]                             |
                         if_id_pkt[1].valid | !rob_rdy[1]         |
                         issue_pkt[1].wb && !freelist_rdy[1]      |
                         issue_pkt[1].wb_t && !freelist_t_rdy[1]  |
                         !rs_rdy[1][issue_pkt[1].fu]);
                         
  assign rob_wr_en[0] = !dec_stall[0];                                          // add inst to rob
  assign rob_wr_en[1] = !dec_stall[1] && rob_wr_en[0];

  assign rs_en[0] = rob_wr_en[0];                                               // add inst to rs
  assign rs_en[1] = rob_wr_en[0] && rob_wr_en[1];

  assign freelist_en[0] = !stall[0] && issue_pkt[0].wb;                         // take from free list
  assign freelist_en[1] = !(stall[0] | stall[1]) && issue_pkt[1].wb;
  
  assign map_wr_en[0] = freelist_en[0] && !(freelist_en[1] && decode_inst[0].rd == decode_inst[1].rd);   // and remap in map table
  assign map_wr_en[1] = freelist_en[1];

  assign freelist_t_en[0] = !stall[0] && issue_pkt[0].wb_t;                     // repeat for t-bit
  assign freelist_t_en[1] = !(stall[0] | stall[1]) && issue_pkt[1].wb_t;
  assign map_t_wr_en = freelist_t_en[0] | freelist_t_en[1];                     // if either inst remaps t-bit
  assign map_t_wr_data = (freelist_t_en[1]) ? next_free_t[1] : next_free_t[0];  // update only newest mapping

  // for debug i'm saving eeeeeverything, pare down later
  assign issue_pkt[0].valid    = !stall[0];                                     // and we're off!
  assign issue_pkt[0].done     = (decode_inst[0].fu == `CTL || decode_inst[0].fu == `EXC) ? 
                                  `TRUE : `FALSE;                               // control instructions have no exec stage
  assign issue_pkt[0].pc       = if_id_pkt[0].pc;                               // instruction PC
  assign issue_pkt[0].npc      = if_id_pkt[0].npc;                              // next PC
  assign issue_pkt[0].bp_state = if_id_pkt[0].bp_state;                         // branch counter val
  assign issue_pkt[0].bp_hit   = if_id_pkt[0].bp_hit;                           // hit in bp
  assign issue_pkt[0].func     = decode_inst[0].func;                           // operation
  assign issue_pkt[0].fu       = decode_inst[0].fu;                             // functional unit
  assign issue_pkt[0].rs1      = decode_inst[0].rs1;                            // a_rs1
  assign issue_pkt[0].rs2      = decode_inst[0].rs2;                            // a_rs2
  assign issue_pkt[0].rd       = decode_inst[0].rd;                             // a_rd
  assign issue_pkt[0].imm      = decode_inst[0].imm;                            // immediate
  assign issue_pkt[0].use_imm  = decode_inst[0].use_imm;                        // i-type
  assign issue_pkt[0].wb       = decode_inst[0].wb;                             // writeback flag
  assign issue_pkt[0].wb_t     = decode_inst[0].wb_t;                           // writeback t flag
  assign issue_pkt[0].read_rs1 = decode_inst[0].read_rs1;                       // read rs1
  assign issue_pkt[0].read_rs2 = decode_inst[0].read_rs2;                       // read rs2
  assign issue_pkt[0].read_t   = decode_inst[0].read_t;                         // read t
  assign issue_pkt[0].rob_num  = next_rob[0];                                   // rob entry number
  assign issue_pkt[0].p_rs1    = map_rd_data[0];                                // p_rs1
  assign issue_pkt[0].p_rs2    = map_rd_data[1];                                // p_rs2
  assign issue_pkt[0].p_rd     = next_free[0];                                  // p_rd
  assign issue_pkt[0].rd_stale = map_rd_data[0];                                // unmap name
  assign issue_pkt[0].t        = map_t_rd_data;                                 // t mapping for read
  assign issue_pkt[0].p_t      = next_free_t[0];                                // t mapping for write
  assign issue_pkt[0].t_stale  = map_t_rd_data;                                 // t unmap name

  assign issue_pkt[1].valid    = !stall[1];
  assign issue_pkt[1].done     = (decode_inst[1].fu == `CTL || decode_inst[1].fu == `EXC)) ? 
                                 `TRUE : `FALSE;
  assign issue_pkt[1].pc       = if_id_pkt[1].pc;
  assign issue_pkt[1].npc      = if_id_pkt[1].npc;
  assign issue_pkt[1].func     = decode_inst[1].func;
  assign issue_pkt[1].fu       = decode_inst[1].fu;
  assign issue_pkt[1].bp_state = if_id_pkt[1].bp_state;
  assign issue_pkt[1].bp_hit   = if_id_pkt[1].bp_hit;
  assign issue_pkt[1].rs1      = decode_inst[1].rs1;
  assign issue_pkt[1].rs2      = decode_inst[1].rs2;
  assign issue_pkt[1].rd       = decode_inst[1].rd;
  assign issue_pkt[1].imm      = decode_inst[1].imm;
  assign issue_pkt[1].use_imm  = decode_inst[1].use_imm;
  assign issue_pkt[1].wb       = decode_inst[1].wb;
  assign issue_pkt[1].wb_t     = decode_inst[1].wb_t;
  assign issue_pkt[1].read_rs1 = decode_inst[1].read_rs1;
  assign issue_pkt[1].read_rs2 = decode_inst[1].read_rs2;
  assign issue_pkt[1].read_t   = decode_inst[1].read_t;
  assign issue_pkt[1].rob_num  = next_rob[1];
  assign issue_pkt[1].p_rs1    = ((issue_pkt[0].rs1 == issue_pkt[1].rs1) && issue_pkt[0].wb) ? next_free[0] : map_rd_data[2];
  assign issue_pkt[1].p_rs2    = ((issue_pkt[0].rs1 == issue_pkt[1].rs2) && issue_pkt[0].wb) ? next_free[0] : map_rd_data[3];
  assign issue_pkt[1].p_rd     = next_free[1];
  assign issue_pkt[1].rd_stale = ((issue_pkt[0].rs1 == issue_pkt[1].rs1) && issue_pkt[0].wb) ? next_free[0] : map_rd_data[2];
  assign issue_pkt[1].t        = (issue_pkt[0].wb_t) ? next_free_t[0] : map_t_rd_data;    // pick up newest mapping
  assign issue_pkt[1].p_t      = next_free_t[1];
  assign issue_pkt[1].t_stale  = (issue_pkt[0].wb_t) ? next_free_t[0] : map_t_rd_data;    // pick up newest stale

endmodule

module inst_decoder(
  input [`XLEN-1:0] inst_i,
  output Inst_t inst_o
);

  always_comb begin
    inst_o = '0;
    
    // rs1
    case (inst_i) inside
      DTA, BRAF, BSRF, JMP, JSR, STB, STW, ADDA, ADDDA, SUBA, SUBDA, STWD:
        inst_o.rs1 = inst_i[10:8] + 8;        // rs1 = AREG

      ANDI, ORI, XORI, TSTI, MULUI, DIVUI, MODI, MULI, DIVI, BF, BT:
        inst_o.rs1 = '0;                      // rs1 = D0

      RTS:
        inst_o.rs1 = 'h8;                     // rs1 = A0
        
      default:
        inst_o.rs1 = inst_i[10:8];
    endcase

    // rs2
    case (inst_i) inside
      MOVA, MOVAD, LDB, LDW, ADDA, SUBA, STA, LDA, STBD, STWD, LDBD, LDWD:
        inst_o.rs2 = inst_i[6:4] + 8;         // rs2 = AREG

      default:
        inst_o.rs2 = inst_i[6:4];
    endcase

    // rd
    case (inst_i) inside
      DTA, MOVDA, MOVA, ADDA, ADDDA, SUBA, SUBDA, LDA, LDWP, ADDIA:
        inst_o.rd = inst_i[10:8] + 8;         // rd = AREG

      ANDI, ORI, XORI, TSTI, MULUI, DIVUI, MODI, MULI, DIVI:
        inst_o.rd = 0;                        // rd = D0

      BSRF, JSR, BSR:
        inst_o.rd = 8;                        // rd = RA

      default:
        inst_o.rd = inst_i[10:8];
    endcase

    // imm
    case (inst_i[15:12]) inside
      'b0011, 
      'b01??: begin
        inst_o.imm = {{12{inst_i[7]}}, inst_i[3:0]};    // 5-bit sign-extended
      end  
      'b1000: begin                                     // bf/bt sign-extend
        inst_o.imm = (inst_i == BF | inst_i == BT) ? {{9{inst_i[7]}}, inst_i[6:0]} : {8'b0, inst_i[7:0]} ;
      end
      'b1001, 'b1010, 'b1011,
      'b1100: begin
        inst_o.imm = {{9{inst_i[7]}}, inst_i[6:0]};     // 8-bit sign-extended
      end  
      'b111?: begin
      	inst_o.imm = {{5{inst_i[11]}}, inst_i[10:0]};   // 12-bit sign-extended
      end
      default:
        inst_o.imm = '0;
    endcase
    
    // use_imm
    case (inst_i) inside
      BCLRI, BSETI, BNOTI, BTSTI, SLLI, SRLI, SRAI, ROTI, ANDI, ORI, XORI, TSTI, MULUI, DIVUI, MODI, 
      MULI, DIVI, ADDI, ADDIA, SEQI, MOVI:
        inst_o.use_imm = 1;
      default:
        inst_o.use_imm = 0;
    endcase
    
    // read_rs1
    case (inst_i) inside
      DTD, DTA, BRAF, BSRF, JMP, JSR, SGZ, SGZU, STB, STW, ADD, ADDC, ADDV, ADDA, ADDDA, SUB,
      SUBC, SUBV, SUBA, SUBDA, AND, TST, OR, XOR, SEQ, SGE, SGEU, SGT, SGTU, SLL, SRL, SRA, ROT, 
      MUL, DIV, MOD, BCLR, BSET, BNOT, BTST, BCLRI, BSETI, BNOTI, BTSTI, SLLI, SRLI, SRAI, ROTI, 
      STA, STBD, STWD, ANDI, ORI, XORI, ADDI, ADDIA, SEQI:
        inst_o.read_rs1 = 1;
        
      default: 
        inst_o.read_rs1 = 0;
    endcase
    
    //read_rs2
    case (inst_i) inside
      MOV, MOVDA, MOVA, MOVAD, LDB, LDW, STB, STW, ADD, ADDC, ADDV, ADDA, ADDDA, SUB,
      SUBC, SUBV, SUBA, SUBDA, AND, TST, NEG, NEGC, NOT, OR, XOR, SEQ, SGE, SGEU, SGT, SGTU,
      EXTSB, EXTUB, SLL, SRL, SRA, ROT, MUL, DIV, MOD, BCLR, BSET, BNOT, BTST, LDA, STA, LDBD, 
      STBD, LDWD, STWD:
        inst_o.read_rs2 = 1;
        
      default: 
        inst_o.read_rs2 = 0;
    endcase
    
    // wb
    case (inst_i) inside
      MOVT, DTD, DTA, BSRF, JSR, MOV, MOVDA, MOVA, MOVAD, LDB, LDW, ADD, ADDC, ADDV, ADDA, ADDDA, 
      SUB, SUBC, SUBV, SUBA, SUBDA, AND, NEG, NEGC, NOT, OR, XOR, EXTSB, EXTUB, SLL, SRL, SRA, ROT, 
      MUL, DIV, MOD, BCLR, BSET, BNOT, BCLRI, BSETI, BNOTI, SLLI, SRLI, SRAI, ROTI, LDA, LDBD, LDWD, 
      ANDI, ORI, XORI, MULUI, DIVUI, MODI, MULI, DIVI, LDWP, LDAP, ADDI, ADDIA, MOVI, BSR:
        inst_o.wb = 1;
        
      default:
        inst_o.wb = 0;
    endcase
    
    // read_t
    case (inst_i) inside
      NOTT, MOVT, ADDC, SUBC, NEGC, BF, BT:
        inst_o.read_t = 1;
        
      default:
        inst_o.read_t = 0;
    endcase
    
    // wb_t
    case (inst_i) inside
      CLRT, SETT, NOTT, DTD, DTA, SGZ, SGZU, ADDC, ADDV, SUBC, SUBV, TST, NEGC, SEQ, SGE, SGEU, 
      SGT, SGTU, BTST, BTSTI, TSTI, SEQI:
        inst_o.wb_t = 1;
        
      default:
        inst_o.wb_t = 0;
    endcase
    
    // fu
    case (inst_i) inside
      CLRT, SETT, NOTT, MOVT, DTD, DTA, SGZ, SGZU, MOV, MOVDA, MOVA, MOVAD, ADD, ADDC, ADDV, 
      ADDA, ADDDA, SUB, SUBC, SUBV, SUBA, SUBDA, AND, TST, NEG, NEGC, NOT, OR, XOR, SEQ, SGE,   
      SGEU, SGT, SGTU, EXTSB, EXTUB, SLL, SRL, SRA, ROT, BCLR, BSET, BNOT, BTST, BCLRI, BSETI, 
      BNOTI, BTSTI, SLLI, SRLI, SRAI, ROTI, ADDI, ADDIA, SEQI, MOVI, ANDI, ORI, XORI, TSTI: 
        inst_o.fu = `ALU;
      
      MUL, DIV, MOD, MULUI, DIVUI, MODI, MULI, DIVI:
        inst_o.fu = `ALU;

      NOP, RTS, RTE, INTC, INTS, EBREAK, EXIT:
        inst_o.fu = `CTL;
        
      BRAF, BSRF, JMP, JSR, BF, BT, BRA, BSR:     
        inst_o.fu = `BR;
        
      LDB, LDW, LDA, LDBD, LDWD, LDWP, LDAP:
        inst_o.fu = `LDQ;
        
      STB, STW, STA, STBD, STWD:
        inst_o.fu = `STQ;
        
      default:
        inst_o.fu = `EXC;
    endcase
  end

endmodule

module decode_tb();
  logic [15:0] raw_inst;
  Inst_t dec_inst;
  
  inst_decoder DUT(
    .inst_i(raw_inst),
    .inst_o(dec_inst)
  );
    
  initial begin
    raw_inst = 'hc3fe;
    
    #1 $display("%p", dec_inst);
  end
endmodule