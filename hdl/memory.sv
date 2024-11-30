/*
 * ECE587 Fall 2024 Final Project
 * R.E. Lamb
 *
 * main memory
 *
 * async reads, synchronous writes
 * writes are byte addressable, all reads are 16b
 *
 */
`include "defs.svh"

module memory 
  #(parameter mem_clear = 0,
    parameter memfile = "") 
  (
  input clk,
  input [`ALEN-1:0] rd_addr_0,
  input [`ALEN-1:0] rd_addr_1,
  input [`ALEN-1:0] rd_addr_2,
  
  input [`ALEN-1:0] wr_addr_0,
  input [`XLEN-1:0] wr_data_0,
  input [1:0] wr_en, 
  
  output [`ALEN-1:0] rd_data_0,
  output [`ALEN-1:0] rd_data_1,
  output [`ALEN-1:0] rd_data_2
);
  logic [`MEMSZ-1:0][7:0] mem;
  
  generate
    initial begin
      if (mem_clear)
        for (integer i = 0; i < `MEMSZ; i++)
          mem[i] = '0;
      if(|memfile) begin
        $display("Preloading %m from %s", memfile);
        $readmemh(memfile, mem);
      end
    end
  endgenerate
  
  always @(posedge clk) begin
    if (wr_en[0])
      mem[wr_addr_0] <= wr_data_0[7:0];
    if (wr_en[1])
      mem[wr_addr_0 + 1] <= wr_data_0[15:8];
  end
  
  // word reads, little-endian
  assign rd_data_0 = { mem[rd_addr_0 + 1], mem[rd_addr_0] };
  assign rd_data_1 = { mem[rd_addr_1 + 1], mem[rd_addr_1] };
  assign rd_data_2 = { mem[rd_addr_2 + 1], mem[rd_addr_2] };
  
endmodule
