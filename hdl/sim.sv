/*
 * ECE587 Fall 2024 Final Project
 * R.E. Lamb
 *
 * CPU top level
 *
 */
`include "defs.svh"
`include "branch.sv"
`include "busybit.sv"
`include "decode.sv"
`include "fetch.sv"
`include "freelist.sv"
`include "int_alu.sv"
`include "maptable.sv"
`include "memory.sv"
`include "regfile.sv"
`include "reorder.sv"
`include "rs.sv"

module sim(
  input clk,
  input rst
);
  logic recovery_en;
  logic [1:0][`ALEN-1:0] fetch_pc;
  logic [1:0][`ALEN-1:0] fetch_inst;

  logic [`ALEN-1:0] recovery_addr;
  logic [1:0] dec_stall;

  If_id_pkt_t [1:0] if_id_pkt;
  logic [1:0] rob_rdy;
  logic [1:0][`RBW-1:0] next_rob;
  logic [1:0] rob_wr_en;

  logic [1:0] retire_en;
  logic [1:0][`PRW-1:0] next_retire;
  logic [1:0] retire_t_en;
  logic [1:0][`TRW-1:0] next_retire_t;

  logic [1:0][3:0] rs_rdy;
  logic [1:0] freelist_en;
  logic [1:0] freelist_t_en;
  logic [1:0] freelist_rdy;
  logic [1:0] freelist_t_rdy;

  logic [1:0][`PRW-1:0] next_free;
  logic [1:0][`TRW-1:0] next_free_t;

  logic [3:0][`ARW-1:0] map_rd_addr;
  logic [3:0][`PRW-1:0] map_rd_data;
  logic [3:0] map_t_rd_data;
  logic [1:0][`TRW-1:0] map_t_rd_addr;

  logic [3:0][`ARW-1:0] map_rd_addr_dec;
  logic [1:0][`ARW-1:0] map_wr_addr_rob;

  logic [3:0][`PRW-1:0] bb_rd_addr;
  logic [1:0][`TRW-1:0] bb_t_rd_addr;
  logic [3:0] bb_rd;
  logic [1:0] bb_t_rd;

  logic [1:0] map_wr_en_dec;
  logic [1:0] map_wr_en_rob;
  logic [1:0] map_wr_en;

  logic [1:0][`PRW-1:0] map_wr_data_dec;
  logic [1:0][`PRW-1:0] map_wr_data_rob;
  logic [1:0][`PRW-1:0] map_wr_data;

  logic map_t_wr_en_dec;
  logic map_t_wr_en_rob;
  logic map_t_wr_en;

  logic [`TRW-1:0] map_t_wr_data_dec;
  logic [`TRW-1:0] map_t_wr_data_rob;
  logic [`TRW-1:0] map_t_wr_data;

  Inst_t [1:0] issue_pkt;

  Cdb_pkt_t [3:0] cdb_pkt;
  Br_pkt_t br_pkt;

  logic [1:0][3:0] rs_en;
  logic [3:0] rdy;
  logic [1:0] rdy_t;

  logic [7:0][`PRW-1:0] reg_rd_addr;
  // logic [3:0][`PRW-1:0] reg_wr_addr;
  logic [3:0][`XLEN-1:0] reg_wr_data;
  logic [7:0][`XLEN-1:0] reg_rd_data;
  logic [3:0] reg_wr_en;

  logic [3:0][`TRW-1:0] reg_t_rd_addr;
  // logic [1:0][`TRW-1:0] reg_t_wr_addr;
  logic [3:0] reg_t_rd_data;
  logic [1:0] reg_t_wr_data;
  logic [1:0] reg_t_wr_en;

  logic [1:0] int_issue_en;
  logic [1:0] br_issue_en;

  Inst_t [1:0] int_issue_pkt;
  Inst_t [1:0] br_issue_pkt;

  // TODO: think on this a bit
  assign map_wr_en = (|map_wr_en_rob) ?  map_wr_en_rob : map_wr_en_dec;
  assign map_wr_data = (|map_wr_en_rob) ? map_wr_data_rob : map_wr_data_dec;
  assign map_rd_addr = (|map_wr_en_rob) ? {4'b0, map_wr_addr_rob[1], 4'b0, map_wr_addr_rob[0]} : map_rd_addr_dec;
  assign map_t_wr_en = (map_t_wr_en_rob) ? '1 : map_t_wr_en_dec;
  assign map_t_wr_data = (map_t_wr_en_rob) ? map_t_wr_data_rob : map_t_wr_data_dec;
  
  assign reg_wr_en[3] = '0;
  assign reg_wr_data[3] = '0;

  assign cdb_pkt[`CDB_LSQ] = '0;
  assign rs_rdy[0][3:2] = '0;
  assign rs_rdy[1][3:2] = '0;

// memory - 95%
  memory #(.memfile("program.mem"))
  mem(
  .clk(clk),
  .rd_addr_0(fetch_pc[0]),
  .rd_addr_1(fetch_pc[1]),
  .rd_addr_2('0),
  .wr_addr_0('0),
  .wr_data_0('0),
  .wr_en('0),
  .rd_data_0(fetch_inst[0]),
  .rd_data_1(fetch_inst[1]),
  .rd_data_2()
);

// fetch ifu - 95%
fetch ifu(
  .clk(clk),
  .rst(rst),
  .br_taken(recovery_en),
  .br_addr(recovery_addr),
  .dec_stall(dec_stall),
  .bp_hit({'0, '0}),
  .bp_taken({'0, '0}),
  .bp_state({'0, '0}),
  .bp_addr('0),
  .inst(fetch_inst),
  .fetch_pc(fetch_pc),
  .if_id_pkt(if_id_pkt)
);

// add RAS?

// bpred bp(); - 0%

// decode - 75% - needs rob_packet/fu_select
decode id(
  .clk(clk),
  .rst(rst),
  .if_id_pkt(if_id_pkt),
  .rob_rdy(rob_rdy),
  .next_rob(next_rob),
  .rs_rdy(rs_rdy),
  .freelist_rdy(freelist_rdy),
  .next_free(next_free),
  .freelist_t_rdy(freelist_t_rdy),
  .next_free_t(next_free_t),
  .map_rd_data(map_rd_data),
  .map_t_rd_data(map_t_rd_data),
  .dec_stall(dec_stall),
  .rob_wr_en(rob_wr_en),
  .rs_en(rs_en),
  .freelist_en(freelist_en),
  .freelist_t_en(freelist_t_en),
  .map_wr_en(map_wr_en_dec),
  .map_wr_data(map_wr_data_dec),
  .map_t_wr_en(map_t_wr_en_dec),
  .map_t_wr_data(map_t_wr_data_dec),
  .map_rd_addr(map_rd_addr_dec),
  .map_t_rd_addr(map_t_rd_addr),
  .bb_rd_addr(bb_rd_addr),
  .bb_t_rd_addr(bb_t_rd_addr),
  .bb_rd(bb_rd),
  .bb_t_rd(bb_t_rd),
  .rdy(rdy),
  .rdy_t(rdy_t),
  .issue_pkt(issue_pkt)
);

// ROB - 60%
reorder rob(
  .clk(clk),
  .rst(rst),
  .issue_pkt(issue_pkt),
  .rob_wr_en(rob_wr_en),
  .cdb_pkt(cdb_pkt),
  .br_pkt(br_pkt),
  .recovery_en(recovery_en),
  .recovery_addr(recovery_addr),
  .rob_rdy(rob_rdy),
  .next_rob(next_rob),
  .retire_en(retire_en),
  .next_retire(next_retire),
  .retire_t_en(retire_t_en),
  .next_retire_t(next_retire_t),
  .map_wr_en(map_wr_en_rob),
  .map_wr_addr(map_wr_addr_rob),
  .map_wr_data(map_wr_data_rob),
  .map_t_wr_en(map_t_wr_en_rob),
  .map_t_wr_data(map_t_wr_data_rob),
  .bp_addr(),
  .bp_target(),
  .bp_state(),
  .bp_wr()
);

// free list
freelist fl(
  .clk(clk),
  .rst(rst),
  .retire_en(retire_en),
  .next_retire(next_retire),
  .retire_t_en(retire_t_en),
  .next_retire_t(next_retire_t),
  .freelist_en(freelist_en),
  .freelist_t_en(freelist_t_en),
  .freelist_rdy(freelist_rdy),
  .next_free(next_free),
  .freelist_t_rdy(freelist_t_rdy),
  .next_free_t(next_free_t)
);

// busybit vector
busybit bsy(
  .clk(clk),
  .rst(rst),
  .recovery_en(recovery_en),
  .cdb_pkt(cdb_pkt),
  .freelist_en(freelist_en),
  .next_free(next_free),
  .freelist_t_en(freelist_t_en),
  .next_free_t(next_free_t),
  .rd_addr(bb_rd_addr),
  .rd_addr_t(bb_t_rd_addr),
  .rdy(bb_rd),
  .rdy_t(bb_t_rd)
);

// maptable - 90% - needs rollback - controlled by rob?
maptable rmap(
  .clk(clk),
  .rst(rst),
  .map_rd_addr(map_rd_addr),
  .map_wr_en(map_wr_en),
  .map_wr_data(map_wr_data),
  .map_t_wr_en(map_t_wr_en),
  .map_t_wr_data(map_t_wr_data),
  .map_rd_data(map_rd_data),
  .map_t_rd_data(map_t_rd_data)
);

// regfile - 95%
regfile regs(
  .clk(clk),
  .rst(rst),
  .reg_rd_addr(reg_rd_addr),
  .reg_wr_addr({cdb_pkt[3].tag, cdb_pkt[2].tag, cdb_pkt[1].tag, cdb_pkt[0].tag}),
  .reg_wr_data(reg_wr_data),
  .reg_wr_en(reg_wr_en),
  .reg_t_rd_addr(reg_t_rd_addr),
  .reg_t_wr_addr({cdb_pkt[1].t_tag, cdb_pkt[0].t_tag}),
  .reg_t_wr_data(reg_t_wr_data),
  .reg_t_wr_en(reg_t_wr_en),
  .reg_rd_data(reg_rd_data),
  .reg_t_rd_data(reg_t_rd_data)
);

// issue - 75% - use logisim design
rs int_rs(
  .clk(clk),
  .rst(rst),
  .recovery_en(recovery_en),
  .rs_en({rs_en[1][`ALU], rs_en[0][`ALU]}),
  .issue_pkt(issue_pkt),
  .reg_rdy(rdy),
  .reg_rdy_t(rdy_t),
  .fu_rdy('1),
  .cdb_pkt(cdb_pkt),
  .rs_rdy({rs_rdy[1][`ALU], rs_rdy[0][`ALU]}),
  .issue_en(int_issue_en),
  .rs_issue_pkt(int_issue_pkt),
  .op_rd_addr(reg_rd_addr[3:0]),
  .op_t_rd_addr(reg_t_rd_addr[1:0])
);

// int_fu - 95% - recycle
int_alu int_0(
  .clk(clk),
  .rst(rst),
  .recovery_en(recovery_en),
  .issue_en(int_issue_en[0]),
  .issue_inst(int_issue_pkt[0]),
  .rd_a(reg_rd_data[0]),
  .rd_b(reg_rd_data[1]),
  .rd_t(reg_t_rd_data[0]),
  .cdb_pkt(cdb_pkt[`CDB_ALU0]),
  .result(reg_wr_data[0]),
  .result_en(reg_wr_en[0]),
  .result_t(reg_t_wr_data[0]),
  .result_t_en(reg_t_wr_en[0])
);

// int_fu - 95% - recycle
int_alu int_1(
  .clk(clk),
  .rst(rst),
  .recovery_en(recovery_en),
  .issue_en(int_issue_en[1]),
  .issue_inst(int_issue_pkt[1]),
  .rd_a(reg_rd_data[2]),
  .rd_b(reg_rd_data[3]),
  .rd_t(reg_t_rd_data[1]),
  .cdb_pkt(cdb_pkt[`CDB_ALU1]),
  .result(reg_wr_data[1]),
  .result_en(reg_wr_en[1]),
  .result_t(reg_t_wr_data[1]),
  .result_t_en(reg_t_wr_en[1])
);

rs br_rs(
  .clk(clk),
  .rst(rst),
  .recovery_en(recovery_en),
  .rs_en({rs_en[1][`BR], rs_en[0][`BR]}),
  .issue_pkt(issue_pkt),
  .reg_rdy(rdy),
  .reg_rdy_t(rdy_t),
  .fu_rdy({'0,'1}),
  .cdb_pkt(cdb_pkt),
  .rs_rdy({rs_rdy[1][`BR], rs_rdy[0][`BR]}),
  .issue_en(br_issue_en),
  .rs_issue_pkt(br_issue_pkt),
  .op_rd_addr(reg_rd_addr[7:4]),
  .op_t_rd_addr(reg_t_rd_addr[3:2])
);

// branch unit - 95% - simple (...)
branch br(
  .clk(clk),
  .rst(rst),
  .recovery_en(recovery_en),
  .issue_en(br_issue_en[0]),
  .issue_inst(br_issue_pkt[0]),
  .rd_a(reg_rd_data[4]),
  .rd_t(reg_t_rd_data[2]),
  .cdb_pkt(cdb_pkt[`CDB_BR]),
  .br_pkt(br_pkt),
  .result(reg_wr_data[2]),
  .result_en(reg_wr_en[2])
);


// load/store unit - 0% - xxx
//loadstore lsu(

//);

endmodule
