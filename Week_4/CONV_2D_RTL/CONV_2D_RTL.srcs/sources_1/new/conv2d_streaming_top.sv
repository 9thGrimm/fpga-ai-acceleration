`timescale 1ns/1ps

module conv2d_streaming_top #(
  parameter int PIX_W = 8,
  parameter int W_W   = 3,
  parameter int ACC_W = 16
)(
  input  logic clk,
  input  logic rst_n,

  input  logic in_valid,
  input  logic signed [PIX_W-1:0] in_pixel,

  output logic out_valid,
  output logic signed [ACC_W-1:0] out_y,

  // optional debug
  output logic [2:0] row_idx,
  output logic [2:0] col_idx
);

  logic window_valid;
  logic signed [PIX_W-1:0] win [0:8];
  logic signed [ACC_W-1:0] mac_y;

  line_buffer_3x3 #(
    .PIX_W(PIX_W)
  ) u_lb (
    .clk(clk),
    .rst_n(rst_n),
    .in_valid(in_valid),
    .in_pixel(in_pixel),
    .window_valid(window_valid),
    .w(win),
    .row_idx(row_idx),
    .col_idx(col_idx)
  );

  mac9 #(
    .PIX_W(PIX_W),
    .W_W(W_W),
    .ACC_W(ACC_W)
  ) u_mac (
    .p(win),
    .y(mac_y)
  );

  // Output handshake
  always_comb begin
    out_valid = window_valid;
    out_y     = mac_y;
  end

endmodule
