module issue(
  input clk,
  input rst,
  input recovery_en,
  input [1:0] rs_en,
  input Inst_t [1:0] issue_pkt,
  input [3:0] reg_rdy,
  input [1:0] reg_rdy_t,
  input Cdb_pkt_t [3:0] cdb_pkt,
  
  output [1:0] rs_rdy,
  output [1:0][2:0] next_free,
  output [3:0][`PRW-1:0] op_rd_addr
  
);
  logic [`RSSZ-1:0] rdy_rs1, rdy_rs2, rdy_t, valid;
  logic [`RSW-1:0] next_rdy_rs1, next_rdy_rs2, next_rdy_t, next_rdy;
  Inst_t [`RSSZ-1:0] entry;
  logic [1:0][`RSW-1:0] next_issue;
  logic [1:0] issue_en; 
  
  always_comb begin
    next_issue[0] <= '0;
    next_issue[1] <= '0;
    issue_en[0]   <= '0;
    issue_en[1]   <= '0;
    
    for (int i = 0; i < `RSSZ; i++) begin
      if (valid[i] && (rdy_rs1[i] || next_rdy_rs1) && 
         (rdy_rs2[i] || next_rdy_rs2) && 
         (rdy_t[i] || next_rdy_t)) begin
        next_issue[0] <= i;
        issue_en[0] <= `TRUE;
        break;
      end
    end
    
    // TODO: test this! the coding style is dubious
    for (int i = 0; i < `RSSZ; i++) begin
      if (valid[i] && (rdy_rs1[i] || next_rdy_rs1) && 
         (rdy_rs2[i] || next_rdy_rs2) && 
         (rdy_t[i] || next_rdy_t) &&
         (next_issue[0] != i)) begin
        next_issue[1] <= i;
        issue_en[1] <= `TRUE;
        break;
      end
    end

  end
  
  // next free slot selection 
  // TODO: THIS SHOULD BE A PARAMETERIZED MODULE
  logic [1:0][`RSW-1:0] next_free_idx;
  logic [1:0][`RSSZ-1:0] bitmap;
  logic [1:0] q_rdy;
  logic [`RSSZ-1:0] set_mask, clear_mask;
  
  // set on entry, free on execute
  assign bitmap[1] = (bitmap[0] & ~(1 << next_free[0]));
  assign set_mask = (rs_en[0] ? (1 << next_free[0]) : '0) | (rs_en[1] ? (1 << next_free[1]) : '0);
  assign clear_mask = (issue_en[0] ? (1 << next_issue[0]) : '0) | (issue_en[1] ? (1 << next_issue[1]) : '0);

  always_ff @(posedge clk) begin
    if (rst || recovery_en)
      bitmap[0] <= '0;    // on reset all free
    else
      bitmap[0] <= (bitmap[0] & ~clear_mask) | set_mask;
  end

  always_comb begin
    next_free_idx[0] <= '0;
    next_free_idx[1] <= '0;
    q_rdy[0] <= '0;
    q_rdy[1] <= '0;

    for (int i = `RSSZ-1; i >= 0; i--) begin
      if (bitmap[0][i] == 1'b0) begin
        next_free_idx[0] <= i;
        q_rdy[0] <= 1'b1;
        break;
      end
    end
    
    // TODO: test this, the coding style is dubious
    for (int i = `RSSZ-1; i >= 0; i--) begin
      if (bitmap[1][i]  == 1'b0) begin
        next_free_idx[1] <= i;
        q_rdy[1] <= 1'b1;
        break;
      end
    end
  end
  
  assign rs_rdy[0] = q_rdy[0];
  assign next_free[0] = next_free_idx[0];

  // if it's the last free slot and inst0 doesn't want it, offer it to inst1
  assign rs_rdy[1] = (q_rdy[0] && !rs_en[0] && !q_rdy[1]) ? q_rdy[0] : q_rdy[1];
  assign next_free[1] = (q_rdy[0] && !rs_en[0] && !q_rdy[1]) ? next_free_idx[0] : next_free_idx[1];

  always_comb begin
    for (int i = 0; i < 4; i++) begin
      // set source ready on cdb broadcast
      for (int j = 0; j < 4; j++) begin
        if (entry[i].valid && cdb_pkt[j].en && (cdb_pkt[j].tag == entry[i].p_rs1))
          next_rdy_rs1[i] <= `TRUE;
        else
          next_rdy_rs1[i] <= rdy_rs1[i];
          
        if (entry[i].valid && cdb_pkt[j].en && (cdb_pkt[j].tag == entry[i].p_rs2))
          next_rdy_rs2[i] <= `TRUE;
        else 
          next_rdy_rs2[i] <= rdy_rs2[i];
          
        if (entry[i].valid && cdb_pkt[j].t_en && (cdb_pkt[j].t_tag == entry[i].p_t))
          next_rdy_t[i] <= `TRUE;
        else
          next_rdy_t <= rdy_t[i];
      end
    end
  end
  
  // update/remove entries
  always @(posedge clk) begin
    if (rst || recovery_en) begin
      valid   <= '0;
      entry   <= '0;
      rdy_rs1 <= '0; 
      rdy_rs2 <= '0; 
      rdy_t   <= '0;
    end
    else begin    
      rdy_rs1 <= next_rdy_rs1;
      rdy_rs2 <= next_rdy_rs2;
      rdy_t   <= next_rdy_t;
      
      // set busybit values on entry
      if (rs_en[0]) begin 
        entry[next_free[0]]   <= issue_pkt[0];
        valid[next_free[0]]   <= `TRUE;
        rdy_rs1[next_free[0]] <= reg_rdy[0];
        rdy_rs2[next_free[0]] <= reg_rdy[1];
        rdy_t[next_free[0]]   <= reg_rdy_t[0];
      end
      if (rs_en[1]) begin 
        entry[next_free[1]]   <= issue_pkt[1];
        valid[next_free[1]]   <= `TRUE;
        rdy_rs1[next_free[1]] <= reg_rdy[2];
        rdy_rs2[next_free[1]] <= reg_rdy[3];
        rdy_t[next_free[1]]   <= reg_rdy_t[1];
      end
      
      // invalidate on issue
      if (issue_en[0]) begin 
        valid[next_issue[0]]  <= `FALSE;
        rdy_rs1[next_free[0]] <= `FALSE;
        rdy_rs2[next_free[0]] <= `FALSE;
        rdy_t[next_free[0]]   <= `FALSE;
      end
      if (issue_en[1]) begin 
        valid[next_issue[1]]  <= `FALSE;
        rdy_rs1[next_free[1]] <= `FALSE;
        rdy_rs2[next_free[1]] <= `FALSE;
        rdy_t[next_free[1]]   <= `FALSE;
      end
    end
  end
  
endmodule