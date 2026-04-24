`timescale 1ns/1ps

module tb_cnn_layer1_iq_top;

  localparam int PIX_W          = 8;
  localparam int NUM_INPUTS     = 64;
  localparam int TIMEOUT_CYCLES = 2000;

  logic clk, rst_n;
  logic in_valid;
  logic in_ready;
  logic signed [PIX_W-1:0] in_I, in_Q;

  integer idx;
  integer wait_cycles;

  integer f_win;
  integer f_conv_raw;
  integer f_conv;
  integer f_pool;

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

  // ---------------- File handles ----------------
  initial begin
    f_win      = $fopen("C:/Users/sagar/Documents/FPGA_AI_STUFF/week_11/rtl_windows.txt", "w");
    f_conv_raw = $fopen("C:/Users/sagar/Documents/FPGA_AI_STUFF/week_11/rtl_conv_raw.txt", "w");
    f_conv     = $fopen("C:/Users/sagar/Documents/FPGA_AI_STUFF/week_11/rtl_conv_out.txt", "w");
    f_pool     = $fopen("C:/Users/sagar/Documents/FPGA_AI_STUFF/week_11/rtl_out.txt", "w");

    if (f_win == 0 || f_conv_raw == 0 || f_conv == 0 || f_pool == 0) begin
      $display("ERROR: failed to open one or more output files");
      $finish;
    end
  end

  // ---------------- Stimulus ----------------
  initial begin
    rst_n       = 1'b0;
    in_valid    = 1'b0;
    in_I        = '0;
    in_Q        = '0;
    idx         = 0;
    wait_cycles = 0;

    repeat (3) @(posedge clk);
    rst_n = 1'b1;
    @(posedge clk);

    $display("\n==============================================");
    $display("Starting input stream");
    $display("==============================================");

    idx      = 0;
    in_valid = 1'b1;
    in_I     = 0;
    in_Q     = 64;

    while (idx < NUM_INPUTS) begin
      @(posedge clk);

      if (in_valid && in_ready) begin
        idx = idx + 1;

        if (idx < NUM_INPUTS) begin
          in_I = idx;
          in_Q = idx + 64;
        end else begin
          in_valid = 1'b0;
          in_I     = '0;
          in_Q     = '0;
        end
      end
    end

    $display("\n==============================================");
    $display("Finished driving inputs");
    $display("==============================================");

    repeat (TIMEOUT_CYCLES) @(posedge clk);

    $display("\n==============================================");
    $display("Simulation done");
    $display("==============================================");

    $display("\n==============================================");
    $display("Feature Map Buffer Dump");
    $display("==============================================");

    for (int ch = 0; ch < 4; ch++) begin
      $display("\nChannel %0d:", ch);
      for (int r = 0; r < 3; r++) begin
        $display("%0d %0d %0d",
                 dut.u_fmap.fmap[ch][r][0],
                 dut.u_fmap.fmap[ch][r][1],
                 dut.u_fmap.fmap[ch][r][2]);
      end
    end

    $fclose(f_win);
    $fclose(f_conv_raw);
    $fclose(f_conv);
    $fclose(f_pool);

    $finish;
  end

  // ---------------- WINDOW DEBUG ONLY ----------------
  always @(posedge clk) begin
    #1step;

    if (dut.lb_window_valid) begin
      $display("\n==============================================");
      $display("WINDOW @ t=%0t", $time);
      $display("row=%0d col=%0d", dut.lb_row_idx_i, dut.lb_col_idx_i);

      $display("---- I WINDOW ----");
      $display("%0d %0d %0d", dut.lb_win_I[0], dut.lb_win_I[1], dut.lb_win_I[2]);
      $display("%0d %0d %0d", dut.lb_win_I[3], dut.lb_win_I[4], dut.lb_win_I[5]);
      $display("%0d %0d %0d", dut.lb_win_I[6], dut.lb_win_I[7], dut.lb_win_I[8]);

      $display("---- Q WINDOW ----");
      $display("%0d %0d %0d", dut.lb_win_Q[0], dut.lb_win_Q[1], dut.lb_win_Q[2]);
      $display("%0d %0d %0d", dut.lb_win_Q[3], dut.lb_win_Q[4], dut.lb_win_Q[5]);
      $display("%0d %0d %0d", dut.lb_win_Q[6], dut.lb_win_Q[7], dut.lb_win_Q[8]);

      $display("==============================================");

      $fwrite(f_win,
        "%0d %0d  %0d %0d %0d  %0d %0d %0d  %0d %0d %0d  %0d %0d %0d  %0d %0d %0d  %0d %0d %0d\n",
        dut.lb_row_idx_i, dut.lb_col_idx_i,
        dut.lb_win_I[0], dut.lb_win_I[1], dut.lb_win_I[2],
        dut.lb_win_I[3], dut.lb_win_I[4], dut.lb_win_I[5],
        dut.lb_win_I[6], dut.lb_win_I[7], dut.lb_win_I[8],
        dut.lb_win_Q[0], dut.lb_win_Q[1], dut.lb_win_Q[2],
        dut.lb_win_Q[3], dut.lb_win_Q[4], dut.lb_win_Q[5],
        dut.lb_win_Q[6], dut.lb_win_Q[7], dut.lb_win_Q[8]
      );
    end
  end

  // ---------------- POOL OUTPUT MONITOR ----------------
  always @(posedge clk) begin
    #1step;
    if (dut.pool_valid) begin
      $display("\n*** POOL_OUT @ t=%0t ***", $time);
      $display("ch=%0d row=%0d col=%0d y=%0d",
               dut.pool_ch,
               dut.pool_row,
               dut.pool_col,
               dut.pool_y);
    end
  end

  // ---------------- RAW CONV DUMP ----------------
  always @(posedge clk) begin
    #1step;
    if (dut.conv_valid) begin
      $fwrite(f_conv_raw, "%0d %0d %0d %0d\n",
              dut.conv_ch,
              dut.conv_row_idx,
              dut.conv_col_idx,
              dut.conv_y);
    end
  end

  // ---------------- QUANTIZED CONV DUMP ----------------
  always @(posedge clk) begin
    #1step;
    if (dut.conv_valid) begin
      $fwrite(f_conv, "%0d %0d %0d %0d\n",
              dut.conv_ch,
              dut.conv_row_idx,
              dut.conv_col_idx,
              dut.quant_y);
    end
  end

  // ---------------- POOLED OUTPUT DUMP ----------------
  always @(posedge clk) begin
    #1step;
    if (dut.pool_valid) begin
      $fwrite(f_pool, "%0d %0d %0d %0d\n",
              dut.pool_ch,
              dut.pool_row,
              dut.pool_col,
              dut.pool_y);
    end
  end
  
  always @(posedge clk) begin
  #1step;
  if (dut.conv_valid) begin
    $display("RAW_CONV ch=%0d row=%0d col=%0d y=%0d",
      dut.conv_ch, dut.conv_row_idx, dut.conv_col_idx, dut.conv_y);
  end
 end

endmodule