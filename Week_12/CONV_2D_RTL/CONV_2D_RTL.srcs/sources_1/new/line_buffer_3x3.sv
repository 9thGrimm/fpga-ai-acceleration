`timescale 1ns/1ps

module line_buffer_3x3 #(
    parameter int PIX_W = 8
)(
   input  logic clk,
   input  logic rst_n,

   input  logic in_valid,
   input  logic window_ready,
   input  logic signed [PIX_W-1:0] in_pixel,

   output logic window_valid,
   output logic signed [PIX_W-1:0] w [0:8],

   output logic [4:0] row_idx,
   output logic [2:0] col_idx
);

  localparam int WID = 8;

  logic signed [PIX_W-1:0] lb2 [0:WID-1];
  logic signed [PIX_W-1:0] lb1 [0:WID-1];
  logic signed [PIX_W-1:0] cur [0:WID-1];

  logic [2:0] col;
  logic [4:0] row;

  integer i;

  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      col <= '0;
      row <= '0;
      row_idx <= '0;
      col_idx <= '0;
      window_valid <= 1'b0;

      for (i = 0; i < 9; i = i + 1)
        w[i] <= '0;

      for (i = 0; i < WID; i = i + 1) begin
        lb2[i] <= '0;
        lb1[i] <= '0;
        cur[i] <= '0;
      end

    end else begin
      window_valid <= 1'b0;

      if (in_valid && window_ready) begin
        $display("%m STATE row=%0d col=%0d in_pixel=%0d", row, col, in_pixel);

        if (row >= 2 && col >= 2) begin
          $display("%m NEXT_PKT row=%0d col=%0d", row, col);
          $display("  TOP  = %0d %0d %0d",
                   lb2[col - 2], lb2[col - 1], lb2[col]);
          $display("  MID  = %0d %0d %0d",
                   lb1[col - 2], lb1[col - 1], lb1[col]);
          $display("  BOT  = %0d %0d %0d",
                   cur[col - 2], cur[col - 1], in_pixel);
        end

        // Write current sample
        cur[col] <= in_pixel;

        // Correct output alignment: export current packet at current row/col
        if (row >= 2 && col >= 2) begin
          window_valid <= 1'b1;

          row_idx <= row;
          col_idx <= col;

          w[0] <= lb2[col - 2];
          w[1] <= lb2[col - 1];
          w[2] <= lb2[col];

          w[3] <= lb1[col - 2];
          w[4] <= lb1[col - 1];
          w[5] <= lb1[col];

          w[6] <= cur[col - 2];
          w[7] <= cur[col - 1];
          w[8] <= in_pixel;

          $display("%m OUT_PKT row=%0d col=%0d  w=%0d %0d %0d | %0d %0d %0d | %0d %0d %0d",
                   row, col,
                   lb2[col - 2], lb2[col - 1], lb2[col],
                   lb1[col - 2], lb1[col - 1], lb1[col],
                   cur[col - 2], cur[col - 1], in_pixel);
        end

        if (col == 3'd7) begin
          col <= 3'd0;
          row <= row + 1;

          for (i = 0; i < WID; i = i + 1) begin
            lb2[i] <= lb1[i];
            lb1[i] <= cur[i];
          end

          lb1[7] <= in_pixel;
        end else begin
          col <= col + 1;
        end
      end
    end
  end

endmodule