module issue(
  input clk,
  input rst,
  input recovery_en,
  input Inst_t inst,
  input [1:0] rs_en,
  input Inst_t [1:0] issue_pkt,
  input [3:0] busy,
  input [1:0] busy_t,
  
  output [1:0] rs_rdy,
  output [1:0][2:0] next_free,
  output [3:0][`PRW-1:0] op_rd_addr,
  
);  
  logic [3:0] rdy_rs1, rdy_rs2, rdy_t, rdy, valid;
  logic [3:0] next_rdy_rs1, next_rdy_rs2, next_rdy_t, next_rdy;
  Inst_t [3:0] inst; 
  
  logic [1:0][2:0] next_free_idx;
  logic [1:0][7:0] bitmap;
  logic [1:0] rdy;
  logic [7:0] set_mask, clear_mask;
  
  assign bitmap[1] = (bitmap[0] & ~(1 << next_free[0]));
  assign set_mask = (rs_en[0] ? (1 << next_free[0]) : '0) | (rs_en[1] ? (1 << next_free[1]) : '0);
  assign clear_mask = (issue_en[0] ? (1 << next_retire[0]) : '0) | (issue_en[1] ? (1 << next_retire[1]) : '0);

  always_ff @(posedge clk) begin
    if (rst || recovery_en)
      bitmap[0] <= '0;    // on reset all free
    else
      bitmap[0] <= (bitmap[0] & ~clear_mask) | set_mask;
  end

  always_comb begin
    next_free_idx[0] <= '0;
    next_free_idx[1] <= '0;
    rdy[0] <= '0;
    rdy[1] <= '0;

    for (int i = 7; i >= 0; i--) begin
      if (bitmap[0][i] == 1'b0) begin
        next_free_idx[0] <= i;
        rdy[0] <= 1'b1;
        break;
      end
    end

    for (int i = 7; i >= 0; i--) begin
      if (bitmap[1][i]  == 1'b0) begin
        next_free_idx[1] <= i;
        rdy[1] <= 1'b1;
        break;
      end
    end
  end
  
  assign rs_rdy[0] = rdy[0];
  assign next_free[0] = next_free_idx[0];

  // if it's the last free and inst0 doesn't want it, offer it to inst1
  assign rs_rdy[1] = (rdy[0] && !rs_en[0] && !rdy[1]) ? rdy[0] : rdy[1];
  assign next_free[1] = (rdy[0] && !rs_en[0] && !rdy[1]) ? next_free_idx[0] : next_free_idx[1];

  always @(posedge clk) begin
    if (rst || recovery_en) begin
      valid <= '0;
      inst <= '0;
    end
    else begin 
      for (int i = 0; i < 4; i++) begin
        // set source ready on cdb broadcast
        for (int j = 0; j < 4; j++) begin
          if (cdb_en[j] && (cdb_tag[j] == entry[i].p_rs1)
            rdy_rs1[i] <= `TRUE;
          if (cdb_en[j] && (cdb_tag[j] == entry[i].p_rs2)
            rdy_rs2[i] <= `TRUE;
          if (t_en && (t_tag[j] == entry[i].p_t)
            rdy_t[i] <= `TRUE;
        end
      end
    
      if (rs_en[0]) begin 
        inst[next_free[0]] <= issue_pkt[0];
        valid[next_free[0]] <= `TRUE;
        
      end
      if (rs_en[1]) begin 
        inst[next_free[1]] <= issue_pkt[1];
        valid[next_free[1]] <= `TRUE;
        
      end
      
      if (issue_en[0]) begin 
        valid[next_issue[0]] <= `FALSE;
      if (issue_en[1]) begin 
        valid[next_issue[1]] <= `FALSE;
    end
  end
  
endmodule