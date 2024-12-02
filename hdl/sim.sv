/*
 * ECE587 Fall 2024 Final Project
 * R.E. Lamb
 *
 * CPU top level 
 *
 */
`include "defs.svh"

module sim();
  logic clk;
  logic rst;
  
// memory - 95%
memory #(mem_clear = 0, memfile = "program.mem") mem(
  .clk(clk),
  .rd_addr_0(),
  .rd_addr_1(),
  .rd_addr_2(),
  .wr_addr_0(),
  .wr_data_0(),
  .wr_en(), 
  .rd_data_0(),
  .rd_data_1(),
  .rd_data_2()
);
  
// fetch ifu - 95% 
fetch ifu(
  .clk(clk),                       
  .rst(rst),
  .br_taken(),  
  .br_addr(),   
  .dec_stall(), 
  .bp_hit(),    
  .bp_taken(),  
  .bp_state(),  
  .bp_addr(),   
  .inst(),      
  .fetch_pc(),  
  .if_id_pkt()  
);

// add RAS?
  
// bpred bp(); - 0%

// decode - 75% - needs rob_packet/fu_select
decode id(
  .clk(clk),
  .rst(rst),
  .if_id_pkt(),           
  .rob_rdy(),             
  .next_rob(),       
  .rs_rdy(),              
  .freelist_rdy(),        
  .next_free(),      
  .freelist_t_rdy(),      
  .next_free_t(),
  .map_rd_data(),    
  .map_t_rd_data(), 
  .dec_stall(),
  .rob_wr_en(),          
  .rs_en(),              
  .freelist_en(),          
  .freelist_t_en(),
  .map_wr_en(),            
  .map_wr_data(),          
  .map_t_wr_en(),
  .map_t_wr_data(),
  .map_rd_addr(),          
  .issue_pkt()
);
  
// ROB - 60%
reorder rob(
  .clk(clk),
  .rst(rst),
  .issue_pkt(),        
  .rob_wr_en(),            
  .cdb_pkt(),
  .br_pkt(),
  .recovery_en(),
  .recovery_addr(),
  .rob_rdy(),          
  .next_rob(),         
  .retire_en(),        
  .next_retire(),      
  .retire_t_en(),        
  .next_retire_t()   
  .map_wr_en(),
  .map_wr_addr(),
  .map_wr_data(),
  .bp_addr(),
  .bp_target(),
  .bp_state(),
  .bp_wr()
);

// free list
freelist fl(
  clk(clk),
  rst(rst),
  retire_en(),
  next_retire(),
  retire_t_en(),
  next_retire_t(),
  freelist_en(),     
  freelist_t_en(),
  freelist_rdy(),    
  next_free(),    
  freelist_t_rdy(),
  next_free_t()
);

// busybit vector  
busybit bsy(
  .clk(clk),
  .rst(rst),
  .recovery_en(),
  .cdb_pkt(),
  .freelist_en(),
  .next_free(),
  .freelist_t_en(),
  .next_free_t(),
  .rd_addr(),
  .rd_addr_t(),
  .rdy(), 
  .rdy_t()
);
  
// maptable - 90% - needs rollback - controlled by rob?
maptable rmap(
  .clk(clk),
  .rst(rst),
  .map_rd_addr(),
  .map_wr_en(),
  .map_wr_data(),
  .map_t_wr_en(),
  .map_t_wr_data(),
  .map_rd_dat(),
  .map_t_rd_data()  
);

// regfile - 95%
regfile regs(
  .clk(clk),
  .reg_rd_addr(),
  .reg_wr_addr(),
  .reg_wr_data(),
  .reg_wr_en(),
  .reg_rd_data()
);

// issue - 75% - use logisim design
rs int_rs(
  .clk(clk),
  .rst(rst),
  .recovery_en(),
  .rs_en(),
  .issue_pkt(),
  .reg_rdy(),
  .reg_rdy_t(),
  .fu_rdy(),
  .cdb_pkt()
);

// int_fu - 95% - recycle
int_alu int_0(
  .clk(clk),
  .rst(rst),
  .recovery_en(),
  .issue_en(),
  .issue_inst(),
  .rd_a(),
  .rd_b(),
  .rd_t(),
  .cdb_pkt(),
  .result(),
  .result_en(),
  .result_t(),
  .result_t_en()
);

// int_fu - 95% - recycle
int_alu int_1(
  .clk(clk),
  .rst(rst),
  .recovery_en(),
  .issue_en(),
  .issue_inst(),
  .rd_a(),
  .rd_b(),
  .rd_t(),
  .cdb_pkt(),
  .result(),
  .result_en(),
  .result_t(),
  .result_t_en()
);

rs br_rs(
  .clk(clk),
  .rst(rst),
  .recovery_en(),
  .rs_en(),
  .issue_pkt(),
  .reg_rdy(),
  .reg_rdy_t(),
  .fu_rdy(),
  .cdb_pkt()
);

// branch unit - 95% - simple (...)
branch br(
  .clk(clk),
  .rst(rst),
  .recovery_en(),
  .issue_en(),
  .issue_inst(),
  .rd_a(),
  .rd_t(),
  .cdb_pkt(),
  .br_pkt(),
  .npc(),
  .result(),
  .result_en()
);

/*
// load/store unit - 0% - xxx
loadstore lsu(   
   
);
*/
  
endmodule
