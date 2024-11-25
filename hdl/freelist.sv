/*
 * ECE587 Fall 2024 Final Project
 * R.E. Lamb
 *
 * register free list
 *
 * allows two issues + retires per cycle
 * 
 */

module freelist(
  input clk,
  input rst,
  
  input [1:0] retire_en,
  input [1:0][4:0] next_retire,
  
  input [1:0] freelist_en,        		  // free list reqs
  output logic [1:0] freelist_rdy,      // valid reg
  output logic [1:0][4:0] next_free     // reg num
);

  logic [1:0][31:0] bitmap;
  assign bitmap[1] = (bitmap[0] & ~(1 << next_free[0]));
  
  logic [31:0] set_mask, clear_mask;
  
  always_comb begin
    next_free[0] <= '0;
    next_free[1] <= '0;
    freelist_rdy[0] <= '0;
    freelist_rdy[1] <= '0;
      
    for (int i = 31; i >= 0; i--) begin
      if (bitmap[0][i] == 1'b1) begin
        next_free[0] <= i;                               
        freelist_rdy[0] <= 1'b1;
        break;          
      end
    end
      
    for (int i = 31; i >= 0; i--) begin
      if (bitmap[1][i]  == 1'b1) begin
        next_free[1] <= i;                               
        freelist_rdy[1] <= 1'b1;
        break;          
      end
    end
  end
  
  assign set_mask = (retire_en[0] ? (1 << next_retire[0]) : '0) | (retire_en[1] ? (1 << next_retire[1]) : '0);
  assign clear_mask = (freelist_en[0] ? (1 << next_free[0]) : '0) | (freelist_en[1] ? (1 << next_free[1]) : '0);                   
  
  always_ff @(posedge clk) begin
    if (rst)
      bitmap[0] <= 32'hffff0000;
    else 
      bitmap[0] <= (bitmap[0] & ~clear_mask) | set_mask;
  end    
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