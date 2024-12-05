/*
 * ECE587 Fall 2024 Final Project
 * R.E. Lamb
 *
 * ROB
 * 
 * 16-entry, 2 issue, 2 retire  
 *
 */

module reorder(
  input clk,
  input rst,
  input Inst_t [1:0] issue_pkt,           // incoming inst
  input [1:0] rob_wr_en,                  // add to rob
  
  input Cdb_pkt_t [3:0] cdb_pkt,          // execution unit completion
  input Br_pkt_t br_pkt,                  // branch unit completion
  
  output recovery_en,                     // initiate rollback
  output [`ALEN-1:0] recovery_addr,       // exc. vector or branch addr
  output [1:0] rob_rdy,                   // rob entry available
  output [1:0][`RBW-1:0] next_rob,             // rob idx
  
  output [1:0] retire_en,                 // release stale reg to free list
  output [1:0][`PRW-1:0] next_retire,     // stale p_reg
  output [1:0] retire_t_en,        
  output [1:0][3:0] next_retire_t, 

  output [1:0] map_wr_en,
  output [1:0][`ARW-1:0] map_wr_addr,
  output [1:0][`PRW-1:0] map_wr_data,
  
  output map_t_wr_en,
  output [`TRW-1:0] map_t_wr_data,
  
  output [1:0][`ALEN-1:0] bp_addr,
  output [1:0][`ALEN-1:0] bp_target,
  output [1:0][1:0] bp_state,
  output [1:0] bp_wr
);
  Inst_t [`ROBSZ-1:0] entry;
  logic [`ROBSZ-1:0] update_br;
  logic [`RBW-1:0] rob_head, rob_head_plus, rob_tail, rob_tail_plus;
  logic [`RBW-1:0] next_head, next_tail;
  logic [`RBW:0] rob_cnt, next_cnt, next_add, next_sub;
  logic [1:0] rob_ret_en;
  logic rollback, rollback_start;
  
  assign next_head = (rob_wr_en[1]) ? rob_head + 'h2 : (rob_wr_en[0]) ? rob_head + 'h1 : rob_head;
  assign next_tail = (rob_ret_en[1]) ? rob_tail + 'h2 : (rob_ret_en[0]) ? rob_tail + 'h1 : rob_tail;
  assign next_add = (rob_wr_en[1]) ? 'h2 : (rob_wr_en[0]) ? 'h1 : '0;
  assign next_sub = (rob_ret_en[1]) ? 'h2 : (rob_ret_en[0]) ? 'h1 : '0;
  assign next_cnt = rob_cnt + next_add - next_sub;
  //assign next_cnt = rob_cnt + rob_wr_en[0] + rob_wr_en[1] - rob_ret_en[0] - rob_ret_en[1]; //rob_cnt + next_add - next_sub;
  
  assign rob_rdy[0] = (rob_cnt < `ROBSZ) && !(rollback_start || rollback) ? `TRUE : `FALSE;
  assign rob_rdy[1] = ((rob_cnt + 1) < `ROBSZ) && !(rollback_start || rollback) ? `TRUE : `FALSE;
  
  assign rob_head_plus = rob_head + 'h1;
  assign rob_tail_plus = rob_tail + 'h1;
  
  assign next_rob[0] = rob_head;
  assign next_rob[1] = rob_head_plus;
  
  
  
  assign rob_ret_en[0] = (entry[rob_tail].valid && entry[rob_tail].done && !entry[rob_tail].exc);
  assign rob_ret_en[1] = (rob_ret_en[0] && entry[rob_tail_plus].valid && entry[rob_tail_plus].done && !entry[rob_tail_plus].exc);
  
  // don't delay, rollback today
  assign rollback_start = ((entry[rob_tail].valid && entry[rob_tail].exc) | (entry[rob_tail_plus].valid && entry[rob_tail_plus].exc)) ? `TRUE : `FALSE;
                          
  // TODO: placeholder 
  assign recovery_en = rollback_start;
  assign recovery_addr = (entry[rob_tail].valid && entry[rob_tail].exc) ? entry[rob_tail].npc : entry[rob_tail_plus].npc;
 
  // update the bp
  assign bp_addr[0] = entry[rob_tail].pc;
  assign bp_addr[1] = entry[rob_tail_plus].pc;
  assign bp_target[0] = entry[rob_tail].npc;
  assign bp_target[1] = entry[rob_tail_plus].npc;
  assign bp_wr[0] = (entry[rob_tail].valid && entry[rob_tail].done && update_br[rob_tail]);
  assign bp_wr[1] = (!entry[rob_tail].exc && entry[rob_tail_plus].valid && entry[rob_tail_plus].done && update_br[rob_tail_plus]);
  assign bp_state[0] = entry[rob_tail].bp_state;
  assign bp_state[1] = entry[rob_tail_plus].bp_state;
 
  // return reg to free list on retirement/rollback
  assign retire_en[0] = (rollback) ? (entry[rob_head].valid && entry[rob_head].wb) : 
                                     (rob_ret_en[0] && entry[rob_tail].wb);
  assign next_retire[0] = (rollback) ? entry[rob_head].p_rd : entry[rob_tail].rd_stale;
  
  assign retire_t_en[0] = (rollback) ? (entry[rob_head].valid && entry[rob_head].wbt) : 
                                       (rob_ret_en[0] && entry[rob_tail].wbt);
  assign next_retire_t[0] = (rollback) ? entry[rob_head].p_t : entry[rob_tail].t_stale;
  
  assign retire_en[1] = (rollback) ? (entry[rob_head_plus].valid && entry[rob_head_plus].wb) : 
                                     (rob_ret_en[1] && entry[rob_tail_plus].wb);
  assign next_retire[1] = (rollback) ? entry[rob_head_plus].p_rd : entry[rob_tail_plus].rd_stale;
  
  assign retire_t_en[1] = (rollback) ? (entry[rob_head_plus].valid && entry[rob_head_plus].wbt) :
                                       (rob_ret_en[1] && entry[rob_tail_plus].wbt);
  assign next_retire_t[1] = (rollback) ? entry[rob_head_plus].p_t : entry[rob_tail_plus].t_stale;
  
  // restore original mappings on rollback
  assign map_wr_addr[0] = entry[rob_head].rd;
  assign map_wr_addr[1] = entry[rob_head_plus].rd;
  
  assign map_wr_data[0] = entry[rob_head].rd_stale;
  assign map_wr_data[1] = entry[rob_head_plus].rd_stale;
  
  assign map_wr_en[0] = (rollback && entry[rob_head].valid && entry[rob_head].wb);
  assign map_wr_en[1] = (rollback && entry[rob_head_plus].valid && entry[rob_head_plus].wb && 
                        (entry[rob_head].rd != entry[rob_head_plus].rd));
  
  assign map_t_wr_en = rollback && ((entry[rob_head].valid && entry[rob_head].wbt) || 
                                    (entry[rob_head_plus].valid && entry[rob_head_plus].wbt));
  assign map_t_wr_data = (rollback && entry[rob_head].valid && entry[rob_head].wbt) ? entry[rob_head].t_stale : 
                                                                                      entry[rob_head_plus].t_stale;
  
  always @(posedge clk) begin
    if (rst) begin
      rob_head  <= '0;
      rob_tail  <= '0;
      rob_cnt   <= '0;
      rollback  <= '0;
      update_br <= '0;
      entry   	<= '0;
    end
    else if (entry[rob_tail].inst == EXIT | entry[rob_tail_plus].inst == EXIT) begin
      $display("exit encountered at %x", entry[rob_tail].pc);
      $finish;
    end 
    else if (rollback) begin      // rebuild state on mispredict/exception
      if (rob_cnt >= 2) begin
        entry[rob_head].valid      <= `FALSE;
        entry[rob_head_plus].valid <= `FALSE;
        update_br[rob_head]        <= `FALSE;
        update_br[rob_head_plus]   <= `FALSE;
        rob_head <= rob_head - 'h2;
        rob_cnt  <= rob_cnt - 'h2;
        if (rob_cnt == 2)
          rollback <= '0;
      end
      else if (rob_cnt > 0) begin
        entry[rob_head].valid <= `FALSE;
        update_br[rob_head]   <= `FALSE;
        rob_head <= rob_head - 'h1;
        rob_cnt  <= '0;
        rollback <= '0;
      end
    end
    else begin					// normal operation
      rob_head <= next_head;
      rob_tail <= next_tail;
      rob_cnt  <= next_cnt;
      
      // mark instructions as complete
      for (int i = 0; i < 4; i++) begin
        if (entry[cdb_pkt[i].idx].valid && cdb_pkt[i].valid) begin
          entry[cdb_pkt[i].idx].done <= `TRUE;
          entry[cdb_pkt[i].idx].exc <= cdb_pkt[i].exc;
        end
      end
      
      // if coming from the branch unit, set update flags
      if (cdb_pkt[`CDB_BR].valid) begin
        entry[cdb_pkt[`CDB_BR].idx].npc <= br_pkt.npc;
        entry[cdb_pkt[`CDB_BR].idx].bp_state <= br_pkt.next_bp;
        update_br[cdb_pkt[`CDB_BR].idx] <= br_pkt.bp_wr;
      end
        
      // add new instructions
      if (rob_wr_en[0]) 
        entry[next_rob[0]] <= issue_pkt[0];
      if (rob_wr_en[1])
        entry[next_rob[1]] <= issue_pkt[1];
        
      // retire completed
      if (rob_ret_en[0])
        entry[rob_tail].valid <= `FALSE;
      if (rob_ret_en[1])
        entry[rob_tail_plus].valid <= `FALSE;
      
      // only handle oldest exception
      if (rollback_start && !rollback)
        rollback <= `TRUE;
    end
  end
  
endmodule
