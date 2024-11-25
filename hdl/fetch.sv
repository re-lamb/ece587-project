/*
 * ECE587 Fall 2024 Final Project
 * R.E. Lamb
 *
 * instruction fetch unit
 */

module fetch(
  input clk,
  input rst,
  
  input br_taken,                     // back end branch/recovery
  input [`ALEN-1:0] br_addr,          // branch addr
  
  input [1:0] dec_stall,              // decode resource stalls
  
  input [1:0] bp_hit,                 // PC found in bp
  input [1:0] bp_taken,               // prediction
  input [1:0] bp_state,               // bp state bits for wb (...don't ask..)
  input [`ALEN-1:0] bp_addr,          // addr from the BTB
  
  input [1:0][`XLEN-1:0] inst,        // raw inst from mem
  
  output [1:0][`ALEN-1:0] fetch_pc,   // addr to mem/bp
  output If_id_pkt_t[1:0] if_id_pkt   // inst packet to decode
);
  
  logic [1:0][`ALEN-1:0] pc, npc;
  assign fetch_pc = pc;
  
  // next pc selection
  assign npc[0] = br_taken ? br_addr :                        // exception or branch correction
                  dec_stall[0] ? pc[0] :                      // inst0 stall
                  dec_stall[1] ? pc[1] :                      // inst1 stall
                  (bp_taken[0] || bp_taken[1]) ? bp_addr :    // branch predicted taken
                  pc + 4;                                     // else pc + 4
  assign npc[1] = npc[0] + 2;
  
  always_ff @(posedge clk) begin
    if (rst)
      pc <= { `ALEN'd2, `ALEN'd0 };
    else
      pc <= npc;
  end
  
  // register the fetch packets
  always_ff @(posedge clk) begin
    if (rst) begin
      if_id_pkt <= {'0};
  	end
    else begin
      if_id_pkt[0].pc <= pc[0]; 
      if_id_pkt[1].pc <= pc[1];
  
      if_id_pkt[0].npc <= npc[0];
      if_id_pkt[1].npc <= npc[1];
    
      if_id_pkt[0].inst = inst[0];
      if_id_pkt[1].inst = inst[1];
  
      if_id_pkt[0].valid <= !br_taken;
      if_id_pkt[1].valid <= !(br_taken || bp_taken[0]);

      if_id_pkt[0].bp_hit <= bp_hit[0];
      if_id_pkt[1].bp_hit <= bp_hit[1];
      if_id_pkt[0].bp_state <= bp_state;
      if_id_pkt[1].bp_state <= bp_state;
  	end
  end

endmodule


module tb_fetch();
  
  bit clk;
  bit rst = 1;
  
  bit br_taken;
  bit [`ALEN-1:0] br_addr;
  
  bit [1:0] dec_stall;
  
  bit [1:0] bp_hit;
  bit [1:0] bp_taken;
  bit [1:0] bp_state;
  bit [`ALEN-1:0] bp_addr;
  
  bit [1:0][`XLEN-1:0] inst;
  
  logic [1:0][`ALEN-1:0] fetch_pc;
  Ifid_pkt_t[1:0] if_id_pkt;
  
  fetch ifu(.*);
  
  initial begin
    $dumpfile("dump.vcd"); $dumpvars;
    #1 clk = ~clk; #1 rst = 0;
    #1 $display("pc:=%x, %x val=%b, %b", if_id_pkt[0].pc, if_id_pkt[1].pc, if_id_pkt[0].valid, if_id_pkt[1].valid);
    #1 clk = ~clk;
    
    
    #1 clk = ~clk; 
    #1 $display("pc:=%x, %x val=%b, %b", if_id_pkt[0].pc, if_id_pkt[1].pc, if_id_pkt[0].valid, if_id_pkt[1].valid);
    #1 clk = ~clk;
    
    #1 clk = ~clk; 
    #1 $display("pc:=%x, %x val=%b, %b", if_id_pkt[0].pc, if_id_pkt[1].pc, if_id_pkt[0].valid, if_id_pkt[1].valid); 
    #1 clk = ~clk;
    
    #1 clk = ~clk;
    #1 $display("pc:=%x, %x val=%b, %b", if_id_pkt[0].pc, if_id_pkt[1].pc, if_id_pkt[0].valid, if_id_pkt[1].valid);
    #1 clk = ~clk;
    
    #1 clk = ~clk; 
    #1 $display("pc:=%x, %x val=%b, %b", if_id_pkt[0].pc, if_id_pkt[1].pc, if_id_pkt[0].valid, if_id_pkt[1].valid); 
    #1 clk = ~clk;
    
    dec_stall[0] = 1;
    #1 clk = ~clk; 
    #1 $display("pc:=%x, %x val=%b, %b", if_id_pkt[0].pc, if_id_pkt[1].pc, if_id_pkt[0].valid, if_id_pkt[1].valid); 
    #1 clk = ~clk;
    
    dec_stall[0] = 0; dec_stall[1] = 1;
    #1 clk = ~clk; 
    #1 $display("pc:=%x, %x val=%b, %b", if_id_pkt[0].pc, if_id_pkt[1].pc, if_id_pkt[0].valid, if_id_pkt[1].valid); 
    #1 clk = ~clk;
    
    #1 clk = ~clk; 
    #1 $display("pc:=%x, %x val=%b, %b", if_id_pkt[0].pc, if_id_pkt[1].pc, if_id_pkt[0].valid, if_id_pkt[1].valid); 
    #1 clk = ~clk;
    #1 $finish;
  end

endmodule
  
