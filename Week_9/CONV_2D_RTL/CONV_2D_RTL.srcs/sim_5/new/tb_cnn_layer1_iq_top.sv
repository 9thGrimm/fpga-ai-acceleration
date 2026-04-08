`timescale 1ns/1ps

module tb_cnn_layer1_iq_top;

  localparam int PIX_W          = 8;
  localparam int NUM_INPUTS     = 64;
  localparam int EXP_POOL_COUNT = 36;
  localparam int TIMEOUT_MAX    = 50000;

  logic clk, rst_n;
  logic in_valid;
  logic in_ready;
  logic signed [PIX_W-1:0] in_I, in_Q;

  integer i, r, c, ch;
  integer pool_count;
  integer timeout_cycles;
  integer ch_count [0:3];

  integer conv_unknown_count;
  integer relu_unknown_count;
  integer pool_in_unknown_count;
  integer pool_out_unknown_count;
  integer pool_ch_unknown_count;

  cnn_layer1_iq_top dut (
    .clk      (clk),
    .rst_n    (rst_n),
    .in_valid (in_valid),
    .in_I     (in_I),
    .in_Q     (in_Q),
    .in_ready (in_ready)
  );

  // ---------------- Clock ----------------
  initial clk = 1'b0;
  always #5 clk = ~clk;

  // ---------------- Main stimulus ----------------
  initial begin
    rst_n = 1'b0;
    in_valid = 1'b0;
    in_I = '0;
    in_Q = '0;
    pool_count = 0;
    timeout_cycles = 0;

    conv_unknown_count     = 0;
    relu_unknown_count     = 0;
    pool_in_unknown_count  = 0;
    pool_out_unknown_count = 0;
    pool_ch_unknown_count  = 0;

    ch_count[0] = 0;
    ch_count[1] = 0;
    ch_count[2] = 0;
    ch_count[3] = 0;

    // Reset
    repeat (3) @(posedge clk);
    rst_n = 1'b1;
    @(posedge clk);

    $display("\n==============================================");
    $display("Starting input stream");
    $display("==============================================");

    // Stream exactly 64 IQ samples, honoring in_ready
    i = 0;
    in_valid = 1'b1;
    in_I = $signed(0);
    in_Q = $signed(64);

    while (i < NUM_INPUTS) begin
      @(posedge clk);

      if (in_valid && in_ready) begin
        $display("accepted input[%0d] : I=%0d Q=%0d at t=%0t",
                 i, in_I, in_Q, $time);

        i = i + 1;

        if (i < NUM_INPUTS) begin
          in_I <= $signed(i);
          in_Q <= $signed(i + 64);
        end
        else begin
          in_valid <= 1'b0;
          in_I <= '0;
          in_Q <= '0;
        end
      end
    end

    $display("\n==============================================");
    $display("Finished driving %0d input samples", NUM_INPUTS);
    $display("Waiting for pooled outputs");
    $display("==============================================");

    // Wait for outputs or timeout
    timeout_cycles = 0;
    while ((pool_count < EXP_POOL_COUNT) && (timeout_cycles < TIMEOUT_MAX)) begin
      @(posedge clk);
      timeout_cycles = timeout_cycles + 1;
    end

    // ---------------- Summary ----------------
    $display("\n==============================================");
    $display("Summary");
    $display("==============================================");
    $display("pool_count            = %0d", pool_count);
    $display("conv_unknown_count    = %0d", conv_unknown_count);
    $display("relu_unknown_count    = %0d", relu_unknown_count);
    $display("pool_in_unknown_count = %0d", pool_in_unknown_count);
    $display("pool_out_unknown_count= %0d", pool_out_unknown_count);
    $display("pool_ch_unknown_count = %0d", pool_ch_unknown_count);

    $display("\n--- Pool Channel Counts ---");
    $display("ch0 = %0d", ch_count[0]);
    $display("ch1 = %0d", ch_count[1]);
    $display("ch2 = %0d", ch_count[2]);
    $display("ch3 = %0d", ch_count[3]);

    if (timeout_cycles >= TIMEOUT_MAX && pool_count < EXP_POOL_COUNT) begin
      $display("\nFAIL: Timeout waiting for pooled outputs.");
      $display("      Observed pool_count = %0d, expected = %0d",
               pool_count, EXP_POOL_COUNT);
    end
    else if (pool_count == EXP_POOL_COUNT &&
             ch_count[0] == 9 &&
             ch_count[1] == 9 &&
             ch_count[2] == 9 &&
             ch_count[3] == 9 &&
             pool_out_unknown_count == 0 &&
             pool_ch_unknown_count == 0) begin
      $display("\nPASS: pooled output count = %0d (expected %0d)",
               pool_count, EXP_POOL_COUNT);
    end
    else begin
      $display("\nFAIL: pooled output count = %0d (expected %0d)",
               pool_count, EXP_POOL_COUNT);
    end

    // ---------------- Full Feature Map Dump ----------------
    $display("\n==============================================");
    $display("Full Feature Map Buffer Dump");
    $display("Format: fmap[channel][row][col] = value");
    $display("==============================================");

    for (ch = 0; ch < 4; ch = ch + 1) begin
      $display("\n--- CHANNEL %0d ---", ch);
      for (r = 0; r < 3; r = r + 1) begin
        for (c = 0; c < 3; c = c + 1) begin
          $write("fmap[%0d][%0d][%0d] = %0d (h=%h)   ",
                 ch, r, c,
                 dut.u_fmap.fmap[ch][r][c],
                 dut.u_fmap.fmap[ch][r][c]);
        end
        $write("\n");
      end
    end

    $display("\n==============================================");
    $display("Matrix View");
    $display("==============================================");
    for (ch = 0; ch < 4; ch = ch + 1) begin
      $display("\nChannel %0d:", ch);
      for (r = 0; r < 3; r = r + 1) begin
        $display("%0d %0d %0d",
                 dut.u_fmap.fmap[ch][r][0],
                 dut.u_fmap.fmap[ch][r][1],
                 dut.u_fmap.fmap[ch][r][2]);
      end
    end

    $finish;
  end

  // ---------------- Conv/ReLU debug monitor ----------------
  always @(posedge clk) begin
    #1step;

    if (dut.conv_valid) begin
      $display("CONV    t=%0t  ch=%0d  row=%0d col=%0d  conv_y=%0d (b=%b h=%h)  relu_y=%0d (b=%b h=%h)",
               $time,
               dut.conv_ch,
               dut.row_idx_i,
               dut.col_idx_i,
               dut.conv_y, dut.conv_y, dut.conv_y,
               dut.relu_y, dut.relu_y, dut.relu_y);

      if ($isunknown(dut.conv_y)) begin
        conv_unknown_count = conv_unknown_count + 1;
        $display("  --> WARNING: conv_y has X/Z at t=%0t", $time);
      end

      if ($isunknown(dut.relu_y)) begin
        relu_unknown_count = relu_unknown_count + 1;
        $display("  --> WARNING: relu_y has X/Z at t=%0t", $time);
      end
    end
  end

  // ---------------- Pool input debug monitor ----------------
  always @(posedge clk) begin
    #1step;

    if (dut.u_pool.in_valid) begin
      $display("POOL_IN t=%0t  ch=%0d  row=%0d col=%0d  in_data=%0d (b=%b h=%h)",
               $time,
               dut.u_pool.channel_idx,
               dut.u_pool.row_idx,
               dut.u_pool.col_idx,
               dut.u_pool.in_data,
               dut.u_pool.in_data,
               dut.u_pool.in_data);

      if ($isunknown(dut.u_pool.in_data)) begin
        pool_in_unknown_count = pool_in_unknown_count + 1;
        $display("  --> WARNING: pool input has X/Z at t=%0t", $time);
      end
    end
  end

  // ---------------- Pool output monitor ----------------
  always @(posedge clk) begin
    #1step;

    if (dut.pool_valid) begin
      $display("POOL_OUT t=%0t  idx=%0d  row=%0d col=%0d ch=%0d  y=%0d (b=%b h=%h)",
               $time,
               pool_count,
               dut.pool_row,
               dut.pool_col,
               dut.pool_ch,
               dut.pool_y,
               dut.pool_y,
               dut.pool_y);

      if ($isunknown(dut.pool_y)) begin
        pool_out_unknown_count = pool_out_unknown_count + 1;
        $display("  --> ERROR: pool_y is X/Z at t=%0t, row=%0d col=%0d ch=%0d",
                 $time, dut.pool_row, dut.pool_col, dut.pool_ch);
      end

      if ($isunknown(dut.pool_ch)) begin
        pool_ch_unknown_count = pool_ch_unknown_count + 1;
        $display("  --> ERROR: pool_ch is X/Z at t=%0t", $time);
      end
      else if (!(dut.pool_ch inside {[0:3]})) begin
        pool_ch_unknown_count = pool_ch_unknown_count + 1;
        $display("  --> ERROR: invalid pool_ch=%0d at t=%0t", dut.pool_ch, $time);
      end
      else begin
        ch_count[dut.pool_ch] = ch_count[dut.pool_ch] + 1;
      end

      pool_count = pool_count + 1;
    end
  end

endmodule