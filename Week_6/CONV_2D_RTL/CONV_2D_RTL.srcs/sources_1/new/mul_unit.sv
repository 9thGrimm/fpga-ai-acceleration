`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 02/02/2026 06:19:56 PM
// Design Name: 
// Module Name: mul_unit
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module mul_unit #(
  parameter int A_W = 8,
  parameter int B_W = 3,
  parameter int P_W = A_W + B_W
)(
  input  logic signed [A_W-1:0] a,
  input  logic signed [B_W-1:0] b,
  output logic signed [P_W-1:0] p
);

  always_comb begin
    p = a * b;
  end
endmodule
