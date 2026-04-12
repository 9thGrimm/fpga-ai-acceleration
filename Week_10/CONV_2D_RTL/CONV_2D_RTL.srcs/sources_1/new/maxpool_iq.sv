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

  // Store 6 valid conv outputs per row (for 8x8 input -> 6x6 conv map)
  logic signed [DATA_W-1:0] prev_row [0:3][0:5];
  logic signed [DATA_W-1:0] curr_row [0:3][0:5];

  integer ch, c;

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
        // Only store valid conv-map columns: conv output is 6 columns wide
        // Assuming incoming col_idx runs 2..7 for valid 3x3 windows
        if (col_idx >= 3'd2) begin
          curr_row[channel_idx][col_idx - 3'd2] <= in_data;
        end

        // Generate 2x2 maxpool output only when enough data exists
        // Need rows >= 3 and cols >= 3 to have a full 2x2 region
        if ((row_idx >= 5'd3) && (col_idx >= 3'd3)) begin
          // Pool on odd conv-map row/col boundaries
          if (row_idx[0] && col_idx[0]) begin
            logic signed [DATA_W-1:0] a, b, c0, d;
            logic signed [DATA_W-1:0] max_tmp;

            a = prev_row[channel_idx][col_idx - 3'd3];
            b = prev_row[channel_idx][col_idx - 3'd2];
            c0 = curr_row[channel_idx][col_idx - 3'd3];
            d = in_data; // current sample corresponds to curr_row[channel_idx][col_idx-2]

            max_tmp = a;
            if (b  > max_tmp) max_tmp = b;
            if (c0 > max_tmp) max_tmp = c0;
            if (d  > max_tmp) max_tmp = d;

            out_valid   <= 1'b1;
            out_data    <= max_tmp;
            out_channel <= channel_idx;
            out_row     <= (row_idx - 5'd3) >> 1;
            out_col     <= (col_idx - 3'd3) >> 1;
          end
        end

        // End of row: copy current row into previous row buffer
        if (col_idx == 3'd7) begin
          for (c = 0; c < 6; c = c + 1) begin
            prev_row[channel_idx][c] <= curr_row[channel_idx][c];
          end
        end
      end
    end
  end

endmodule