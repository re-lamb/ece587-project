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
  
  input [3:0] rs_rdy,						              // rs ready bits
  
  input [1:0] freelist_rdy,                   // free reg available
  input [1:0][4:0] next_free,                 // next free reg mapping
  
  input [1:0] freelist_t_rdy,                 // per-inst t-bit mapping as well
  input [1:0][3:0] next_free_t,
  
  input [3:0][4:0] map_rd_data,               // read 4 register mappings
  input [3:0] map_t_rd_data,                  // and t-bit mappings
  
  output [1:0] rob_wr_en,                     // rob entry enable
  output [3:0] rs_en,						              // rs entry enable
  
  output [1:0] freelist_en,                   // grab names from free list
  output [1:0] freelist_t_en,                 
  
  output [1:0] map_wr_en,                     // remap written regs
  output [4:0][1:0] map_wr_data,              // ..with new alias
  
  output map_t_wr_en,
  output [3:0] map_t_wr_data,
  
  output [3:0][3:0] map_rd_addr               // rs1/rs2/rd lookup in map table
  
  // output rs packet
  // output rob packet 
);
  Inst_t [1:0] inst, decode_inst;
  logic [1:0] stall;
  
  // decode raw instruction
  inst_decoder dec0(if_id_pkt[0].inst, decode_inst[0]);
  inst_decoder dec1(if_id_pkt[1].inst, decode_inst[1]);
  
  assign map_rd_addr[0] = decode_inst[0].rs1;
  assign map_rd_addr[1] = decode_inst[0].rs2;
  assign map_rd_addr[2] = decode_inst[1].rs1;
  assign map_rd_addr[3] = decode_inst[1].rs2;
  
  assign stall[0] = (!inst[0].valid | !rob_rdy[0]       |                       // no rob space
                     inst[0].wb && !freelist_rdy[0]     |                       // no free reg
                     inst[0].wb_t && !freelist_t_rdy[0] |                       // no free t reg
                     !rs_rdy[inst[0].fu]);                                      // no free rs
  
  assign stall[1] = (stall[0]                           |
                     !inst[1].valid | !rob_rdy[1]       |
                     inst[1].wb && !freelist_rdy[1]     |
                     inst[1].wb_t && !freelist_t_rdy[1] |
                     !rs_rdy[inst[1].fu]);
  
  assign rob_wr_en[0] = !stall[0];                                              // add inst to rob
  assign rob_wr_en[1] = !stall[1] && rob_wr_en[0]; 
  
  assign rs_en[0] = rob_wr_en[0];                                               // add inst to rs
  assign rs_en[1] = rob_wr_en[0] && rob_wr_en[1];                               // TODO: inst's that dont need rs?
  
  assign freelist_en[0] = !stall[0] && inst[0].wb;                              // take from free list
  assign freelist_en[1] = !(stall[0] | stall[1]) && inst[1].wb;
  
  assign map_wr_en[0] = freelist_en[0];                                         // and remap in map table
  assign map_wr_en[1] = freelist_en[1];
  
  assign freelist_t_en[0] = !stall[0] && inst[0].wb_t;
  assign freelist_t_en[1] = !(stall[0] | stall[1]) && inst[1].wb_t;
  
  assign map_t_wr_en = freelist_t_en[0] | freelist_t_en[1];                     // if either inst remaps t-bit
  assign map_t_wr_data = (freelist_t_en[1]) ? next_free_t[1] : next_free_t[0];  // update only newest mapping
  
   // for debug i'm saving eeeeeverything
  assign inst[0].rs1      = decode_inst[0].rs1;                                 // a_rs1
  assign inst[0].rs2      = decode_inst[0].rs2;                                 // a_rs2
  assign inst[0].rd       = decode_inst[0].rd;                                  // a_rd
  assign inst[0].imm      = decode_inst[0].imm;                                 // immediate
  assign inst[0].wb       = decode_inst[0].wb;                                  // writeback flag
  assign inst[0].wb_t     = decode_inst[0].wb_t;                                // writeback t flag
  assign inst[0].read_rs1 = decode_inst[0].read_rs1;                            // read rs1
  assign inst[0].read_rs2 = decode_inst[0].read_rs2;                            // read rs2
  assign inst[0].read_t   = decode_inst[0].read_t;                              // read t
  assign inst[0].bp_state = if_id_pkt[0].bp_state;                              // branch counter val
  assign inst[0].bp_hit   = if_id_pkt[0].bp_hit;                                // hit in bp
  assign inst[0].pc       = if_id_pkt[0].pc;                                    // instruction PC
  assign inst[0].npc      = if_id_pkt[0].npc;                                   // next PC
  assign inst[0].rob_num  = next_rob[0];                                        // rob entry number
  assign inst[0].p_rs1    = map_rd_data[0];                                     // p_rs1                                 
  assign inst[0].p_rs2    = map_rd_data[1];                                     // p_rs2                              
  assign inst[0].p_rd     = next_free[0];                                       // p_rd
  assign inst[0].rd_stale = map_rd_data[0];                                     // unmap name
  assign inst[0].t        = map_t_rd_data;                                      // t mapping for read
  assign inst[0].p_t      = next_free_t[0];                                     // t mapping for write
  assign inst[0].t_stale  = map_t_rd_data;                                      // t unmap name
  
  assign inst[1].rs1      = decode_inst[1].rs1;             
  assign inst[1].rs2      = decode_inst[1].rs2;             
  assign inst[1].rd       = decode_inst[1].rd;              
  assign inst[1].imm      = decode_inst[1].imm;             
  assign inst[1].wb       = decode_inst[1].wb;              
  assign inst[1].wb_t     = decode_inst[1].wb_t;            
  assign inst[1].read_rs1 = decode_inst[1].read_rs1;        
  assign inst[1].read_rs2 = decode_inst[1].read_rs2;        
  assign inst[1].read_t   = decode_inst[1].read_t;          
  assign inst[1].bp_state = if_id_pkt[1].bp_state;          
  assign inst[1].bp_hit   = if_id_pkt[1].bp_hit;            
  assign inst[1].pc       = if_id_pkt[1].pc;                
  assign inst[1].npc      = if_id_pkt[1].npc;               
  assign inst[1].rob_num  = next_rob[1];              
  assign inst[1].p_rs1    = ((inst[0].rs1 == inst[1].rs1) && inst[0].wb) ? next_free[0] : map_rd_data[2];                                       
  assign inst[1].p_rs2    = ((inst[0].rs1 == inst[1].rs2) && inst[0].wb) ? next_free[0] : map_rd_data[3];                                       
  assign inst[1].p_rd     = next_free[1]; 
  assign inst[1].rd_stale = ((inst[0].rs1 == inst[1].rs1) && inst[0].wb) ? next_free[0] : map_rd_data[2]; 
  assign inst[1].t        = (inst[0].wb_t) ? next_free_t[0] : map_t_rd_data;    // pick up newest mapping
  assign inst[1].p_t      = next_free_t[1];                                          
  assign inst[1].t_stale  = (inst[0].wb_t) ? next_free_t[0] : map_t_rd_data;    // pick up newest stale
  
endmodule

module inst_decoder(
  input [15:0] inst_i,
  output Inst_t inst_o 
);

  always_comb begin
    inst_o = '0;
    
    // rs1
    case (inst_i) inside
      DTA, BRAF, BSRF, JMP, JSR, STB, STW, ADDA, ADDDA, SUBA, SUBDA,
      STWD:
        inst_o.rs1 = inst_i[10:8] + 8;        // rs1 = AREG

      ANDI, ORI, XORI, TSTI, MULUI, DIVUI, MODI, MULI, DIVI, BF,
      BT:
        inst_o.rs1 = '0;                      // rs1 = D0
      
      RTS:
        inst_o.rs1 = 'h8;                     // rs1 = A0
      default:
        inst_o.rs1 = inst_i[10:8];
    endcase
  
  	// rs2
    case (inst_i) inside
      MOVA, MOVAD, LDB, LDW, ADDA, SUBA, STA, LDA, STBD, STWD, LDBD,
      LDWD:
        inst_o.rs2 = inst_i[6:4] + 8;         // rs2 = AREG      
        
      default:
        inst_o.rs2 = inst_i[6:4];
    endcase
    
    // rd
    case (inst_i) inside
      DTA, MOVDA, MOVA, ADDA, ADDDA, SUBA, SUBDA, LDA, LDWP, 
      ADDIA:
        inst_o.rd = inst_i[10:8] + 8;         // rd = AREG
      
      ANDI, ORI, XORI, TSTI, MULUI, DIVUI, MODI, MULI, 
      DIVI:
        inst_o.rd = 0;                        // rd = D0
      
      BSRF, JSR, BSR:
        inst_o.rd = 8;                        // rd = RA
        
      default:
        inst_o.rd = inst_i[10:8];
    endcase
                            
    //imm;                   
    //func;                  
    //fu;
    //wb;
    //wb_t;
    //read_rs1;
    //read_rs2;
    //read_t;
  end
  
endmodule
