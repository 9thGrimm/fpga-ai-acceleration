`timescale 1ns/1ps

module maxpool_iq #(
    parameter int DATA_W = 32
)(
    input  logic clk,
    input  logic rst_n,

    input  logic in_valid,
    input  logic signed [DATA_W-1:0] in_data,
    input  logic [1:0] channel_idx,
    input  logic [4:0] row_idx,
    input  logic [2:0] col_idx,

    output logic out_valid,
    output logic signed [DATA_W-1:0] out_data,
    output logic [1:0] out_channel,
    output logic [4:0] out_row,
    output logic [2:0] out_col
);

  // Full dense 6x6 conv-map storage by channel
  logic signed [DATA_W-1:0] prev_row [0:3][0:5];
  logic signed [DATA_W-1:0] curr_row [0:3][0:5];

  integer ch, c;

  logic [4:0] conv_row;
  logic [2:0] conv_col;

  logic signed [DATA_W-1:0] a, b, c0, d, max_tmp;

  always_comb begin
    conv_row = row_idx - 5'd2;   // image-space 2..7 -> dense 0..5
    conv_col = col_idx - 3'd2;   // image-space 2..7 -> dense 0..5
  end

  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      out_valid   <= 1'b0;
      out_data    <= '0;
      out_channel <= '0;
      out_row     <= '0;
      out_col     <= '0;

      for (ch = 0; ch < 4; ch = ch + 1) begin
        for (c = 0; c < 6; c = c + 1) begin
          prev_row[ch][c] <= '0;
          curr_row[ch][c] <= '0;
        end
      end
    end else begin
      out_valid <= 1'b0;

      if (in_valid) begin
        // store current conv sample into dense current row
        if ((row_idx >= 5'd2) && (row_idx <= 5'd7) &&
            (col_idx >= 3'd2) && (col_idx <= 3'd7)) begin
          curr_row[channel_idx][conv_col] <= in_data;
        end

        // normal 2x2 stride-2 pool on dense conv coordinates
        // emit at dense odd row/odd col => pooled 3x3
        if ((row_idx >= 5'd3) && (row_idx <= 5'd7) &&
            (col_idx >= 3'd3) && (col_idx <= 3'd7) &&
            conv_row[0] && conv_col[0]) begin

          a = prev_row[channel_idx][conv_col - 3'd1];
          b = prev_row[channel_idx][conv_col];
          c0 = curr_row[channel_idx][conv_col - 3'd1];
          d = in_data;

          max_tmp = a;
          if (b  > max_tmp) max_tmp = b;
          if (c0 > max_tmp) max_tmp = c0;
          if (d  > max_tmp) max_tmp = d;

          out_valid   <= 1'b1;
          out_data    <= max_tmp;
          out_channel <= channel_idx;
          out_row     <= conv_row >> 1;   // 1,3,5 -> 0,1,2
          out_col     <= conv_col >> 1;   // 1,3,5 -> 0,1,2
        end

        // end of dense row: copy curr_row to prev_row
        if (col_idx == 3'd7) begin
          for (c = 0; c < 6; c = c + 1) begin
            prev_row[channel_idx][c] <= curr_row[channel_idx][c];
          end
          prev_row[channel_idx][5] <= in_data; // current sample is col 5
        end
      end
    end
  end

endmodule