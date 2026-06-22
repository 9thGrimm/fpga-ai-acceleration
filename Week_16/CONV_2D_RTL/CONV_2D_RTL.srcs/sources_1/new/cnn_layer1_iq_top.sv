`timescale 1ns/1ps

module cnn_layer1_iq_top #(
  parameter int PIX_W   = 8,
  parameter int W_W     = 8,
  parameter int ACC_W   = 32,
  parameter int QUANT_W = 16,
  parameter bit LB_DEBUG = 1'b0
)(
  input  logic clk,
  input  logic rst_n,

  input  logic in_valid,
  input  logic signed [PIX_W-1:0] in_I,
  input  logic signed [PIX_W-1:0] in_Q,
  output logic in_ready,

  output logic cnn_valid,
  output logic [1:0] cnn_class,
  output logic signed [ACC_W-1:0] cnn_score
);

  // ============================================================
  // Line Buffers
  // ============================================================

  logic lb_window_valid_I;
  logic lb_window_valid_Q;
  logic lb_window_valid;
  logic lb_window_ready;

  logic signed [PIX_W-1:0] lb_win_I [0:8];
  logic signed [PIX_W-1:0] lb_win_Q [0:8];

  logic [4:0] lb_row_idx_i;
  logic [4:0] lb_row_idx_q;
  logic [2:0] lb_col_idx_i;
  logic [2:0] lb_col_idx_q;

  line_buffer_3x3 #(
    .PIX_W(PIX_W),
    .DEBUG(LB_DEBUG)
  ) u_lb_I (
    .clk          (clk),
    .rst_n        (rst_n),
    .in_valid     (in_valid),
    .window_ready (lb_window_ready),
    .in_pixel     (in_I),
    .window_valid (lb_window_valid_I),
    .w            (lb_win_I),
    .row_idx      (lb_row_idx_i),
    .col_idx      (lb_col_idx_i)
  );

  line_buffer_3x3 #(
    .PIX_W(PIX_W),
    .DEBUG(LB_DEBUG)
  ) u_lb_Q (
    .clk          (clk),
    .rst_n        (rst_n),
    .in_valid     (in_valid),
    .window_ready (lb_window_ready),
    .in_pixel     (in_Q),
    .window_valid (lb_window_valid_Q),
    .w            (lb_win_Q),
    .row_idx      (lb_row_idx_q),
    .col_idx      (lb_col_idx_q)
  );

  assign lb_window_valid = lb_window_valid_I & lb_window_valid_Q;

  // ============================================================
  // Window FIFO
  // Stores full I/Q 3x3 window + row/col metadata
  // ============================================================

  localparam int FIFO_DEPTH = 64;

  logic fifo_wr_en;
  logic fifo_rd_en;
  logic fifo_full;
  logic fifo_empty;
  logic fifo_out_valid;
  logic [$clog2(FIFO_DEPTH+1)-1:0] fifo_count;

  logic signed [PIX_W-1:0] fifo_win_I [0:8];
  logic signed [PIX_W-1:0] fifo_win_Q [0:8];
  logic [4:0] fifo_row_idx;
  logic [2:0] fifo_col_idx;

  assign lb_window_ready = !fifo_full;
  assign in_ready        = !fifo_full;
  assign fifo_wr_en      = lb_window_valid && !fifo_full;

  window_fifo_iq #(
    .PIX_W(PIX_W),
    .DEPTH(FIFO_DEPTH)
  ) u_window_fifo (
    .clk        (clk),
    .rst_n      (rst_n),

    .wr_en      (fifo_wr_en),
    .wr_win_I   (lb_win_I),
    .wr_win_Q   (lb_win_Q),
    .wr_row_idx (lb_row_idx_i),
    .wr_col_idx (lb_col_idx_i),

    .rd_en      (fifo_rd_en),
    .out_valid  (fifo_out_valid),
    .rd_win_I   (fifo_win_I),
    .rd_win_Q   (fifo_win_Q),
    .rd_row_idx (fifo_row_idx),
    .rd_col_idx (fifo_col_idx),

    .full       (fifo_full),
    .empty      (fifo_empty),
    .count      (fifo_count)
  );

  // ============================================================
  // Conv Start Control
  // Conv engine is serialized across channels.
  // Start one window only when FIFO has data and conv is ready.
  // ============================================================

  logic conv_window_ready;
  logic start_window;

  assign start_window = fifo_out_valid && conv_window_ready;
  assign fifo_rd_en   = start_window;

  logic [4:0] conv_row_idx;
  logic [2:0] conv_col_idx;

  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      conv_row_idx <= '0;
      conv_col_idx <= '0;
    end else if (start_window) begin
      conv_row_idx <= fifo_row_idx;
      conv_col_idx <= fifo_col_idx;
    end
  end

  // ============================================================
  // Conv1
  // ============================================================

  logic conv_valid;
  logic signed [ACC_W-1:0] conv_y;
  logic [1:0] conv_ch;

  conv1_engine_iq #(
    .PIX_W(PIX_W),
    .W_W  (W_W),
    .ACC_W(ACC_W)
  ) u_conv1 (
    .clk          (clk),
    .rst_n        (rst_n),
    .start_window (start_window),
    .win_I        (fifo_win_I),
    .win_Q        (fifo_win_Q),
    .window_ready (conv_window_ready),
    .conv_valid   (conv_valid),
    .conv_y       (conv_y),
    .channel_idx  (conv_ch)
  );

  // ============================================================
  // ReLU
  // ============================================================

  logic signed [ACC_W-1:0] relu_y;

  relu #(
    .W(ACC_W)
  ) u_relu (
    .in_x  (conv_y),
    .out_y (relu_y)
  );

  // ============================================================
  // Quantizer
  // ============================================================

  logic signed [QUANT_W-1:0] quant_y;

  quantizer #(
    .IN_W (ACC_W),
    .OUT_W(QUANT_W)
  ) u_quant (
    .in_x  (relu_y),
    .out_y (quant_y)
  );

  // ============================================================
  // MaxPool
  // ============================================================

  logic pool_valid;
  logic signed [QUANT_W-1:0] pool_y;
  logic [1:0] pool_ch;
  logic [4:0] pool_row;
  logic [2:0] pool_col;

  maxpool_iq #(
    .DATA_W(QUANT_W)
  ) u_pool (
    .clk         (clk),
    .rst_n       (rst_n),
    .in_valid    (conv_valid),
    .in_data     (quant_y),
    .channel_idx (conv_ch),
    .row_idx     (conv_row_idx),
    .col_idx     (conv_col_idx),
    .out_valid   (pool_valid),
    .out_data    (pool_y),
    .out_channel (pool_ch),
    .out_row     (pool_row),
    .out_col     (pool_col)
  );

  // ============================================================
  // Feature Map Buffer
  // ============================================================

  logic fmap_done;
  logic signed [QUANT_W-1:0] fmap_l1 [0:3][0:2][0:2];

  feature_map_buffer_iq #(
    .DATA_W(QUANT_W)
  ) u_fmap (
    .clk         (clk),
    .rst_n       (rst_n),
    .in_valid    (pool_valid),
    .in_data     (pool_y),
    .channel_idx (pool_ch),
    .row_idx     (pool_row),
    .col_idx     (pool_col),

    .fmap_done   (fmap_done),
    .fmap        (fmap_l1)
  );

  // ============================================================
  // Layer-2 Conv Engine
  // Input:  4 channels x 3x3 Layer-1 pooled fmap
  // Output: 4 scalar filter outputs
  // ============================================================

  logic l2_done;
  logic l2_valid;
  logic signed [ACC_W-1:0] l2_out_data;
  logic [1:0] l2_out_filter;

  layer2_conv_engine #(
    .DATA_W(QUANT_W),
    .W_W   (W_W),
    .ACC_W (ACC_W)
  ) u_layer2 (
    .clk        (clk),
    .rst_n      (rst_n),
    .start      (fmap_done),
    .fmap       (fmap_l1),
    .done       (l2_done),
    .valid      (l2_valid),
    .out_data   (l2_out_data),
    .out_filter (l2_out_filter)
  );

  // ============================================================
  // Classifier Input Buffer
  // Captures Layer-2 scalar outputs before starting argmax.
  // ============================================================

  logic signed [ACC_W-1:0] l2_logits [0:3];
  logic [2:0] l2_out_count;
  logic l2_outputs_ready;
  logic classifier_start;

  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      l2_out_count     <= '0;
      l2_outputs_ready <= 1'b0;
      classifier_start <= 1'b0;

      l2_logits[0] <= '0;
      l2_logits[1] <= '0;
      l2_logits[2] <= '0;
      l2_logits[3] <= '0;
    end else begin
      classifier_start <= 1'b0;

      if (l2_valid) begin
        l2_logits[l2_out_filter] <= l2_out_data;

        if (l2_out_count == 3'd3) begin
          l2_out_count     <= '0;
          l2_outputs_ready <= 1'b1;
        end else begin
          l2_out_count <= l2_out_count + 3'd1;
        end
      end

      // One-cycle delayed start after all Layer-2 outputs are captured
      if (l2_outputs_ready) begin
        classifier_start <= 1'b1;
        l2_outputs_ready <= 1'b0;
      end
    end
  end

  // ============================================================
  // CNN Classifier
  // Final top-level CNN output:
  //   cnn_valid
  //   cnn_class
  //   cnn_score
  // ============================================================

  classifier_argmax #(
    .NUM_CLASSES(4),
    .DATA_W(ACC_W),
    .CLASS_W(2)
  ) u_classifier (
    .clk             (clk),
    .rst_n           (rst_n),

    .start           (classifier_start),
    .logits          (l2_logits),

    .valid           (cnn_valid),
    .predicted_class (cnn_class),
    .max_value       (cnn_score)
  );

endmodule