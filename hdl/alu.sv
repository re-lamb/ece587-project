module exec_int(
  input clk,
  input rst,
  input recovery_en,
  input Inst_t issue_inst,
  input [`XLEN-1:0] reg_a, 
  input [`XLEN-1:0] reg_b,
  input reg_t;
  output Cdb_pkt_t cdb_pkt,
  output [`XLEN-1:0] result,
  output result_en
);
  Inst_t inst;
  logic [`XLEN-1:0] op_a, op_b;
  
  
  always_ff @(posedge clk) begin
    if (rst || recovery_en) 
      inst <= '0;
    else begin
      inst <= issue_inst;
    end
  end
  
  always_comb begin
    op_a = reg_a;
    op_b = (inst.use_imm) ? inst.imm : reg_b;
    op_t = (inst.read_t) ? reg_t : '0;
    cdb_pkt.en = (recovery_en) ? '0 : (inst.valid && inst.wb);
    cdb_pkt.t_en = (recovery_en) ? '0 : (inst.valid && inst.wbt);
    cdb_pkt.idx = inst.idx;
    cdb_pkt.tag = inst.p_rd;
    cdb_pkt.t_tag = inst.p_t;
    cdb_pkt.exc = (inst.valid) ? `TRUE : `FALSE;
    
    case (inst.inst) begin
      CLRT: begin
        func = 
        a,
        b,
        t_in,
        f,
        t_out,
      end
      SETT: 
      NOTT:
      MOVT:
      DTD: 
      DTA: 
      SGZ:
      SGZU:
      MOV, MOVDA, MOVA, MOVAD, ADD, ADDC, ADDV, 
      ADDA, ADDDA, SUB, SUBC, SUBV, SUBA, SUBDA, AND, TST, NEG, NEGC, NOT, OR, XOR, SEQ, SGE,   
      SGEU, SGT, SGTU, EXTSB, EXTUB, SLL, SRL, SRA, ROT, BCLR, BSET, BNOT, BTST, BCLRI, BSETI, 
      BNOTI, BTSTI, SLLI, SRLI, SRAI, ROTI, ADDI, ADDIA, SEQI, MOVI, ANDI, ORI, XORI, TSTI: 
        inst_o.fu = `ALU;
      
      MUL, DIV, MOD, MULUI, DIVUI, MODI, MULI, DIVI:
        inst_o.fu = `ALU;
      
    endcase
  end
  
endmodule

module alu(
  input func,
  input a,
  input b,
  input t_in,
  output f,
  output t_out,
);
  logic signed [`XLEN-1:0] a, b, f;
  logic signed [`XLEN:0] val;
  
  assign f = val[`XLEN-1:0];
  
  always_comb begin
    case (func) 
      op_add:
        val = a + b;
      op_addc: begin
        val = a + b + t_in;
        t_out = f[`XLEN];
      end
      op_addv: begin
        val = a + b;
        t_out = a[`XLEN-2] ^ b[`XLEN-2] ^ val[`XLEN];
      end
      op_sub:
        val = a - b;
      op_subc: begin
        val = a - b - t_in;
        t_out = f[`XLEN];
      end
      op_subv: begin
        val = a - b;
        t_out = a[`XLEN-2] ^ b[`XLEN-2] ^ val[`XLEN];
      end
      op_passb:
        val = b;
      op_and:
        val = a & b;
      op_or:
        val = a | b;
      op_not:
        val = ~b;
      op_xor:
        val = a ^ b;
      default: begin
        val = 'hbad1;
        t_out = t_in;
      end
    endcase
  end

endmodule