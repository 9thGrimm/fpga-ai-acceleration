`timescale 1ns/1ps

module relu #(
  parameter int W = 16
)(
  input  logic signed [W-1:0] in_x,
  output logic signed [W-1:0] out_y
);

  always_comb begin
    out_y = (in_x < 0) ? '0 : in_x;
  end

endmodule