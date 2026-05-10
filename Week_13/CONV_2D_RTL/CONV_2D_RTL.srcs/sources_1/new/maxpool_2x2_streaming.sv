`timescale 1ns/1ps

module maxpool_2x2_streaming #(
  parameter int IN_W = 16
)(
  input  logic clk,
  input  logic rst_n,

  input  logic in_valid,
  input  logic signed [IN_W-1:0] in_x,

  input  logic [2:0] row_idx,
  input  logic [2:0] col_idx,

  output logic out_valid,
  output logic signed [IN_W-1:0] out_x,

  output logic [1:0] out_row,
  output logic [1:0] out_col
);

  // Store left element at even column to compute horizontal max at odd column
  logic signed [IN_W-1:0] left_val;
  logic left_valid;

  // Buffer hmax results from the even row (3 pooled columns)
  logic signed [IN_W-1:0] buf0, buf1, buf2;

  // Derived indices/parity
  logic row_even, col_odd;
  logic [1:0] pcol;
  logic [1:0] prow;

  assign row_even = ~row_idx[0];   // even row when LSB=0
  assign col_odd  =  col_idx[0];   // odd col when LSB=1

  // pooled indices (divide by 2)
  assign pcol = col_idx[2:1];      // maps 1->0, 3->1, 5->2 (when using odd col)
  assign prow = row_idx[2:1];

  // Internal computed horizontal max
  logic signed [IN_W-1:0] hmax;
  logic signed [IN_W-1:0] vref;

  always_ff @(posedge clk) begin
    if (!rst_n) begin
      left_val   <= '0;
      left_valid <= 1'b0;

      buf0 <= '0; buf1 <= '0; buf2 <= '0;

      out_valid <= 1'b0;
      out_x     <= '0;
      out_row   <= '0;
      out_col   <= '0;
    end else begin
      out_valid <= 1'b0; // pulse when producing pooled output

      if (in_valid) begin
        // Capture left value at even columns
        if (!col_odd) begin
          left_val   <= in_x;
          left_valid <= 1'b1;
        end else begin
          // At odd column: complete the 2-wide horizontal max
          if (left_valid) hmax = (left_val > in_x) ? left_val : in_x;
          else            hmax = in_x;

          left_valid <= 1'b0;

          // Vertical pooling:
          if (row_even) begin
            // even row: store hmax into buffer
            unique case (pcol)
              2'd0: buf0 <= hmax;
              2'd1: buf1 <= hmax;
              default: buf2 <= hmax; // 2'd2
            endcase
          end else begin
            // odd row: compare with stored hmax and output
            unique case (pcol)
              2'd0: vref = buf0;
              2'd1: vref = buf1;
              default: vref = buf2;
            endcase

            out_x     <= (vref > hmax) ? vref : hmax;
            out_valid <= 1'b1;
            out_row   <= prow;
            out_col   <= pcol;
          end
        end
      end
    end
  end

endmodule