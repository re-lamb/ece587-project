module branch(
  input clk,
  input rst,
  input recovery_en,
  input issue_en,
  input Inst_t issue_inst,
  input [`XLEN-1:0] rd_a, 
  input rd_t,
  output Cdb_pkt_t cdb_pkt,
  output logic [`XLEN-1:0] result,
  output logic result_en 
);
  Inst_t inst;
  logic [`XLEN-1:0] reg_a;
  logic reg_t;
  logic [`XLEN-1:0] op_a, op_b, npc;

  always_comb begin
    op_a = reg_a;
    op_b = inst.pc;
    op_t = reg_t;
    cdb_pkt.valid = (recovery_en) ? `FALSE : inst.valid;
    cdb_pkt.en = cdb_pkt.valid && inst.wb;
    cdb_pkt.t_en = `FALSE;
    cdb_pkt.idx = inst.rob_num;
    cdb_pkt.tag = inst.p_rd;
    cdb_pkt.t_tag = inst.p_t;
    cdb_pkt.exc = (npc != inst.npc) ? `TRUE : `FALSE;
    
    result = inst.pc + 2;
    result_en = cdb_pkt.en;
    
    case (inst.inst) 
      BRAF, BSRF: begin
        npc <= (op_a + op_b);
        
        cdb_pkt.npc <= npc;
      end
      JMP, JSR: begin
        
        npc <= op_a;
        cdb_pkt.npc <= npc;
      end
      BF: begin
        npc <= op_b + (inst.imm << 1);
      end
      BT: begin
      
      end
      BRA: begin
      
      end
      
      BSR: begin
      
      end
    endcase
  end
  
  always_ff @(posedge clk) begin
    if (rst || recovery_en) begin
      inst  <= '0;
      reg_a <= '0;
      reg_t <= '0;
    end
    else if (issue_en) begin
      inst  <= issue_inst;
      reg_a <= rd_a;
      reg_t <= rd_t;
    end
    else begin
      inst  <= '0;
      reg_a <= '0;
      reg_t <= '0;
    end
  end
endmodule