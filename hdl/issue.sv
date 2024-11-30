module issue(
  input clk,
  input rst,
  input recovery_en,
  
  input Inst_t inst,

);  
  logic [3:0] rdy_rs1, rdy_rs2, rdy_t, rdy, valid;
  logic [3:0] 
  
  always @(posedge clk) begin
    if (rst || recovery_en) begin
      valid <= '0;
    end
    
    else begin 
    // set source ready on cdb broadcast
      for (int i = 0; i < 4; i++) begin
        for (int j = 0; j < 4; j++) begin
          if (cdb_en[j] && (cdb_tag[j] == entry[i].p_rs1)
            rdy_rs1[i] <= `TRUE;
          if (cdb_en[j] && (cdb_tag[j] == entry[i].p_rs2)
            rdy_rs2[i] <= `TRUE;
          if (t_en && (t_tag[j] == entry[i].p_t)
            rdy_t[i] <= `TRUE;
        end
        
        if (rdy_rs1[i] && rdy_rs2[i] && rdy_t[i])
          rdy[i] <= `TRUE;
          
        if (issue[i]) begin
          valid[i] <= `FALSE;
          
        end
          
      end
       
    end 
  end
  
endmodule