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

  output logic window_ready,
  output logic conv_valid,
  output logic signed [ACC_W-1:0] conv_y,
  output logic [1:0] channel_idx
);

  // Weight storage: 4 output channels × 9 weights
  logic signed [W_W-1:0] weight [0:3][0:8];

  // Selected weights for current channel
  logic signed [W_W-1:0] sel_w [0:8];

  // Latched copy of current window
  logic signed [PIX_W-1:0] win_reg [0:8];

  logic signed [ACC_W-1:0] mac_y;

  logic busy;
  logic [1:0] ch;

  assign channel_idx = ch;
  
  assign window_ready = !busy;

  // Example weights
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

  // Select weights for current channel
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

  // MAC with latched window
  mac9_runtime #(
    .PIX_W(PIX_W),
    .W_W(W_W),
    .ACC_W(ACC_W)
  ) u_mac (
    .p(win_reg),
    .w(sel_w),
    .y(mac_y)
  );

  always_ff @(posedge clk) begin
    if (!rst_n) begin
      busy       <= 1'b0;
      ch         <= 2'd0;
      conv_valid <= 1'b0;
      conv_y     <= '0;

      win_reg[0] <= '0; win_reg[1] <= '0; win_reg[2] <= '0;
      win_reg[3] <= '0; win_reg[4] <= '0; win_reg[5] <= '0;
      win_reg[6] <= '0; win_reg[7] <= '0; win_reg[8] <= '0;
    end else begin
      conv_valid <= 1'b0;

      if (!busy && window_valid) begin
        // Latch the incoming window once
        win_reg[0] <= win[0]; win_reg[1] <= win[1]; win_reg[2] <= win[2];
        win_reg[3] <= win[3]; win_reg[4] <= win[4]; win_reg[5] <= win[5];
        win_reg[6] <= win[6]; win_reg[7] <= win[7]; win_reg[8] <= win[8];

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