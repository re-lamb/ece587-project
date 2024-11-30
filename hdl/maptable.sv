/*
 * ECE587 Fall 2024 Final Project
 * R.E. Lamb
 *
 * register name table
 *
 * maps 16 architectural regs to 32 physical
 * maps 1 architectural t-bit to 16 physical
 *
 */
 
module maptable(
  input clk,
  input rst,

  input [3:0][3:0] map_rd_addr,
  
  input [1:0] map_wr_en,
  input [1:0][4:0] map_wr_data,
  
  input [1:0] map_t_wr_en,
  input [3:0] map_t_wr_data,
  
  output [3:0][4:0] map_rd_data,
  output [3:0] map_t_rd_data  
);

  logic [15:0][4:0] map;
  logic [3:0] tmap;

  assign map_rd_data[0] = map[map_rd_addr[0]];
  assign map_rd_data[1] = map[map_rd_addr[1]];
  assign map_rd_data[2] = map[map_rd_addr[2]];
  assign map_rd_data[3] = map[map_rd_addr[3]];
  
  always_ff @(posedge clk) begin
    if (rst) begin
      for (int i = 0; i < `REGS; i++)
        map[i] <= i;
      tmap <= 0;
    end
    if (map_wr_en[0])
      map[map_rd_addr[0]] <= map_wr_data[0];
    if (map_wr_en[1])
      map[map_rd_addr[2]] <= map_wr_data[1];
    if (map_t_wr_en)
      tmap <= map_t_wr_data;
  end
endmodule

module maptable_tb();

  bit clk, rst;
  bit [3:0][4:0] map_rd_addr;
  bit [1:0] map_wr_en;
  bit [1:0][4:0] map_wr_data;
  
  logic [3:0][4:0] map_rd_data;
  
  maptable DUT(.*);
  
  initial begin
   	map_wr_data[0] = 4;
    map_wr_en[0] = 1;
    map_rd_addr[1] = 1;
    map_rd_addr[2] = 2;
    map_rd_addr[3] = 3;
    
    $monitor ("ra: %d,%d,%d,%d rd: %d,%d,%d,%d", map_rd_addr[0], map_rd_addr[1], map_rd_addr[2], map_rd_addr[3],
              map_rd_data[0], map_rd_data[1], map_rd_data[2], map_rd_data[3]);
    
    #1 clk = ~clk; #1 clk = ~clk;
    map_wr_en[0] = 0;
    #1 clk = ~clk; #1 clk = ~clk;
    #1 clk = ~clk; #1 clk = ~clk;
    
    map_wr_data[1] = 21;
    map_wr_en[1] = 1;
    #1 clk = ~clk; #1 clk = ~clk;
    
  end

endmodule