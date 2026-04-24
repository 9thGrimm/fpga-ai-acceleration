`timescale 1ns/1ps

module tb_streaming_count;

  localparam int PIX_W = 8;
  localparam int ACC_W = 16;

  // Clock & Reset
  logic clk, rst_n;

  // Input stream
  logic in_valid;
  logic signed [PIX_W-1:0] in_pixel;

  // Final pooled output
  logic out_valid;
  logic signed [ACC_W-1:0] out_y;

  // Debug coordinates
  logic [2:0] row_idx, col_idx;   // conv coords
  logic [1:0] pool_row, pool_col; // pooled coords

  integer i;
  integer out_count;

  // DUT
  conv2d_streaming_top dut (
    .clk(clk),
    .rst_n(rst_n),
    .in_valid(in_valid),
    .in_pixel(in_pixel),

    .conv_valid(),      // unused
    .conv_y(),          // unused

    .out_valid(out_valid),
    .out_y(out_y),

    .row_idx(row_idx),
    .col_idx(col_idx),

    .pool_row(pool_row),
    .pool_col(pool_col)
  );

  // 100 MHz clock
  initial clk = 0;
  always #5 clk = ~clk;

  initial begin
    rst_n     = 0;
    in_valid  = 0;
    in_pixel  = '0;
    out_count = 0;

    #20;
    rst_n = 1;

    // Start streaming 8x8 pixels (0..63)
    @(posedge clk);
    in_valid = 1;

    for (i = 0; i < 64; i++) begin
      in_pixel = $signed(i);
      @(posedge clk);
    end

    in_valid = 0;
    in_pixel = '0;

    // Wait for pipeline flush
    repeat (60) @(posedge clk);

    if (out_count == 9) begin
      $display("\n PASS: pooled out_valid count = %0d (expected 9)", out_count);
    end else begin
      $display("\n FAIL: pooled out_valid count = %0d (expected 9)", out_count);
      $fatal;
    end

    $finish;
  end

  // Count pooled outputs
  always @(posedge clk) begin
    if (out_valid) begin
      $display("pool[%0d] row=%0d col=%0d y=%0d",
               out_count,
               pool_row,
               pool_col,
               out_y);
      out_count++;
    end
  end

endmodule