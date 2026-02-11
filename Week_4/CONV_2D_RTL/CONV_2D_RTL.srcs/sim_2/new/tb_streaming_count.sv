`timescale 1ns/1ps

module tb_streaming_count;

  localparam int PIX_W = 8;
  localparam int ACC_W = 16;

  logic clk, rst_n;
  logic in_valid;
  logic signed [PIX_W-1:0] in_pixel;

  logic out_valid;
  logic signed [ACC_W-1:0] out_y;
  logic [2:0] row_idx, col_idx;

  integer i;
  integer out_count;

  // DUT
  conv2d_streaming_top dut (
    .clk(clk),
    .rst_n(rst_n),
    .in_valid(in_valid),
    .in_pixel(in_pixel),
    .out_valid(out_valid),
    .out_y(out_y),
    .row_idx(row_idx),
    .col_idx(col_idx)
  );

  // 100 MHz clock
  initial clk = 0;
  always #5 clk = ~clk;

  initial begin
    rst_n = 0;
    in_valid = 0;
    in_pixel = '0;
    out_count = 0;

    #20;
    rst_n = 1;

    @(posedge clk);
    in_valid = 1;
    for (i = 0; i < 64; i++) begin
      in_pixel = $signed(i);  // 0..63
      @(posedge clk);
    end
    in_valid = 0;
    in_pixel = '0;

    // wait a bit for last valids
    repeat (20) @(posedge clk);

    if (out_count == 36) begin
      $display("\n PASS: out_valid count = %0d (expected 36)", out_count);
    end else begin
      $display("\n FAIL: out_valid count = %0d (expected 36)", out_count);
      $fatal;
    end

    $finish;
  end

  always @(posedge clk) begin
    if (out_valid) begin
      out_count++;
      // Optional visibility:
      $display("out[%0d] at row=%0d col=%0d y=%0d", out_count-1, row_idx, col_idx, out_y);
    end
  end

endmodule
