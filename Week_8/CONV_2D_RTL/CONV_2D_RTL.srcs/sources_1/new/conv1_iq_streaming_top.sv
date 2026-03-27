`timescale 1ns/1ps

module conv1_iq_streaming_top #(
  parameter int PIX_W = 8,
  parameter int W_W   = 8,
  parameter int ACC_W = 32
)(
  input  logic clk,
  input  logic rst_n,

  input  logic in_valid,
  input  logic signed [PIX_W-1:0] in_I,
  input  logic signed [PIX_W-1:0] in_Q,
  output logic in_ready,

  output logic out_valid,
  output logic signed [ACC_W-1:0] out_y,
  output logic [1:0] channel_idx,

  output logic [2:0] row_idx,
  output logic [2:0] col_idx
);

  logic window_valid_I, window_valid_Q;
  logic window_ready;

  logic signed [PIX_W-1:0] win_I [0:8];
  logic signed [PIX_W-1:0] win_Q [0:8];

  logic conv_valid_i;
  logic signed [ACC_W-1:0] conv_y_i;
  logic [1:0] channel_idx_i;

  logic signed [ACC_W-1:0] relu_y;

  logic [2:0] row_idx_i, col_idx_i;
  logic [2:0] row_idx_q, col_idx_q;

  line_buffer_3x3 #(
    .PIX_W(PIX_W)
  ) u_lb_I (
    .clk(clk),
    .rst_n(rst_n),
    .in_valid(in_valid),
    .window_ready(window_ready),
    .in_pixel(in_I),
    .window_valid(window_valid_I),
    .w(win_I),
    .row_idx(row_idx_i),
    .col_idx(col_idx_i)
  );

  line_buffer_3x3 #(
    .PIX_W(PIX_W)
  ) u_lb_Q (
    .clk(clk),
    .rst_n(rst_n),
    .in_valid(in_valid),
    .window_ready(window_ready),
    .in_pixel(in_Q),
    .window_valid(window_valid_Q),
    .w(win_Q),
    .row_idx(row_idx_q),
    .col_idx(col_idx_q)
  );

  conv1_engine_iq #(
    .PIX_W(PIX_W),
    .W_W(W_W),
    .ACC_W(ACC_W)
  ) u_conv1_iq (
    .clk(clk),
    .rst_n(rst_n),
    .window_valid(window_valid_I),
    .win_I(win_I),
    .win_Q(win_Q),
    .window_ready(window_ready),
    .conv_valid(conv_valid_i),
    .conv_y(conv_y_i),
    .channel_idx(channel_idx_i)
  );

  relu #(
    .W(ACC_W)
  ) u_relu (
    .in_x(conv_y_i),
    .out_y(relu_y)
  );

  always_comb begin
    in_ready    = window_ready;
    out_valid   = conv_valid_i;
    out_y       = relu_y;
    channel_idx = channel_idx_i;
    row_idx     = row_idx_i;
    col_idx     = col_idx_i;
  end

endmodule