`timescale 1ns/1ps

module feature_map_buffer #(
  parameter int DATA_W = 32
)(
  input  logic clk,
  input  logic rst_n,

  input  logic in_valid,
  input  logic signed [DATA_W-1:0] in_data,
  input  logic [1:0] channel_idx,
  input  logic [2:0] row_idx,
  input  logic [2:0] col_idx
);

  // 4 channels × 6 rows × 6 cols
  logic signed [DATA_W-1:0] fmap [0:3][0:5][0:5];

  always_ff @(posedge clk) begin
    if (!rst_n) begin
    end else begin
      if (in_valid) begin
        if ((row_idx >= 3'd2) && (row_idx <= 3'd7) &&
            (col_idx >= 3'd2) && (col_idx <= 3'd7)) begin
          fmap[channel_idx][row_idx - 3'd2][col_idx - 3'd2] <= in_data;
        end
      end
    end
  end

endmodule