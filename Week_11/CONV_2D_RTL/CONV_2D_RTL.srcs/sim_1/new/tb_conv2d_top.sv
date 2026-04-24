`timescale 1ns / 1ps

module tb_conv2d_top;

  // -------------------------
  // Parameters (must match DUT)
  // -------------------------
  localparam int PIX_W = 8;
  localparam int ACC_W = 16;
  localparam string DATA_X = "C:/Users/sagar/CONV_2D_RTL/CONV_2D_RTL.srcs/sim_1/new/x_8x8.txt";
  localparam string DATA_Y = "C:/Users/sagar/CONV_2D_RTL/CONV_2D_RTL.srcs/sim_1/new/y_6x6.txt";

  // -------------------------
  // Clock & Reset
  // -------------------------
  logic clk;
  logic rst_n;

  // -------------------------
  // DUT interface
  // -------------------------
  logic start;
  logic busy;
  logic done;
  logic out_valid;
  logic signed [ACC_W-1:0] out_y;
  logic [2:0] out_row, out_col;

  // -------------------------
  // Instantiate DUT
  // -------------------------
  conv2d_8x8_3x3 dut (
    .clk(clk),
    .rst_n(rst_n),
    .start(start),
    .busy(busy),
    .done(done),
    .out_valid(out_valid),
    .out_y(out_y),
    .out_row(out_row),
    .out_col(out_col)
  );

  // -------------------------
  // Clock generation (100 MHz)
  // -------------------------
  initial clk = 0;
  always #5 clk = ~clk;

  // -------------------------
  // Golden reference storage
  // -------------------------
  integer gold [0:5][0:5];   // y_6x6.txt
  integer out_count;

  initial begin
    rst_n = 0;
    start = 0;
    out_count = 0;

    #20;
    rst_n = 1;

    // preload input image
    preload_image();

    // load golden outputs
    load_golden();

    // start convolution
    #20;
    start = 1;
    #10;
    start = 0;
  end

  // -------------------------
  // Capture & compare outputs
  // -------------------------
  always @(posedge clk) begin
    if (out_valid) begin
      if (out_y !== gold[out_row][out_col]) begin
        $display("MISMATCH at (%0d,%0d): RTL=%0d GOLD=%0d",
                 out_row, out_col, out_y, gold[out_row][out_col]);
        $fatal;
      end else begin
        $display("MATCH (%0d,%0d): %0d",
                 out_row, out_col, out_y);
      end
      out_count++;
    end

    if (done) begin
      if (out_count == 36) begin
        $display("\nPASS: All 36 outputs match Python golden model!");
      end else begin
        $display("\nFAIL: Expected 36 outputs, got %0d", out_count);
      end
      $finish;
    end
  end

  // -------------------------
  // Tasks
  // -------------------------
  task preload_image;
  integer r, c;
  integer fd;
  integer rc;
  integer tmp;
  begin
    fd = $fopen(DATA_X, "r");
    if (fd == 0) $fatal(1, "Failed to open %s", DATA_X);

    for (r = 0; r < 8; r++) begin
      for (c = 0; c < 8; c++) begin
        rc = $fscanf(fd, "%d", tmp);
        if (rc != 1) $fatal(1, "Bad/short read in %s at r=%0d c=%0d", DATA_X, r, c);
        dut.img[r][c] = tmp; // hierarchical assignment into DUT memory
      end
    end

    $fclose(fd);
    $display("Input image loaded from %s", DATA_X);
  end
endtask


task load_golden;
  integer r, c;
  integer fd;
  integer rc;
  integer tmp;
  begin
    fd = $fopen(DATA_Y, "r");
    if (fd == 0) $fatal(1, "Failed to open %s", DATA_Y);

    for (r = 0; r < 6; r++) begin
      for (c = 0; c < 6; c++) begin
        rc = $fscanf(fd, "%d", tmp);
        if (rc != 1) $fatal(1, "Bad/short read in %s at r=%0d c=%0d", DATA_Y, r, c);
        gold[r][c] = tmp;
      end
    end

    $fclose(fd);
    $display("Golden output loaded from %s", DATA_Y);
  end
endtask


endmodule
