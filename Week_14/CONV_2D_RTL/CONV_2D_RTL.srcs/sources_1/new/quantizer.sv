`timescale 1ns/1ps

module quantizer #(
  parameter int IN_W  = 32,
  parameter int OUT_W = 16
)(
  input  logic signed [IN_W-1:0]  in_x,
  output logic signed [OUT_W-1:0] out_y
);

  localparam signed [IN_W-1:0] MAX_VAL = (1 <<< (OUT_W-1)) - 1;
  localparam signed [IN_W-1:0] MIN_VAL = -(1 <<< (OUT_W-1));

  always_comb begin
    if (in_x > MAX_VAL)
      out_y = {1'b0, {(OUT_W-1){1'b1}}};   // +32767 for OUT_W=16
    else if (in_x < MIN_VAL)
      out_y = {1'b1, {(OUT_W-1){1'b0}}};   // -32768 for OUT_W=16
    else
      out_y = in_x[OUT_W-1:0];
  end

endmodule