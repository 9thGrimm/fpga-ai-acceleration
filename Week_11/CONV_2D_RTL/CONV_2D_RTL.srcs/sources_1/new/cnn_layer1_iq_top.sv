`timescale 1ns/1ps

module cnn_layer1_iq_top #(
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
  output logic in_ready
);

  logic lb_window_valid_I, lb_window_valid_Q;
  logic lb_window_valid;
  logic lb_window_ready;

  logic signed [PIX_W-1:0] lb_win_I [0:8];
  logic signed [PIX_W-1:0] lb_win_Q [0:8];

  logic [4:0] lb_row_idx_i, lb_row_idx_q;
  logic [2:0] lb_col_idx_i, lb_col_idx_q;

  line_buffer_3x3 #(.PIX_W(PIX_W)) u_lb_I (
    .clk(clk),
    .rst_n(rst_n),
    .in_valid(in_valid),
    .window_ready(lb_window_ready),
    .in_pixel(in_I),
    .window_valid(lb_window_valid_I),
    .w(lb_win_I),
    .row_idx(lb_row_idx_i),
    .col_idx(lb_col_idx_i)
  );

  line_buffer_3x3 #(.PIX_W(PIX_W)) u_lb_Q (
    .clk(clk),
    .rst_n(rst_n),
    .in_valid(in_valid),
    .window_ready(lb_window_ready),
    .in_pixel(in_Q),
    .window_valid(lb_window_valid_Q),
    .w(lb_win_Q),
    .row_idx(lb_row_idx_q),
    .col_idx(lb_col_idx_q)
  );

  assign lb_window_valid = lb_window_valid_I & lb_window_valid_Q;

  logic buf_valid;
  logic signed [PIX_W-1:0] buf_win_I [0:8];
  logic signed [PIX_W-1:0] buf_win_Q [0:8];
  logic [4:0] buf_row_idx;
  logic [2:0] buf_col_idx;

  logic conv_window_ready;
  logic consume_buf;
  logic accept_lb;
  logic start_window;

  assign lb_window_ready = (~buf_valid) && conv_window_ready;
  assign in_ready        = lb_window_ready;

  assign consume_buf  = buf_valid && conv_window_ready;
  assign accept_lb    = lb_window_valid && lb_window_ready;
  assign start_window = consume_buf;

  integer k;

  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      buf_valid   <= 1'b0;
      buf_row_idx <= '0;
      buf_col_idx <= '0;

      for (k = 0; k < 9; k = k + 1) begin
        buf_win_I[k] <= '0;
        buf_win_Q[k] <= '0;
      end
    end else begin
      case ({accept_lb, consume_buf})
        2'b00: begin
          buf_valid <= buf_valid;
        end

        2'b01: begin
          buf_valid <= 1'b0;
        end

        2'b10: begin
          buf_valid   <= 1'b1;
          buf_row_idx <= lb_row_idx_i;
          buf_col_idx <= lb_col_idx_i;

          for (k = 0; k < 9; k = k + 1) begin
            buf_win_I[k] <= lb_win_I[k];
            buf_win_Q[k] <= lb_win_Q[k];
          end
        end

        2'b11: begin
          buf_valid   <= 1'b1;
          buf_row_idx <= lb_row_idx_i;
          buf_col_idx <= lb_col_idx_i;

          for (k = 0; k < 9; k = k + 1) begin
            buf_win_I[k] <= lb_win_I[k];
            buf_win_Q[k] <= lb_win_Q[k];
          end
        end
      endcase
    end
  end

  logic [4:0] conv_row_idx;
  logic [2:0] conv_col_idx;

  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      conv_row_idx <= '0;
      conv_col_idx <= '0;
    end else if (consume_buf) begin
      conv_row_idx <= buf_row_idx;
      conv_col_idx <= buf_col_idx;
    end
  end

  logic conv_valid;
  logic signed [ACC_W-1:0] conv_y;
  logic [1:0] conv_ch;

  conv1_engine_iq #(
    .PIX_W(PIX_W),
    .W_W(W_W),
    .ACC_W(ACC_W)
  ) u_conv1 (
    .clk(clk),
    .rst_n(rst_n),
    .start_window(start_window),
    .win_I(buf_win_I),
    .win_Q(buf_win_Q),
    .window_ready(conv_window_ready),
    .conv_valid(conv_valid),
    .conv_y(conv_y),
    .channel_idx(conv_ch)
  );

  logic signed [ACC_W-1:0] relu_y;

  relu #(.W(ACC_W)) u_relu (
    .in_x(conv_y),
    .out_y(relu_y)
  );

  logic signed [QUANT_W-1:0] quant_y;

  quantizer #(
    .IN_W(ACC_W),
    .OUT_W(QUANT_W)
  ) u_quant (
    .in_x(relu_y),
    .out_y(quant_y)
  );

  logic pool_valid;
  logic signed [QUANT_W-1:0] pool_y;
  logic [1:0] pool_ch;
  logic [4:0] pool_row;
  logic [2:0] pool_col;

  maxpool_iq #(.DATA_W(QUANT_W)) u_pool (
    .clk(clk),
    .rst_n(rst_n),
    .in_valid(conv_valid),
    .in_data(quant_y),
    .channel_idx(conv_ch),
    .row_idx(conv_row_idx),
    .col_idx(conv_col_idx),
    .out_valid(pool_valid),
    .out_data(pool_y),
    .out_channel(pool_ch),
    .out_row(pool_row),
    .out_col(pool_col)
  );

  feature_map_buffer_iq #(.DATA_W(QUANT_W)) u_fmap (
    .clk(clk),
    .rst_n(rst_n),
    .in_valid(pool_valid),
    .in_data(pool_y),
    .channel_idx(pool_ch),
    .row_idx(pool_row),
    .col_idx(pool_col)
  );

endmodule