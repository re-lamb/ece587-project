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
  input rst,
  input [7:0][`PRW-1:0] reg_rd_addr,
  input [3:0][`PRW-1:0] reg_wr_addr,
  input [3:0][15:0] reg_wr_data,
  input [3:0] reg_wr_en,
  
  input [3:0][`TRW-1:0] reg_t_rd_addr,
  input [1:0][`TRW-1:0] reg_t_wr_addr,
  input [1:0] reg_t_wr_data,
  input [1:0] reg_t_wr_en,
  
  output logic [7:0][`XLEN-1:0] reg_rd_data,
  output logic [3:0] reg_t_rd_data
);
  logic [`PREGS-1:0][`XLEN-1:0] mem;
  logic [`TREGS-1:0] mem_t;
  
  generate
    initial begin
      for (integer i = 0; i < `PREGS; i++) mem[i] = '0;
      mem_t = '0;
      reg_rd_data = '0;
      reg_t_rd_data = '0;
    end
  endgenerate
  
  always @(posedge clk) begin
    if (rst)
      mem <= '0;
    else begin
      if (reg_wr_en[0]) mem[reg_wr_addr[0]] <= reg_wr_data[0];
      if (reg_wr_en[1]) mem[reg_wr_addr[1]] <= reg_wr_data[1];
      if (reg_wr_en[2]) mem[reg_wr_addr[2]] <= reg_wr_data[2];
      if (reg_wr_en[3]) mem[reg_wr_addr[3]] <= reg_wr_data[3];
      if (reg_t_wr_en[0]) mem_t[reg_t_wr_addr[0]] <= reg_t_wr_data[0];
      if (reg_t_wr_en[1]) mem_t[reg_t_wr_addr[1]] <= reg_t_wr_data[1];
    end
  end
  
  // forward wr->rd on addr match
  always @(posedge clk) begin
    for (int i = 0; i < 8; i++) begin
      if (rst) 
        reg_rd_data[i] <= '0;
      else begin
        if ((reg_rd_addr[i] == reg_wr_addr[0]) && reg_wr_en[i])
        	reg_rd_data[i] <= reg_wr_data[0];
      	else if ((reg_rd_addr[i] == reg_wr_addr[1]) && reg_wr_en[i])
        	reg_rd_data[i] <= reg_wr_data[1];
      	else if ((reg_rd_addr[i] == reg_wr_addr[2]) && reg_wr_en[i])
        	reg_rd_data[i] <= reg_wr_data[2];
      	else if ((reg_rd_addr[i] == reg_wr_addr[3]) && reg_wr_en[i])
        	reg_rd_data[i] <= reg_wr_data[3];
      	else 
        	reg_rd_data[i] = mem[reg_rd_addr[i]];
    	end
    end
    
    for (int i = 0; i < 4; i++) begin
      if (rst) 
        reg_t_rd_data[i] <= '0;
      else 
        reg_t_rd_data[i] <= ((reg_t_rd_addr[i] == reg_t_wr_addr[0]) && reg_t_wr_en[0]) ? reg_t_wr_data[0] : 
      					  	((reg_t_rd_addr[i] == reg_t_wr_addr[1]) && reg_t_wr_en[1]) ? reg_t_wr_data[1] : 
      					  	mem_t[reg_t_rd_addr[i]];
    end                        
  end
  
endmodule