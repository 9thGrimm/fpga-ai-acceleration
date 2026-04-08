`timescale 1ns/1ps

module cnn_layer1_iq_top #(
  parameter int PIX_W = 8,
  parameter int W_W   = 8,
  parameter int ACC_W = 32
)(
  input  logic clk,
  input  logic rst_n,

  input  logic in_valid,
  input  logic signed [PIX_W-1:0] in_I,
  input  logic signed [PIX_W-1:0] in_Q,
  output logic in_ready
);

  // ---------- Line Buffers ----------
  logic window_valid_I, window_valid_Q;
  logic window_ready;

  logic signed [PIX_W-1:0] win_I [0:8];
  logic signed [PIX_W-1:0] win_Q [0:8];

  logic [4:0] row_idx_i, row_idx_q;
  logic [2:0] col_idx_i, col_idx_q;

  line_buffer_3x3 u_lb_I (
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

  line_buffer_3x3 u_lb_Q (
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

  assign in_ready = window_ready;

  // ---------- Conv1 ----------
  logic conv_valid;
  logic signed [ACC_W-1:0] conv_y;
  logic [1:0] conv_ch;

  conv1_engine_iq u_conv1 (
    .clk(clk),
    .rst_n(rst_n),
    .window_valid(window_valid_I),
    .win_I(win_I),
    .win_Q(win_Q),
    .window_ready(window_ready),
    .conv_valid(conv_valid),
    .conv_y(conv_y),
    .channel_idx(conv_ch)
  );

  // ---------- ReLU ----------
  logic signed [ACC_W-1:0] relu_y;

  relu u_relu (
    .in_x(conv_y),
    .out_y(relu_y)
  );

  // ---------- MaxPool ----------
  logic pool_valid;
  logic signed [ACC_W-1:0] pool_y;
  logic [1:0] pool_ch;
  logic [4:0] pool_row;
  logic [2:0] pool_col;

  maxpool_iq u_pool (
    .clk(clk),
    .rst_n(rst_n),
    .in_valid(conv_valid),
    .in_data(relu_y),
    .channel_idx(conv_ch),
    .row_idx(row_idx_i),
    .col_idx(col_idx_i),
    .out_valid(pool_valid),
    .out_data(pool_y),
    .out_channel(pool_ch),
    .out_row(pool_row),
    .out_col(pool_col)
  );

  // ---------- Feature Map Buffer ----------
  feature_map_buffer_iq u_fmap (
    .clk(clk),
    .rst_n(rst_n),
    .in_valid(pool_valid),
    .in_data(pool_y),
    .channel_idx(pool_ch),
    .row_idx(pool_row),
    .col_idx(pool_col)
  );

endmodule