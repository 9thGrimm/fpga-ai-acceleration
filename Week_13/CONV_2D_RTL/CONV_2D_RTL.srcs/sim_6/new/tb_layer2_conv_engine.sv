`timescale 1ns/1ps

module tb_layer2_conv_engine;

  localparam int DATA_W = 16;
  localparam int W_W    = 8;
  localparam int ACC_W  = 32;

  logic clk;
  logic rst_n;
  logic start;

  logic signed [DATA_W-1:0] fmap [0:3][0:2][0:2];

  logic done;
  logic valid;
  logic signed [ACC_W-1:0] out_data;
  logic [1:0] out_filter;

  integer f_l2_out;
  integer pass_count;
  integer fail_count;

  logic signed [ACC_W-1:0] expected [0:3];

  // ------------------------------------------------------------
  // DUT
  // ------------------------------------------------------------
  layer2_conv_engine #(
    .DATA_W(DATA_W),
    .W_W   (W_W),
    .ACC_W (ACC_W)
  ) dut (
    .clk        (clk),
    .rst_n      (rst_n),
    .start      (start),
    .fmap       (fmap),
    .done       (done),
    .valid      (valid),
    .out_data   (out_data),
    .out_filter (out_filter)
  );

  // ------------------------------------------------------------
  // Clock
  // ------------------------------------------------------------
  initial clk = 1'b0;
  always #5 clk = ~clk;

  // ------------------------------------------------------------
  // Test
  // ------------------------------------------------------------
  initial begin
    f_l2_out = $fopen("C:/Users/sagar/Documents/FPGA_AI_STUFF/Week_13/rtl_layer2_out.txt", "w");

    if (f_l2_out == 0) begin
      $display("ERROR: failed to open rtl_layer2_out.txt");
      $finish;
    end

    pass_count = 0;
    fail_count = 0;

    expected[0] = 32'sd138;
    expected[1] = 32'sd108;
    expected[2] = 32'sd970;
    expected[3] = 32'sd474;

    rst_n = 1'b0;
    start = 1'b0;

    clear_fmap();

    repeat (3) @(posedge clk);
    rst_n = 1'b1;
    @(posedge clk);

    load_verified_layer1_fmap();

    $display("\n==============================================");
    $display("Starting Layer-2 standalone convolution test");
    $display("Expected outputs:");
    $display("filter 0 = %0d", expected[0]);
    $display("filter 1 = %0d", expected[1]);
    $display("filter 2 = %0d", expected[2]);
    $display("filter 3 = %0d", expected[3]);
    $display("==============================================");

    print_input_fmap();

    @(posedge clk);
    start = 1'b1;
    @(posedge clk);
    start = 1'b0;

    wait(done === 1'b1);
    @(posedge clk);

    $display("\n==============================================");
    $display("Layer-2 standalone test complete");
    $display("PASS count = %0d", pass_count);
    $display("FAIL count = %0d", fail_count);
    $display("==============================================");

    if (fail_count == 0 && pass_count == 4) begin
      $display("LAYER-2 RTL COMPARISON: PASS");
    end else begin
      $display("LAYER-2 RTL COMPARISON: FAIL");
    end

    $fclose(f_l2_out);

    repeat (5) @(posedge clk);
    $finish;
  end

  // ------------------------------------------------------------
  // Monitor/check output
  // ------------------------------------------------------------
  always @(posedge clk) begin
    #1step;

    if (valid) begin
      $display("L2_OUT filter=%0d value=%0d expected=%0d",
               out_filter,
               out_data,
               expected[out_filter]);

      $fwrite(f_l2_out, "%0d %0d\n", out_filter, out_data);

      if (out_data === expected[out_filter]) begin
        $display("  PASS");
        pass_count = pass_count + 1;
      end else begin
        $display("  FAIL");
        fail_count = fail_count + 1;
      end
    end
  end

  // ------------------------------------------------------------
  // Tasks
  // ------------------------------------------------------------
  task automatic clear_fmap();
    for (int ch = 0; ch < 4; ch++) begin
      for (int r = 0; r < 3; r++) begin
        for (int c = 0; c < 3; c++) begin
          fmap[ch][r][c] = '0;
        end
      end
    end
  endtask

  task automatic load_verified_layer1_fmap();
    // Channel 0
    fmap[0][0][0] = 16'sd18;
    fmap[0][0][1] = 16'sd20;
    fmap[0][0][2] = 16'sd22;

    fmap[0][1][0] = 16'sd34;
    fmap[0][1][1] = 16'sd36;
    fmap[0][1][2] = 16'sd38;

    fmap[0][2][0] = 16'sd50;
    fmap[0][2][1] = 16'sd52;
    fmap[0][2][2] = 16'sd54;

    // Channel 1
    fmap[1][0][0] = 16'sd0;
    fmap[1][0][1] = 16'sd0;
    fmap[1][0][2] = 16'sd0;

    fmap[1][1][0] = 16'sd0;
    fmap[1][1][1] = 16'sd0;
    fmap[1][1][2] = 16'sd0;

    fmap[1][2][0] = 16'sd0;
    fmap[1][2][1] = 16'sd0;
    fmap[1][2][2] = 16'sd0;

    // Channel 2
    fmap[2][0][0] = 16'sd8;
    fmap[2][0][1] = 16'sd8;
    fmap[2][0][2] = 16'sd8;

    fmap[2][1][0] = 16'sd8;
    fmap[2][1][1] = 16'sd8;
    fmap[2][1][2] = 16'sd8;

    fmap[2][2][0] = 16'sd8;
    fmap[2][2][1] = 16'sd8;
    fmap[2][2][2] = 16'sd8;

    // Channel 3
    fmap[3][0][0] = 16'sd114;
    fmap[3][0][1] = 16'sd118;
    fmap[3][0][2] = 16'sd122;

    fmap[3][1][0] = 16'sd146;
    fmap[3][1][1] = 16'sd150;
    fmap[3][1][2] = 16'sd154;

    fmap[3][2][0] = 16'sd178;
    fmap[3][2][1] = 16'sd182;
    fmap[3][2][2] = 16'sd186;
  endtask

  task automatic print_input_fmap();
    $display("\nLayer-2 input feature map:");

    for (int ch = 0; ch < 4; ch++) begin
      $display("\nChannel %0d:", ch);
      $display("%0d %0d %0d", fmap[ch][0][0], fmap[ch][0][1], fmap[ch][0][2]);
      $display("%0d %0d %0d", fmap[ch][1][0], fmap[ch][1][1], fmap[ch][1][2]);
      $display("%0d %0d %0d", fmap[ch][2][0], fmap[ch][2][1], fmap[ch][2][2]);
    end

    $display("");
  endtask

endmodule