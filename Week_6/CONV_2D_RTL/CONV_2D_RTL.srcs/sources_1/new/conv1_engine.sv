`timescale 1ns/1ps

module conv1_engine #(
  parameter int PIX_W = 8,
  parameter int W_W   = 8,
  parameter int ACC_W = 32
)(
  input  logic clk,
  input  logic rst_n,

  input  logic window_valid,
  input  logic signed [PIX_W-1:0] win [0:8],

  output logic conv_valid,
  output logic signed [ACC_W-1:0] conv_y,
  output logic [1:0] channel_idx
);

  // 4 output channels
  logic signed [W_W-1:0] weight [0:3][0:8];

  // weights for MAC
  logic signed [W_W-1:0] sel_w [0:8];

  logic signed [ACC_W-1:0] mac_y;

  logic busy;
  logic [1:0] ch;

  assign channel_idx = ch;

  // Sobel-like Kernel
  initial begin
    // Channel 0
    weight[0][0] =  8'sd1;  weight[0][1] =  8'sd0;  weight[0][2] = -8'sd1;
    weight[0][3] =  8'sd2;  weight[0][4] =  8'sd0;  weight[0][5] = -8'sd2;
    weight[0][6] =  8'sd1;  weight[0][7] =  8'sd0;  weight[0][8] = -8'sd1;

    // Channel 1
    weight[1][0] =  8'sd1;  weight[1][1] =  8'sd1;  weight[1][2] =  8'sd1;
    weight[1][3] =  8'sd0;  weight[1][4] =  8'sd0;  weight[1][5] =  8'sd0;
    weight[1][6] = -8'sd1;  weight[1][7] = -8'sd1;  weight[1][8] = -8'sd1;

    // Channel 2
    weight[2][0] =  8'sd0;  weight[2][1] =  8'sd1;  weight[2][2] =  8'sd0;
    weight[2][3] =  8'sd1;  weight[2][4] = -8'sd4;  weight[2][5] =  8'sd1;
    weight[2][6] =  8'sd0;  weight[2][7] =  8'sd1;  weight[2][8] =  8'sd0;

    // Channel 3
    weight[3][0] = -8'sd1;  weight[3][1] =  8'sd0;  weight[3][2] =  8'sd1;
    weight[3][3] = -8'sd2;  weight[3][4] =  8'sd0;  weight[3][5] =  8'sd2;
    weight[3][6] = -8'sd1;  weight[3][7] =  8'sd0;  weight[3][8] =  8'sd1;
  end

  // Weights based on channel
  always_comb begin
    sel_w[0] = weight[ch][0];
    sel_w[1] = weight[ch][1];
    sel_w[2] = weight[ch][2];
    sel_w[3] = weight[ch][3];
    sel_w[4] = weight[ch][4];
    sel_w[5] = weight[ch][5];
    sel_w[6] = weight[ch][6];
    sel_w[7] = weight[ch][7];
    sel_w[8] = weight[ch][8];
  end

  // runtime-weight MAC
  mac9_runtime #(
    .PIX_W(PIX_W),
    .W_W(W_W),
    .ACC_W(ACC_W)
  ) u_mac (
    .p(win),
    .w(sel_w),
    .y(mac_y)
  );

  always_ff @(posedge clk) begin
    if (!rst_n) begin
      ch         <= 2'd0;
      busy       <= 1'b0;
      conv_valid <= 1'b0;
      conv_y     <= '0;
    end else begin
      conv_valid <= 1'b0;

      if (window_valid && !busy) begin
        // start 4-channel evaluation
        busy <= 1'b1;
        ch   <= 2'd0;
      end else if (busy) begin
        conv_y     <= mac_y;
        conv_valid <= 1'b1;

        if (ch == 2'd3) begin
          busy <= 1'b0;
          ch   <= 2'd0;
        end else begin
          ch <= ch + 2'd1;
        end
      end
    end
  end

endmodule