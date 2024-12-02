/*
 * ECE587 Fall 2024 Final Project
 * R.E. Lamb
 *
 * on issue read status of 4 regs + 2 tbits
 * on execution set 4 ready bits
 *
 */
 
module busybit(
  input clk,
  input rst,
  input recovery_en,
  
  input Cdb_pkt_t [3:0] cdb_pkt,
  
  input [1:0] freelist_en,
  input [1:0][4:0] next_free,
  
  input [1:0] freelist_t_en,
  input [1:0][3:0] next_free_t,
  
  input [3:0][4:0] rd_addr,
  input [1:0][3:0] rd_addr_t,
  
  output logic [3:0] rdy, 
  output logic [1:0] rdy_t
);
  logic [31:0] bitmap, set_mask, clear_mask;
  logic [15:0] bitmap_t, set_mask_t, clear_mask_t;
  
  // functional units broadcast on writeback
  assign set_mask = (cdb_pkt[0].en ? (1 << cdb_pkt[0].tag) : '0) | 
                    (cdb_pkt[1].en ? (1 << cdb_pkt[1].tag) : '0) |
                    (cdb_pkt[2].en ? (1 << cdb_pkt[2].tag) : '0) | 
                    (cdb_pkt[3].en ? (1 << cdb_pkt[3].tag) : '0);
    
  // set register as busy on issue              
  assign clear_mask = (freelist_en[0] ? (1 << next_free[0]) : '0) | 
    				          (freelist_en[1] ? (1 << next_free[1]) : '0);

  assign set_mask_t = (cdb_pkt[0].t_en ? (1 << cdb_pkt[0].t_tag) : '0) | 
                      (cdb_pkt[1].t_en ? (1 << cdb_pkt[1].t_tag) : '0) |
                      (cdb_pkt[2].t_en ? (1 << cdb_pkt[2].t_tag) : '0) |
                      (cdb_pkt[3].t_en ? (1 << cdb_pkt[3].t_tag) : '0);
  
  assign clear_mask_t = (freelist_t_en[0] ? (1 << next_free_t[0]) : '0) |
                        (freelist_t_en[1] ? (1 << next_free_t[1]) : '0);
  
  // on reset or flush, all regs become ready (??)
  always_ff @(posedge clk) begin
    if (rst | recovery_en) begin
      bitmap   <= '1;
      bitmap_t <= '1;
    end
    else begin
      bitmap   <= (bitmap & ~clear_mask) | set_mask;
      bitmap_t <= (bitmap_t & ~clear_mask_t) | set_mask_t;
    end
  end
  
  // catch current writebacks on issue
  always_comb begin
    for (int i = 0; i < 4; i++) begin
      rdy[i] = (cdb_pkt[0].en && (cdb_pkt[0].tag == rd_addr[i])) |
               (cdb_pkt[1].en && (cdb_pkt[1].tag == rd_addr[i])) |
               (cdb_pkt[2].en && (cdb_pkt[2].tag == rd_addr[i])) |
               (cdb_pkt[2].en && (cdb_pkt[2].tag == rd_addr[i])) |
               bitmap[rd_addr[i]];
    end
    
    rdy_t[0] = (cdb_pkt[0].t_en && (cdb_pkt[0].t_tag == rd_addr_t[0])) |
               (cdb_pkt[1].t_en && (cdb_pkt[1].t_tag == rd_addr_t[0])) |
               (cdb_pkt[2].t_en && (cdb_pkt[2].t_tag == rd_addr_t[0])) |
               (cdb_pkt[2].t_en && (cdb_pkt[2].t_tag == rd_addr_t[0])) |
               bitmap_t[rd_addr[0]];
              
    rdy_t[1] = (cdb_pkt[0].t_en && (cdb_pkt[0].t_tag == rd_addr_t[1])) |
               (cdb_pkt[1].t_en && (cdb_pkt[1].t_tag == rd_addr_t[1])) |
               (cdb_pkt[2].t_en && (cdb_pkt[2].t_tag == rd_addr_t[1])) |
               (cdb_pkt[2].t_en && (cdb_pkt[2].t_tag == rd_addr_t[1])) |
               bitmap_t[rd_addr[1]];
  end
  
endmodule