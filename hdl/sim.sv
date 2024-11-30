/*
 * ECE587 Fall 2024 Final Project
 * R.E. Lamb
 *
 * CPU top level 
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
  .clk(),
  .rst(),
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
  .clk(),
  .rst(),
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
  .clk(),
  .rst(),
  .issue_pkt(),        
  .rob_wr_en(),            
  .cdb_pkt(),        
  .recovery_en(),
  .recovery_addr(),
  .rob_rdy(),          
  .next_rob(),         
  .retire_en(),        
  .next_retire(),      
  .retire_t_en(),        
  .next_retire_t()         
);

// free list
freelist fl(
  clk(),
  rst(),
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
  .clk(),
  .rst(),
  .recovery_en(),
  .cdb_tag(),
  .cdb_en(),
  .t_tag(),
  .t_en(),
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
  .clk(),
  .rst(),
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
  .clk(),
  .reg_rd_addr(),
  .reg_wr_addr(),
  .reg_wr_data(),
  .reg_wr_en(),
  .reg_rd_data()
);

// issue - 50% - use logisim design
issue is(           
);

loadstore lsu(      - 0% - xxx
);

alu alu(            - 0% - recycle
);

branch br(         - 0% - simple
);

  
endmodule
