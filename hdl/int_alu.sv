/*
 * ECE587 Fall 2024 Final Project
 * R.E. Lamb
 *
 * ALU
 *
 * integer ALU with mul/div - sim only
 *
 */

module int_alu(
  input clk,
  input rst,
  input recovery_en,
  input issue_en,
  input Inst_t issue_inst,
  input [`XLEN-1:0] rd_a,
  input [`XLEN-1:0] rd_b,
  input rd_t,
  output Cdb_pkt_t cdb_pkt,
  output logic [`XLEN-1:0] result,
  output logic result_en,
  output logic result_t,
  output logic result_t_en
);
  Inst_t inst;
  logic [`XLEN-1:0] reg_a, reg_b;
  logic reg_t;
  logic [`XLEN-1:0] op_a, op_b, f;
  logic [4:0] func;
  logic op_t, co, z, v, n;

  always_ff @(posedge clk) begin
    if (rst || recovery_en) begin
      inst  <= '0;
      reg_a <= '0;
      reg_b <= '0;
      reg_t <= '0;
    end
    else if (issue_en) begin
      inst  <= issue_inst;
      reg_a <= rd_a;
      reg_b <= rd_b;
      reg_t <= rd_t;
    end
    else begin
      inst  <= '0;
      reg_a <= '0;
      reg_b <= '0;
      reg_t <= '0;
    end
  end

  alu alu(
    .func (func),
    .a    (op_a),
    .b    (op_b),
    .ci   (op_t),
    .f    (f),
    .co   (co),
    .v    (v),
    .z    (z),
    .n    (n)
  );

  always_comb begin
    op_a = reg_a;
    op_b = (inst.use_imm) ? inst.imm : reg_b;
    op_t = (inst.read_t) ? reg_t : `FALSE;
    cdb_pkt.valid = (recovery_en) ? `FALSE : inst.valid;
    cdb_pkt.en = cdb_pkt.valid && inst.wb;
    cdb_pkt.t_en = cdb_pkt.valid && inst.wbt;
    cdb_pkt.idx = inst.rob_num;
    cdb_pkt.tag = inst.p_rd;
    cdb_pkt.t_tag = inst.p_t;

    result = f;
    result_t = op_t;
    result_en = cdb_pkt.en;
    result_t_en = cdb_pkt.t_en;

    case (inst.inst)
      CLRT: result_t = '0;
      SETT: result_t = '1;
      NOTT: result_t = ~reg_t;
      MOVT: result = reg_t;
      DTD, DTA: begin
        func = op_sub;
        result_t = z;
      end
      SGZ: begin
        func = op_add;
        op_b = '0;
        result_t = !(z | n);
      end
      SGZU: begin
        func = op_add;
        op_b = '0;
        result_t = !z;
      end
      MOV, MOVDA, MOVA, MOVAD, MOVI: func = op_passb;
      ADD, ADDA, ADDDA, ADDI, ADDIA: func = op_add;
      ADDC: begin
        func = op_add;
        result_t = co;
      end
      ADDV: begin
        func = op_add;
        result_t = v;
      end
      SUB, SUBA, SUBDA:
        func = op_sub;
      SUBC: begin
        func = op_sub;
        result_t = co;
      end
      SUBV: begin
        func = op_sub;
        result_t = v;
      end
      AND, ANDI: func = op_and;
      TST, TSTI: begin
        func = op_and;
        result_t = z;
      end
      NEG: begin
        func = op_sub;
        op_a = 0;
      end
      NEGC: begin
        func = op_sub;
        op_a = 0;
        result_t = co;
      end
      NOT: func = op_not;
      OR, ORI: func = op_or;
      XOR, XORI: func = op_xor;
      BCLR, BCLRI: func = op_bclr;
      BSET, BSETI: func = op_bset;
      BNOT, BNOTI: func = op_bnot;
      BTST, BTSTI: begin
        func = op_btst;
        result_t = f[0];
      end
      SLL, SLLI: func = op_sll;
      SRL, SRLI: func = op_srl;
      SRA, SRAI: func = op_sra;
      ROT, ROTI: func = op_rot;
      SEQ, SEQI: begin
        func = op_sub;
        result_t = z;
      end
      SGE: begin
        func = op_sub;
        result_t = (n == v);
      end
      SGEU: begin
        func = op_sub;
        result_t = (z | co);
      end
      SGT: begin
        func = op_sub;
        result_t = (!z & (n == v));
      end
      SGTU: begin
        func = op_sub;
        result_t = (!z & co);
      end
      EXTSB: func = op_ext;
      EXTUB: begin
        func = op_and;
        op_a = 'h00ff;
      end

      // TODO: figure out the mul/div situation
      MUL, MULI, MULUI: func = op_mul;
      DIV, DIVI, DIVUI: begin
        if (op_b == 0) begin
          func = op_passb;
          cdb_pkt.exc = `TRUE;
        end
        else func = op_div;
      end
      MOD, MODI: func = op_mod;
      default:
        cdb_pkt.exc = `TRUE;
    endcase
  end

endmodule

module alu(
  input [4:0] func,
  input [`XLEN-1:0] a,
  input [`XLEN-1:0] b,
  input ci,
  output [`XLEN-1:0] f,
  output co,
  output v,
  output z,
  output n
);
  logic [`XLEN:0] val;

  assign f = val[`XLEN-1:0];
  assign co = val[`XLEN];
  assign v = a[`XLEN-2] ^ b[`XLEN-2] ^ val[`XLEN];
  assign z = (f == '0);
  assign n = val[`XLEN-1];

  always_comb begin
    case (func)
      op_add:
        val = a + b + ci;
      op_sub:
        val = a - b - ci;
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
      op_sll:
        val = a >> b[3:0];
      op_srl:
        val = a << b[3:0];
      op_sra:
        val = a <<< b[3:0];
      op_rot:
        val = {2{a}} >> b[3:0];
      op_ext:
        val = {{8{b[7]}}, b[7:0]};
      op_mul:
        val = a * b;
      op_div:
        val = a / b;
      op_mod:
        val = a % b;
      op_bclr:
        val = a & ~(1 << b[3:0]);
      op_bset:
        val = a | (1 << b[3:0]);
      op_bnot:
        val = (a & (1 << b[3:0])) ? (a & ~(1 << b[3:0])) : (a | (1 << b[3:0]));
      op_btst:
        val = a[b[3:0]];
      default:
        val = 'hbad1;
    endcase
  end

endmodule