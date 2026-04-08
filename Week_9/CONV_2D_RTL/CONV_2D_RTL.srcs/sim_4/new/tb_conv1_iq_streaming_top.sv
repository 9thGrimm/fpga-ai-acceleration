`timescale 1ns/1ps

module tb_conv1_iq_streaming_top;

  localparam int PIX_W = 8;
  localparam int ACC_W = 32;

  logic clk, rst_n;
  logic in_valid;
  logic in_ready;
  logic signed [PIX_W-1:0] in_I;
  logic signed [PIX_W-1:0] in_Q;

  logic out_valid;
  logic signed [ACC_W-1:0] out_y;
  logic [1:0] channel_idx;
  logic [2:0] row_idx, col_idx;

  integer i;
  integer out_count;
  integer ch_count [0:3];

  conv1_iq_streaming_top dut (
    .clk(clk),
    .rst_n(rst_n),
    .in_valid(in_valid),
    .in_I(in_I),
    .in_Q(in_Q),
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
    in_I = '0;
    in_Q = '0;
    out_count = 0;

    ch_count[0] = 0;
    ch_count[1] = 0;
    ch_count[2] = 0;
    ch_count[3] = 0;

    #20;
    rst_n = 1;

    i = 0;
    in_valid = 1;
    in_I = $signed(0);
    in_Q = $signed(64);

    while (i < 64) begin
      @(posedge clk);
      if (in_ready) begin
        i = i + 1;
        if (i < 64) begin
          in_I = $signed(i);
          in_Q = $signed(i + 64);
        end
      end
    end

    @(posedge clk);
    in_valid = 0;
    in_I = '0;
    in_Q = '0;

    repeat (2000) @(posedge clk);

    $display("\n--- Channel Counts ---");
    $display("ch0 = %0d", ch_count[0]);
    $display("ch1 = %0d", ch_count[1]);
    $display("ch2 = %0d", ch_count[2]);
    $display("ch3 = %0d", ch_count[3]);

    if (out_count == 144 &&
        ch_count[0] == 36 &&
        ch_count[1] == 36 &&
        ch_count[2] == 36 &&
        ch_count[3] == 36) begin
      $display("\nPASS: IQ Conv1 output count = %0d (expected 144)", out_count);
    end else begin
      $display("\nFAIL: IQ Conv1 output count = %0d (expected 144)", out_count);
      $fatal;
    end

    $finish;
  end

  always @(posedge clk) begin
    if (out_valid) begin
      $display("out[%0d] row=%0d col=%0d ch=%0d y=%0d",
               out_count, row_idx, col_idx, channel_idx, out_y);
      ch_count[channel_idx] = ch_count[channel_idx] + 1;
      out_count++;
    end
  end

endmodule