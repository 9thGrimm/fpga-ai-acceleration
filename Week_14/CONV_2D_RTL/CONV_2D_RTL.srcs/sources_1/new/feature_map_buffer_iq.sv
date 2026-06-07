`timescale 1ns/1ps

module feature_map_buffer_iq #(
  parameter int DATA_W = 16
)(
  input  logic clk,
  input  logic rst_n,

  input  logic in_valid,
  input  logic signed [DATA_W-1:0] in_data,
  input  logic [1:0] channel_idx,
  input  logic [4:0] row_idx,
  input  logic [2:0] col_idx,

  output logic fmap_done,
  output logic signed [DATA_W-1:0] fmap [0:3][0:2][0:2]
);

  logic [5:0] write_count;

  integer ch, r, c;

  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      fmap_done   <= 1'b0;
      write_count <= '0;

      for (ch = 0; ch < 4; ch = ch + 1) begin
        for (r = 0; r < 3; r = r + 1) begin
          for (c = 0; c < 3; c = c + 1) begin
            fmap[ch][r][c] <= '0;
          end
        end
      end

    end else begin
      fmap_done <= 1'b0;

      if (in_valid) begin
        if ((channel_idx <= 2'd3) && (row_idx < 5'd3) && (col_idx < 3'd3)) begin
          fmap[channel_idx][row_idx][col_idx] <= in_data;

          if (write_count == 6'd35) begin
            fmap_done   <= 1'b1;
            write_count <= '0;
          end else begin
            write_count <= write_count + 6'd1;
          end
        end
      end
    end
  end

endmodule