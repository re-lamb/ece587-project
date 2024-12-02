/*
 * ECE587 Fall 2024 Final Project
 * R.E. Lamb
 *
 * 4W/8R physical register file
 * 32 x 16b, pipelined with internal wr/rd forwarding
 *
 */

module regfile(
  input clk,
  input [7:0][4:0]  reg_rd_addr,
  input [3:0][4:0]  reg_wr_addr,
  input [3:0][15:0] reg_wr_data,
  input [4:0]       reg_wr_en,
  
  output [8:0][15:0] reg_rd_data
);
  logic [31:0][15:0] mem;
  logic [7:0][15:0] out_reg;
  
  always @(posedge clk) begin
    if (reg_wr_en[0])
      mem[reg_wr_addr[0]] <= reg_wr_data[0];
    if (reg_wr_en[1])
      mem[reg_wr_addr[1]] <= reg_wr_data[1];
    if (reg_wr_en[2])
      mem[reg_wr_addr[2]] <= reg_wr_data[2];
    if (reg_wr_en[3])
      mem[reg_wr_addr[3]] <= reg_wr_data[3];
  end
  
  // forward wr->rd on addr match
  always @(posedge clk) begin
    for (int i = 0; i < 8; i++) begin
      if ((reg_rd_addr[i] == reg_wr_addr[0]) && reg_wr_en[i])
        out_reg <= reg_wr_data[0];
      else if ((reg_rd_addr[i] == reg_wr_addr[1]) && reg_wr_en[i])
        out_reg <= reg_wr_data[1];
      else if ((reg_rd_addr[i] == reg_wr_addr[2]) && reg_wr_en[i])
        out_reg <= reg_wr_data[2];
      else if ((reg_rd_addr[i] == reg_wr_addr[3]) && reg_wr_en[i])
        out_reg <= reg_wr_data[3];
      else 
        out_reg <= mem[reg_rd_addr[i]];
    end
  end
  
endmodule