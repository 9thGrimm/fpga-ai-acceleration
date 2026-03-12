`timescale 1ns/1ps

module tb_conv1_streaming_top;

  localparam int PIX_W = 8;
  localparam int ACC_W = 32;

  logic clk, rst_n;
  logic in_valid;
  logic in_ready;
  logic signed [PIX_W-1:0] in_pixel;

  logic out_valid;
  logic signed [ACC_W-1:0] out_y;
  logic [1:0] channel_idx;
  logic [2:0] row_idx, col_idx;

  integer i;
  integer out_count;

  conv1_streaming_top_mk1 dut (
    .clk(clk),
    .rst_n(rst_n),
    .in_valid(in_valid),
    .in_pixel(in_pixel),
    .in_ready(in_ready),
    .out_valid(out_valid),
    .out_y(out_y),
    .channel_idx(channel_idx),
    .row_idx(row_idx),
    .col_idx(col_idx)
  );

  initial clk = 0;
  always #5 clk = ~clk;

  initial begin
    rst_n = 0;
    in_valid = 0;
    in_pixel = '0;
    out_count = 0;

    #20;
    rst_n = 1;

    i = 0;
    in_valid = 1;
    in_pixel = $signed(0);

    while (i < 64) begin
     @(posedge clk);
     if (in_ready) begin
        i = i + 1;
        if (i < 64)
            in_pixel = $signed(i);
     end
    end

    @(posedge clk);
    in_valid = 0;
    in_pixel = '0;

    repeat (200) @(posedge clk);

    if (out_count == 144) begin
      $display("\nPASS: output count = %0d (expected 144)", out_count);
    end else begin
      $display("\nFAIL: output count = %0d (expected 144)", out_count);
      $fatal;
    end

    $finish;
  end

  always @(posedge clk) begin
    if (out_valid) begin
      $display("out[%0d] row=%0d col=%0d ch=%0d y=%0d",
               out_count, row_idx, col_idx, channel_idx, out_y);
      out_count++;
    end
  end

endmodule