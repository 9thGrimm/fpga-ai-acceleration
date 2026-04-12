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

  // Conv+ReLU stream (debug / intermediate)
  output logic conv_valid,
  output logic signed [ACC_W-1:0] conv_y,

  output logic out_valid,
  output logic signed [ACC_W-1:0] out_y,

  // debug: conv coordinate space
  output logic [2:0] row_idx,
  output logic [2:0] col_idx,

  // debug: pooled coordinate space (0..2)
  output logic [1:0] pool_row,
  output logic [1:0] pool_col
);

  logic window_valid;
  logic signed [PIX_W-1:0]  win [0:8];
  logic signed [ACC_W-1:0]  mac_y;
  logic signed [ACC_W-1:0]  relu_y;

  logic pool_valid;
  logic signed [ACC_W-1:0] pool_y;

  // Line buffer window generator
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

  // MAC
  mac9 #(
    .PIX_W(PIX_W),
    .W_W(W_W),
    .ACC_W(ACC_W)
  ) u_mac (
    .p(win),
    .y(mac_y)
  );

  // ReLU
  relu #(
    .W(ACC_W)
  ) u_relu (
    .in_x(mac_y),
    .out_y(relu_y)
  );

  // Expose Conv+ReLU stream (intermediate)
  always_comb begin
    conv_valid = window_valid;
    conv_y     = relu_y;
  end

  // MaxPool 2x2 stride-2 (streaming)
  maxpool_2x2_streaming #(
    .IN_W(ACC_W)
  ) u_pool (
    .clk(clk),
    .rst_n(rst_n),
    .in_valid(conv_valid),
    .in_x(conv_y),
    .row_idx(row_idx),
    .col_idx(col_idx),
    .out_valid(pool_valid),
    .out_x(pool_y),
    .out_row(pool_row),
    .out_col(pool_col)
  );

  
  always_comb begin
    out_valid = pool_valid;
    out_y     = pool_y;
  end

endmodule