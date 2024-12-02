/*
 * ECE587 Fall 2024 Final Project
 * R.E. Lamb
 *
 * register free list
 *
 * claim/retire 2 physical reg mappings per cycle
 * as well as 2/2 t-bit mappings
 *
 */

module freelist(
  input clk,
  input rst,

  input [1:0] retire_en,            // free stale mappings on retire
  input [1:0][4:0] next_retire,
  input [1:0] retire_t_en,
  input [1:0][4:0] next_retire_t,

  input [1:0] freelist_en,          // free list reqs from decode
  input [1:0] freelist_t_en,
  
  output [1:0] freelist_rdy,        // valid free reg
  output [1:0][4:0] next_free,      // free reg name
  
  output [1:0] freelist_t_rdy,
  output [1:0][3:0] next_free_t
);
  logic [1:0][4:0] next_free_idx;
  logic [1:0][31:0] bitmap;
  logic [1:0] rdy;
  logic [31:0] set_mask, clear_mask;

  assign bitmap[1] = (bitmap[0] & ~(1 << next_free[0]));
  assign set_mask = (retire_en[0] ? (1 << next_retire[0]) : '0) | (retire_en[1] ? (1 << next_retire[1]) : '0);
  assign clear_mask = (freelist_en[0] ? (1 << next_free[0]) : '0) | (freelist_en[1] ? (1 << next_free[1]) : '0);

  always_ff @(posedge clk) begin
    if (rst)
      bitmap[0] <= 32'hffff0000;    // on reset 0-15 mapped, 16-31 free
    else
      bitmap[0] <= (bitmap[0] & ~clear_mask) | set_mask;
  end

  always_comb begin
    next_free_idx[0] <= '0;
    next_free_idx[1] <= '0;
    rdy[0] <= '0;
    rdy[1] <= '0;

    for (int i = 31; i >= 0; i--) begin
      if (bitmap[0][i] == 1'b1) begin
        next_free_idx[0] <= i;
        rdy[0] <= 1'b1;
        break;
      end
    end

    for (int i = 31; i >= 0; i--) begin
      if (bitmap[1][i]  == 1'b1) begin
        next_free_idx[1] <= i;
        rdy[1] <= 1'b1;
        break;
      end
    end
  end
  
  assign freelist_rdy[0] = rdy[0];
  assign next_free[0] = next_free_idx[0];

  // if it's the last free and inst0 doesn't want it, offer it to inst1
  assign freelist_rdy[1] = (rdy[0] && !freelist_en[0] && !rdy[1]) ? rdy[0] : rdy[1];
  assign next_free[1] = (rdy[0] && !freelist_en[0] && !rdy[1]) ? next_free_idx[0] : next_free_idx[1];
  
    
  logic [1:0][3:0] next_free_t_idx;
  logic [1:0][15:0] bitmap_t;
  logic [1:0] rdy_t;
  logic [15:0] set_mask_t, clear_mask_t;

  assign bitmap_t[1] = (bitmap_t[0] & ~(1 << next_free_t[0]));
  assign set_mask_t = (retire_t_en[0] ? (1 << next_retire_t[0]) : '0) | (retire_t_en[1] ? (1 << next_retire_t[1]) : '0);
  assign clear_mask_t = (freelist_t_en[0] ? (1 << next_free_t[0]) : '0) | (freelist_t_en[1] ? (1 << next_free_t[1]) : '0);

  always_ff @(posedge clk) begin
    if (rst)
      bitmap_t[0] <= 16'hfffe;      // on reset 0 is mapped, 1-15 free
    else
      bitmap_t[0] <= (bitmap_t[0] & ~clear_mask_t) | set_mask_t;
  end

  always_comb begin
    next_free_t_idx[0] <= '0;
    next_free_t_idx[1] <= '0;
    rdy_t[0] <= '0;
    rdy_t[1] <= '0;

    for (int i = 15; i > 0; i--) begin
      if (bitmap_t[0][i] == 1'b1) begin
        next_free_t_idx[0] <= i;
        rdy_t[0] <= 1'b1;
        break;
      end
    end

    for (int i = 31; i >= 0; i--) begin
      if (bitmap_t[1][i]  == 1'b1) begin
        next_free_t_idx[1] <= i;
        rdy_t[1] <= 1'b1;
        break;
      end
    end
  end

  assign freelist_t_rdy[0] = rdy_t[0];
  assign next_free_t[0] = next_free_t_idx[0];

  // if it's the last free and inst0 doesn't want it, offer it to inst1
  assign freelist_t_rdy[1] = (rdy_t[0] && !freelist_t_en[0] && !rdy_t[1]) ? rdy_t[0] : rdy_t[1];
  assign next_free_t[1] = (rdy_t[0] && !freelist_t_en[0] && !rdy_t[1]) ? next_free_t_idx[0] : next_free_t_idx[1];

endmodule

module freelist_tb();
  bit clk;
  bit rst = 1;
  bit [1:0] freelist_en;

  bit [1:0] retire_en;
  bit [1:0][4:0] next_retire;

  wire [1:0] freelist_rdy;
  wire [1:0][4:0] next_free;

  freelist DUT(.*);

  initial begin
    $dumpfile("dump.vcd"); $dumpvars;

    #1 clk = ~clk; #1 rst = 0; #1 clk = ~clk;

    #1 $display("%d %b, %d, %b", next_free[0], freelist_rdy[0], next_free[1], freelist_rdy[1]);

    // take out 30 -> 31, 29
    #1 freelist_en[1] = 1;
    #1 clk = ~clk; #1 clk = ~clk;
    #1 $display("%d %b, %d, %b", next_free[0], freelist_rdy[0], next_free[1], freelist_rdy[1]);

    // take out 31, 29 -> 28, 27
    #1 freelist_en[0] = 1;
    #1 clk = ~clk; #1 clk = ~clk;
    #1 $display("%d %b, %d, %b", next_free[0], freelist_rdy[0], next_free[1], freelist_rdy[1]);

    // add 30 -> 30, 28
    retire_en[0] = 1; next_retire[0] = 30;
    freelist_en[0] = 0; freelist_en[1] = 0;

    #1 clk = ~clk; #1 clk = ~clk;
    #1 $display("%d %b, %d, %b", next_free[0], freelist_rdy[0], next_free[1], freelist_rdy[1]);

    // add 31, add 15, -> 31, 30
    retire_en[0] = 1; retire_en[1] = 0;
    next_retire[0] = 31; next_retire[1] = 15;
    #1 clk = ~clk; #1 clk = ~clk;
    #1 $display("%d %b, %d, %b", next_free[0], freelist_rdy[0], next_free[1], freelist_rdy[1]);

    // do nothing -> 31, 30
    retire_en[0] = 0; retire_en[1] = 0;
    freelist_en[0] = 0; freelist_en[1] = 0;
    #1 clk = ~clk; #1 clk = ~clk;
    #1 $display("%d %b, %d, %b", next_free[0], freelist_rdy[0], next_free[1], freelist_rdy[1]);

    //  -> 28, 27
    freelist_en[0] = 1; freelist_en[1] = 1;
    #1 clk = ~clk; #1 clk = ~clk;
    #1 $display("%d %b, %d, %b", next_free[0], freelist_rdy[0], next_free[1], freelist_rdy[1]);

    for (int i = 0; i < 15; i++) begin
      #1 clk = ~clk; #1 clk = ~clk;
      #1 $display("%d %b, %d, %b", next_free[0], freelist_rdy[0], next_free[1], freelist_rdy[1]);
    end

    #1 $finish;
  end

endmodule