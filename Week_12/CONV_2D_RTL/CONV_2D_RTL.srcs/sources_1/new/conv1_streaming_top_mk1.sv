`timescale 1ns/1ps

module conv1_streaming_top_mk1 #(
  parameter int PIX_W = 8,
  parameter int W_W   = 8,
  parameter int ACC_W = 32
)(
  input  logic clk,
  input  logic rst_n,

  input  logic in_valid,
  input  logic signed [PIX_W-1:0] in_pixel,
  output logic in_ready,

  output logic out_valid,
  output logic signed [ACC_W-1:0] out_y,
  output logic [1:0] channel_idx,

  output logic [2:0] row_idx,
  output logic [2:0] col_idx
);

  logic window_valid;
  logic window_ready;
  logic signed [PIX_W-1:0] win [0:8];

  logic conv_valid_i;
  logic signed [ACC_W-1:0] conv_y_i;
  logic [1:0] channel_idx_i;

  logic signed [ACC_W-1:0] relu_y;

  line_buffer_3x3 #(
    .PIX_W(PIX_W)
  ) u_lb (
    .clk(clk),
    .rst_n(rst_n),
    .in_valid(in_valid),
    .window_ready(window_ready),
    .in_pixel(in_pixel),
    .window_valid(window_valid),
    .w(win),
    .row_idx(row_idx),
    .col_idx(col_idx)
  );

  conv1_engine #(
    .PIX_W(PIX_W),
    .W_W(W_W),
    .ACC_W(ACC_W)
  ) u_conv1 (
    .clk(clk),
    .rst_n(rst_n),
    .window_valid(window_valid),
    .win(win),
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
  
  feature_map_buffer #(
  .DATA_W(ACC_W)
  ) u_fmap (
  .clk(clk),
  .rst_n(rst_n),
  .in_valid(out_valid),
  .in_data(out_y),
  .channel_idx(channel_idx),
  .row_idx(row_idx),
  .col_idx(col_idx)
  );
  
  logic out_valid_r;
  logic signed [ACC_W-1:0] out_y_r;
  logic [1:0] channel_idx_r;
  logic [2:0] row_idx_r, col_idx_r;
  
  always_ff @(posedge clk) begin
  if (!rst_n) begin
    out_valid_r   <= 1'b0;
    out_y_r       <= '0;
    channel_idx_r <= '0;
    row_idx_r     <= '0;
    col_idx_r     <= '0;
  end else begin
    out_valid_r   <= conv_valid_i;
    out_y_r       <= relu_y;
    channel_idx_r <= channel_idx_i;
    row_idx_r     <= row_idx;
    col_idx_r     <= col_idx;
  end
 end

  assign out_valid   = out_valid_r;
  assign out_y       = out_y_r;
  assign channel_idx = channel_idx_r;
  assign in_ready     = window_ready;

endmodule