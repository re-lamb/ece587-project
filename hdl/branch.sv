/*
 * ECE587 Fall 2024 Final Project
 * R.E. Lamb
 *
 * branch unit
 * 
 * calculate branch target and generate bp update  
 *
 */

module branch(
  input clk,
  input rst,
  input recovery_en,
  input issue_en,
  input Inst_t issue_inst,
  input [`XLEN-1:0] rd_a, 
  input rd_t,
  output Cdb_pkt_t cdb_pkt,
  output Br_pkt_t br_pkt, 
  output logic [`XLEN-1:0] npc,
  output logic [`XLEN-1:0] result,
  output logic result_en
);
  Inst_t inst;
  logic [`XLEN-1:0] reg_a;
  logic reg_t, op_t;
  logic [`XLEN-1:0] op_a, op_b;

  always_comb begin
    op_a = reg_a;
    op_b = inst.pc;
    op_t = reg_t;
    cdb_pkt.valid = (recovery_en) ? `FALSE : inst.valid;
    cdb_pkt.en = cdb_pkt.valid && inst.wb;
    cdb_pkt.t_en = `FALSE;
    cdb_pkt.idx = inst.rob_num;
    cdb_pkt.tag = inst.p_rd;
    cdb_pkt.t_tag = '0;
    cdb_pkt.exc = (npc != inst.npc) ? `TRUE : `FALSE;
    
    if (npc != inst.npc) begin
      case (inst.bp_state)
        BP_SNT: br_pkt.next_bp = BP_WNT;
        BP_WNT: br_pkt.next_bp = BP_WT;
        BP_WT:  br_pkt.next_bp = BP_WNT;
        BP_ST:  br_pkt.next_bp = BP_WT;
      endcase
    end
    else begin
      case (inst.bp_state) 
        BP_SNT: br_pkt.next_bp = BP_SNT;
        BP_WNT: br_pkt.next_bp = BP_SNT;
        BP_WT:  br_pkt.next_bp = BP_ST;
        BP_ST:  br_pkt.next_bp = BP_ST;
      endcase
    end
    
    br_pkt.next_bp = inst.bp_state;
    br_pkt.bp_wr = `FALSE;
    
    result = inst.pc + 2;
    result_en = cdb_pkt.en;
    
    case (inst.inst) 
      BRAF, BSRF:
        npc = op_a + op_b;
      JMP, JSR:
        npc = op_a;
      BF: begin
        npc = !(reg_t) ? (op_b + (inst.imm << 1)) : (op_b + 2);
        br_pkt.bp_wr = `TRUE;
      end
      BT: begin
        npc = (reg_t) ? (op_b + (inst.imm << 1)) : (op_b + 2);
        br_pkt.bp_wr = `TRUE;
      end
      BRA: begin
        npc = (op_b + (inst.imm << 1));
        br_pkt.bp_wr = `TRUE;
      end
      BSR: begin
        npc = (op_b + (inst.imm << 1));
        br_pkt.bp_wr = `TRUE;
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