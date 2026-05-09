`timescale 1ns/1ps

module window_fifo_iq #(
  parameter int PIX_W = 8,
  parameter int DEPTH = 8
)(
  input  logic clk,
  input  logic rst_n,

  // Write side: from line buffer
  input  logic wr_en,
  input  logic signed [PIX_W-1:0] wr_win_I [0:8],
  input  logic signed [PIX_W-1:0] wr_win_Q [0:8],
  input  logic [4:0] wr_row_idx,
  input  logic [2:0] wr_col_idx,

  // Read side: to conv engine
  input  logic rd_en,
  output logic out_valid,
  output logic signed [PIX_W-1:0] rd_win_I [0:8],
  output logic signed [PIX_W-1:0] rd_win_Q [0:8],
  output logic [4:0] rd_row_idx,
  output logic [2:0] rd_col_idx,

  output logic full,
  output logic empty,
  output logic [$clog2(DEPTH+1)-1:0] count
);

  localparam int PTR_W = $clog2(DEPTH);

  logic [PTR_W-1:0] wr_ptr;
  logic [PTR_W-1:0] rd_ptr;

  logic signed [PIX_W-1:0] fifo_win_I [0:DEPTH-1][0:8];
  logic signed [PIX_W-1:0] fifo_win_Q [0:DEPTH-1][0:8];

  logic [4:0] fifo_row_idx [0:DEPTH-1];
  logic [2:0] fifo_col_idx [0:DEPTH-1];

  integer i;

  assign full      = (count == DEPTH);
  assign empty     = (count == 0);
  assign out_valid = !empty;

  always_comb begin
    for (int k = 0; k < 9; k++) begin
      rd_win_I[k] = fifo_win_I[rd_ptr][k];
      rd_win_Q[k] = fifo_win_Q[rd_ptr][k];
    end

    rd_row_idx = fifo_row_idx[rd_ptr];
    rd_col_idx = fifo_col_idx[rd_ptr];
  end

  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      wr_ptr <= '0;
      rd_ptr <= '0;
      count  <= '0;

      for (int d = 0; d < DEPTH; d++) begin
        fifo_row_idx[d] <= '0;
        fifo_col_idx[d] <= '0;

        for (int k = 0; k < 9; k++) begin
          fifo_win_I[d][k] <= '0;
          fifo_win_Q[d][k] <= '0;
        end
      end

    end else begin
      // Write
      if (wr_en && !full) begin
        for (i = 0; i < 9; i = i + 1) begin
          fifo_win_I[wr_ptr][i] <= wr_win_I[i];
          fifo_win_Q[wr_ptr][i] <= wr_win_Q[i];
        end

        fifo_row_idx[wr_ptr] <= wr_row_idx;
        fifo_col_idx[wr_ptr] <= wr_col_idx;

        if (wr_ptr == DEPTH-1)
          wr_ptr <= '0;
        else
          wr_ptr <= wr_ptr + 1'b1;
      end

      // Read
      if (rd_en && !empty) begin
        if (rd_ptr == DEPTH-1)
          rd_ptr <= '0;
        else
          rd_ptr <= rd_ptr + 1'b1;
      end

      // Count update
      unique case ({wr_en && !full, rd_en && !empty})
        2'b10: count <= count + 1'b1;
        2'b01: count <= count - 1'b1;
        2'b11: count <= count;
        default: count <= count;
      endcase
    end
  end

endmodule