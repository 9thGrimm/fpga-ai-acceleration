`timescale 1ns/1ps

module layer2_conv_engine #(
  parameter int DATA_W = 16,
  parameter int W_W    = 8,
  parameter int ACC_W  = 32
)(
  input  logic clk,
  input  logic rst_n,

  input  logic start,

  // fmap[channel][row][col]
  input  logic signed [DATA_W-1:0] fmap [0:3][0:2][0:2],

  output logic done,
  output logic valid,
  output logic signed [ACC_W-1:0] out_data,
  output logic [1:0] out_filter
);

  // weights[out_filter][in_channel][row][col]
  logic signed [W_W-1:0] weight [0:3][0:3][0:2][0:2];

  logic busy;
  logic [1:0] filter_idx;

  logic signed [ACC_W-1:0] acc_comb;

  integer oc, ic, r, c;

  initial begin
    // Default all weights to zero
    for (oc = 0; oc < 4; oc = oc + 1) begin
      for (ic = 0; ic < 4; ic = ic + 1) begin
        for (r = 0; r < 3; r = r + 1) begin
          for (c = 0; c < 3; c = c + 1) begin
            weight[oc][ic][r][c] = '0;
          end
        end
      end
    end

    // ----------------------------------------------------------
    // Filter 0
    // ----------------------------------------------------------
    weight[0][0][0][0] =  8'sd1; weight[0][0][0][1] =  8'sd0; weight[0][0][0][2] = -8'sd1;
    weight[0][0][1][0] =  8'sd1; weight[0][0][1][1] =  8'sd0; weight[0][0][1][2] = -8'sd1;
    weight[0][0][2][0] =  8'sd1; weight[0][0][2][1] =  8'sd0; weight[0][0][2][2] = -8'sd1;

    weight[0][2][0][0] =  8'sd1; weight[0][2][0][1] =  8'sd1; weight[0][2][0][2] =  8'sd1;
    weight[0][2][1][0] =  8'sd0; weight[0][2][1][1] =  8'sd0; weight[0][2][1][2] =  8'sd0;
    weight[0][2][2][0] = -8'sd1; weight[0][2][2][1] = -8'sd1; weight[0][2][2][2] = -8'sd1;

    weight[0][3][0][0] =  8'sd0; weight[0][3][0][1] =  8'sd0; weight[0][3][0][2] =  8'sd0;
    weight[0][3][1][0] =  8'sd0; weight[0][3][1][1] =  8'sd1; weight[0][3][1][2] =  8'sd0;
    weight[0][3][2][0] =  8'sd0; weight[0][3][2][1] =  8'sd0; weight[0][3][2][2] =  8'sd0;

    // ----------------------------------------------------------
    // Filter 1
    // ----------------------------------------------------------
    weight[1][0][0][0] = 8'sd0; weight[1][0][0][1] = 8'sd1; weight[1][0][0][2] = 8'sd0;
    weight[1][0][1][0] = 8'sd0; weight[1][0][1][1] = 8'sd1; weight[1][0][1][2] = 8'sd0;
    weight[1][0][2][0] = 8'sd0; weight[1][0][2][1] = 8'sd1; weight[1][0][2][2] = 8'sd0;

    weight[1][2][0][0] = 8'sd0; weight[1][2][0][1] = 8'sd0; weight[1][2][0][2] = 8'sd0;
    weight[1][2][1][0] = 8'sd1; weight[1][2][1][1] = 8'sd1; weight[1][2][1][2] = 8'sd1;
    weight[1][2][2][0] = 8'sd0; weight[1][2][2][1] = 8'sd0; weight[1][2][2][2] = 8'sd0;

    weight[1][3][0][0] =  8'sd1; weight[1][3][0][1] =  8'sd0; weight[1][3][0][2] = -8'sd1;
    weight[1][3][1][0] =  8'sd1; weight[1][3][1][1] =  8'sd0; weight[1][3][1][2] = -8'sd1;
    weight[1][3][2][0] =  8'sd1; weight[1][3][2][1] =  8'sd0; weight[1][3][2][2] = -8'sd1;

    // ----------------------------------------------------------
    // Filter 2: same kernel for all input channels
    // [[1,0,1], [0,1,0], [1,0,1]]
    // ----------------------------------------------------------
    for (ic = 0; ic < 4; ic = ic + 1) begin
      weight[2][ic][0][0] = 8'sd1; weight[2][ic][0][1] = 8'sd0; weight[2][ic][0][2] = 8'sd1;
      weight[2][ic][1][0] = 8'sd0; weight[2][ic][1][1] = 8'sd1; weight[2][ic][1][2] = 8'sd0;
      weight[2][ic][2][0] = 8'sd1; weight[2][ic][2][1] = 8'sd0; weight[2][ic][2][2] = 8'sd1;
    end

    // ----------------------------------------------------------
    // Filter 3
    // ----------------------------------------------------------
    // input channel 0: all +1
    for (r = 0; r < 3; r = r + 1) begin
      for (c = 0; c < 3; c = c + 1) begin
        weight[3][0][r][c] = 8'sd1;
      end
    end

    // input channel 1: all -1
    for (r = 0; r < 3; r = r + 1) begin
      for (c = 0; c < 3; c = c + 1) begin
        weight[3][1][r][c] = -8'sd1;
      end
    end

    // input channel 2: Laplacian-like
    weight[3][2][0][0] =  8'sd0; weight[3][2][0][1] =  8'sd1; weight[3][2][0][2] =  8'sd0;
    weight[3][2][1][0] =  8'sd1; weight[3][2][1][1] = -8'sd4; weight[3][2][1][2] =  8'sd1;
    weight[3][2][2][0] =  8'sd0; weight[3][2][2][1] =  8'sd1; weight[3][2][2][2] =  8'sd0;

    // input channel 3: checkerboard
    weight[3][3][0][0] =  8'sd1; weight[3][3][0][1] = -8'sd1; weight[3][3][0][2] =  8'sd1;
    weight[3][3][1][0] = -8'sd1; weight[3][3][1][1] =  8'sd1; weight[3][3][1][2] = -8'sd1;
    weight[3][3][2][0] =  8'sd1; weight[3][3][2][1] = -8'sd1; weight[3][3][2][2] =  8'sd1;
  end

  always_comb begin
    acc_comb = '0;

    for (int in_ch = 0; in_ch < 4; in_ch++) begin
      for (int rr = 0; rr < 3; rr++) begin
        for (int cc = 0; cc < 3; cc++) begin
          acc_comb += fmap[in_ch][rr][cc] * weight[filter_idx][in_ch][rr][cc];
        end
      end
    end
  end

  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      busy       <= 1'b0;
      filter_idx <= 2'd0;
      valid      <= 1'b0;
      done       <= 1'b0;
      out_data   <= '0;
      out_filter <= '0;
    end else begin
      valid <= 1'b0;
      done  <= 1'b0;

      if (start && !busy) begin
        busy       <= 1'b1;
        filter_idx <= 2'd0;
      end else if (busy) begin
        valid      <= 1'b1;
        out_data   <= acc_comb;
        out_filter <= filter_idx;

        if (filter_idx == 2'd3) begin
          busy       <= 1'b0;
          done       <= 1'b1;
          filter_idx <= 2'd0;
        end else begin
          filter_idx <= filter_idx + 2'd1;
        end
      end
    end
  end

endmodule