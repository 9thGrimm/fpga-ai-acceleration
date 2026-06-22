`timescale 1ns/1ps

module conv1_iq_streaming_top #(
  parameter int PIX_W   = 8,
  parameter int W_W     = 8,
  parameter int ACC_W   = 32,
  parameter int QUANT_W = 16
)(
  input  logic clk,
  input  logic rst_n,

  input  logic in_valid,
  input  logic signed [PIX_W-1:0] in_I,
  input  logic signed [PIX_W-1:0] in_Q,
  output logic in_ready,

  output logic out_valid,
  output logic signed [QUANT_W-1:0] out_y,
  output logic [1:0] channel_idx,

  output logic [4:0] row_idx,
  output logic [2:0] col_idx
);

  logic window_valid_I, window_valid_Q;
  logic window_valid;
  logic window_ready;

  logic signed [PIX_W-1:0] win_I [0:8];
  logic signed [PIX_W-1:0] win_Q [0:8];

  logic conv_valid_i;
  logic signed [ACC_W-1:0] conv_y_i;
  logic [1:0] channel_idx_i;

  logic signed [ACC_W-1:0]  relu_y;
  logic signed [QUANT_W-1:0] quant_y;

  logic [4:0] row_idx_i, row_idx_q;
  logic [2:0] col_idx_i, col_idx_q;

  logic out_valid_r;
  logic signed [QUANT_W-1:0] out_y_r;
  logic [1:0] channel_idx_r;
  logic [4:0] row_idx_r;
  logic [2:0] col_idx_r;

  // Optional debug/consistency check
  // In normal operation, I and Q line buffers should stay aligned
  // If you want, you can promote this to an assertion later.

  // I-channel line buffer
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

  // Q-channel line buffer
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

  // Use both valids to avoid I/Q skew issues
  assign window_valid = window_valid_I & window_valid_Q;

  // I/Q-aware Conv1 engine
  conv1_engine_iq #(
    .PIX_W(PIX_W),
    .W_W  (W_W),
    .ACC_W(ACC_W)
  ) u_conv1_iq (
    .clk(clk),
    .rst_n(rst_n),
    .window_valid(window_valid),
    .win_I(win_I),
    .win_Q(win_Q),
    .window_ready(window_ready),
    .conv_valid(conv_valid_i),
    .conv_y(conv_y_i),
    .channel_idx(channel_idx_i)
  );

  // ReLU
  relu #(
    .W(ACC_W)
  ) u_relu (
    .in_x(conv_y_i),
    .out_y(relu_y)
  );

  // Quantizer
  quantizer #(
    .IN_W (ACC_W),
    .OUT_W(QUANT_W)
  ) u_quant (
    .in_x (relu_y),
    .out_y(quant_y)
  );

  // Output pipeline register
  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      out_valid_r   <= 1'b0;
      out_y_r       <= '0;
      channel_idx_r <= '0;
      row_idx_r     <= '0;
      col_idx_r     <= '0;
    end else begin
      out_valid_r   <= conv_valid_i;
      out_y_r       <= quant_y;
      channel_idx_r <= channel_idx_i;
      row_idx_r     <= row_idx_i;
      col_idx_r     <= col_idx_i;
    end
  end

  assign out_valid   = out_valid_r;
  assign out_y       = out_y_r;
  assign channel_idx = channel_idx_r;
  assign row_idx     = row_idx_r;
  assign col_idx     = col_idx_r;
  assign in_ready    = window_ready;

  // Feature map buffer for quantized Conv1 output
  feature_map_buffer_iq #(
    .DATA_W(QUANT_W)
  ) u_fmap_iq (
    .clk(clk),
    .rst_n(rst_n),
    .in_valid(out_valid_r),
    .in_data(out_y_r),
    .channel_idx(channel_idx_r),
    .row_idx(row_idx_r),
    .col_idx(col_idx_r)
  );

endmodule