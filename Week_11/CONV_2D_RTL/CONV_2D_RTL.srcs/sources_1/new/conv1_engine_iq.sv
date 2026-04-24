`timescale 1ns/1ps

module conv1_engine_iq #(
  parameter int PIX_W = 8,
  parameter int W_W   = 8,
  parameter int ACC_W = 32
)(
  input  logic clk,
  input  logic rst_n,

  input  logic start_window,
  input  logic signed [PIX_W-1:0] win_I [0:8],
  input  logic signed [PIX_W-1:0] win_Q [0:8],

  output logic window_ready,
  output logic conv_valid,
  output logic signed [ACC_W-1:0] conv_y,
  output logic [1:0] channel_idx
);

  logic signed [W_W-1:0] weight [0:3][0:1][0:8];

  logic signed [W_W-1:0] sel_w_I [0:8];
  logic signed [W_W-1:0] sel_w_Q [0:8];

  logic signed [PIX_W-1:0] win_I_reg [0:8];
  logic signed [PIX_W-1:0] win_Q_reg [0:8];

  logic signed [ACC_W-1:0] mac_y;
  logic mac_done;

  logic busy;
  logic start_mac;
  logic [1:0] ch;

  assign channel_idx  = ch;
  assign window_ready = !busy;

  initial begin
    // Channel 0
    weight[0][0][0] =  8'sd1;  weight[0][0][1] =  8'sd0;  weight[0][0][2] = -8'sd1;
    weight[0][0][3] =  8'sd2;  weight[0][0][4] =  8'sd0;  weight[0][0][5] = -8'sd2;
    weight[0][0][6] =  8'sd1;  weight[0][0][7] =  8'sd0;  weight[0][0][8] = -8'sd1;

    weight[0][1][0] =  8'sd1;  weight[0][1][1] =  8'sd1;  weight[0][1][2] =  8'sd1;
    weight[0][1][3] =  8'sd0;  weight[0][1][4] =  8'sd0;  weight[0][1][5] =  8'sd0;
    weight[0][1][6] = -8'sd1;  weight[0][1][7] = -8'sd1;  weight[0][1][8] = -8'sd1;

    // Channel 1
    weight[1][0][0] =  8'sd0;  weight[1][0][1] =  8'sd1;  weight[1][0][2] =  8'sd0;
    weight[1][0][3] =  8'sd1;  weight[1][0][4] = -8'sd4;  weight[1][0][5] =  8'sd1;
    weight[1][0][6] =  8'sd0;  weight[1][0][7] =  8'sd1;  weight[1][0][8] =  8'sd0;

    weight[1][1][0] = -8'sd1;  weight[1][1][1] =  8'sd0;  weight[1][1][2] =  8'sd1;
    weight[1][1][3] = -8'sd2;  weight[1][1][4] =  8'sd0;  weight[1][1][5] =  8'sd2;
    weight[1][1][6] = -8'sd1;  weight[1][1][7] =  8'sd0;  weight[1][1][8] =  8'sd1;

    // Channel 2
    weight[2][0][0] =  8'sd1;  weight[2][0][1] =  8'sd1;  weight[2][0][2] =  8'sd0;
    weight[2][0][3] =  8'sd1;  weight[2][0][4] =  8'sd0;  weight[2][0][5] = -8'sd1;
    weight[2][0][6] =  8'sd0;  weight[2][0][7] = -8'sd1;  weight[2][0][8] = -8'sd1;

    weight[2][1][0] =  8'sd0;  weight[2][1][1] =  8'sd0;  weight[2][1][2] =  8'sd1;
    weight[2][1][3] =  8'sd1;  weight[2][1][4] =  8'sd0;  weight[2][1][5] =  8'sd1;
    weight[2][1][6] = -8'sd1;  weight[2][1][7] =  8'sd0;  weight[2][1][8] =  8'sd0;

    // Channel 3
    weight[3][0][0] =  8'sd1;  weight[3][0][1] = -8'sd1;  weight[3][0][2] =  8'sd1;
    weight[3][0][3] = -8'sd1;  weight[3][0][4] =  8'sd1;  weight[3][0][5] = -8'sd1;
    weight[3][0][6] =  8'sd1;  weight[3][0][7] = -8'sd1;  weight[3][0][8] =  8'sd1;

    weight[3][1][0] =  8'sd1;  weight[3][1][1] =  8'sd0;  weight[3][1][2] =  8'sd1;
    weight[3][1][3] =  8'sd0;  weight[3][1][4] = -8'sd4;  weight[3][1][5] =  8'sd0;
    weight[3][1][6] =  8'sd1;  weight[3][1][7] =  8'sd0;  weight[3][1][8] =  8'sd1;
  end

  always_comb begin
    sel_w_I[0] = weight[ch][0][0]; sel_w_I[1] = weight[ch][0][1]; sel_w_I[2] = weight[ch][0][2];
    sel_w_I[3] = weight[ch][0][3]; sel_w_I[4] = weight[ch][0][4]; sel_w_I[5] = weight[ch][0][5];
    sel_w_I[6] = weight[ch][0][6]; sel_w_I[7] = weight[ch][0][7]; sel_w_I[8] = weight[ch][0][8];

    sel_w_Q[0] = weight[ch][1][0]; sel_w_Q[1] = weight[ch][1][1]; sel_w_Q[2] = weight[ch][1][2];
    sel_w_Q[3] = weight[ch][1][3]; sel_w_Q[4] = weight[ch][1][4]; sel_w_Q[5] = weight[ch][1][5];
    sel_w_Q[6] = weight[ch][1][6]; sel_w_Q[7] = weight[ch][1][7]; sel_w_Q[8] = weight[ch][1][8];
  end

  mac9_dual_channel #(
    .PIX_W(PIX_W),
    .W_W(W_W),
    .ACC_W(ACC_W)
  ) u_mac_dual (
    .clk(clk),
    .rst_n(rst_n),
    .start(start_mac),
    .win_I(win_I_reg),
    .win_Q(win_Q_reg),
    .w_I(sel_w_I),
    .w_Q(sel_w_Q),
    .done(mac_done),
    .y(mac_y)
  );

  always_ff @(posedge clk) begin
    if (!rst_n) begin
      busy       <= 1'b0;
      ch         <= 2'd0;
      start_mac  <= 1'b0;
      conv_valid <= 1'b0;
      conv_y     <= '0;

      win_I_reg[0] <= '0; win_I_reg[1] <= '0; win_I_reg[2] <= '0;
      win_I_reg[3] <= '0; win_I_reg[4] <= '0; win_I_reg[5] <= '0;
      win_I_reg[6] <= '0; win_I_reg[7] <= '0; win_I_reg[8] <= '0;

      win_Q_reg[0] <= '0; win_Q_reg[1] <= '0; win_Q_reg[2] <= '0;
      win_Q_reg[3] <= '0; win_Q_reg[4] <= '0; win_Q_reg[5] <= '0;
      win_Q_reg[6] <= '0; win_Q_reg[7] <= '0; win_Q_reg[8] <= '0;
    end else begin
      start_mac  <= 1'b0;
      conv_valid <= 1'b0;

      if (!busy && start_window) begin
        win_I_reg[0] <= win_I[0]; win_I_reg[1] <= win_I[1]; win_I_reg[2] <= win_I[2];
        win_I_reg[3] <= win_I[3]; win_I_reg[4] <= win_I[4]; win_I_reg[5] <= win_I[5];
        win_I_reg[6] <= win_I[6]; win_I_reg[7] <= win_I[7]; win_I_reg[8] <= win_I[8];

        win_Q_reg[0] <= win_Q[0]; win_Q_reg[1] <= win_Q[1]; win_Q_reg[2] <= win_Q[2];
        win_Q_reg[3] <= win_Q[3]; win_Q_reg[4] <= win_Q[4]; win_Q_reg[5] <= win_Q[5];
        win_Q_reg[6] <= win_Q[6]; win_Q_reg[7] <= win_Q[7]; win_Q_reg[8] <= win_Q[8];

        busy      <= 1'b1;
        ch        <= 2'd0;
        start_mac <= 1'b1;
      end else if (busy) begin
        if (mac_done) begin
          conv_y     <= mac_y;
          conv_valid <= 1'b1;

          if (ch == 2'd3) begin
            busy <= 1'b0;
            ch   <= 2'd0;
          end else begin
            ch        <= ch + 2'd1;
            start_mac <= 1'b1;
          end
        end
      end
    end
  end

endmodule