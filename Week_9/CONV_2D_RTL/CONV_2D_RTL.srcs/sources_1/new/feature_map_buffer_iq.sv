`timescale 1ns/1ps

module feature_map_buffer_iq #(
  parameter int DATA_W = 32
)(
  input  logic clk,
  input  logic rst_n,

  input  logic in_valid,
  input  logic signed [DATA_W-1:0] in_data,
  input  logic [1:0] channel_idx,
  input  logic [4:0] row_idx,   // wider now because row can go up to 15
  input  logic [2:0] col_idx
);

  // 4 channels × 14 rows × 6 cols
  logic signed [DATA_W-1:0] fmap [0:3][0:13][0:5];

  always_ff @(posedge clk) begin
    if (!rst_n) begin
      // no explicit reset needed for storage array
    end else begin
      if (in_valid) begin
        if ((row_idx >= 5'd2) && (row_idx <= 5'd15) &&
            (col_idx >= 3'd2) && (col_idx <= 3'd7)) begin
          fmap[channel_idx][row_idx - 5'd2][col_idx - 3'd2] <= in_data;
        end
      end
    end
  end

endmodule