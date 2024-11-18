`default_nettype none

module sim(
    input [7:0] a,
    input [7:0] b,
    output [7:0] f
  );
  
  assign f = a + b;
endmodule
