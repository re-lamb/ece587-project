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
  
  assign map_t_rd_data = tmap;
  
  always_ff @(posedge clk) begin
    if (rst) begin
      for (int i = 0; i < `REGS; i++) begin
        map[i] <= i;
      end
      tmap <= '0;
    end
    else begin
      if (map_wr_en[0])
        map[map_rd_addr[0]] <= map_wr_data[0];
      if (map_wr_en[1])
        map[map_rd_addr[2]] <= map_wr_data[1];
      if (map_t_wr_en)
        tmap <= map_t_wr_data;
    end
  end
endmodule
