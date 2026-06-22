`timescale 1ns/1ps

module mac9_runtime #(
  parameter int PIX_W  = 8,   //int8 format for Pixel and Weight widths
  parameter int W_W    = 8,
  parameter int PROD_W = PIX_W + W_W,
  parameter int ACC_W  = 32
)(
  input  logic signed [PIX_W-1:0] p [0:8],
  input  logic signed [W_W-1:0]   w [0:8],
  output logic signed [ACC_W-1:0] y
);

  logic signed [PROD_W-1:0] prod [0:8];

  always_comb begin
    prod[0] = p[0] * w[0];
    prod[1] = p[1] * w[1];
    prod[2] = p[2] * w[2];
    prod[3] = p[3] * w[3];
    prod[4] = p[4] * w[4];
    prod[5] = p[5] * w[5];
    prod[6] = p[6] * w[6];
    prod[7] = p[7] * w[7];
    prod[8] = p[8] * w[8];

    y =  $signed(prod[0]) + $signed(prod[1]) + $signed(prod[2])
       + $signed(prod[3]) + $signed(prod[4]) + $signed(prod[5])
       + $signed(prod[6]) + $signed(prod[7]) + $signed(prod[8]);
  end

endmodule