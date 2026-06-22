`timescale 1ns/1ps

module tb_cnn_layer12_classifier_counters;

  localparam int PIX_W          = 8;
  localparam int NUM_INPUTS     = 64;
  localparam int TIMEOUT_CYCLES = 3000;

  logic clk;
  logic rst_n;
  logic in_valid;
  logic in_ready;
  logic signed [PIX_W-1:0] in_I;
  logic signed [PIX_W-1:0] in_Q;

  integer idx;
  integer wait_cycles;

  integer f_win;
  integer f_conv_raw;
  integer f_conv;
  integer f_pool;
  integer f_l2_full;
  integer f_classifier_full;
  integer f_metrics;

  integer l2_pass_count;
  integer l2_fail_count;
  integer classifier_pass_count;
  integer classifier_fail_count;

  logic signed [31:0] expected_l2 [0:3];
  logic [1:0] expected_class;
  logic signed [31:0] expected_max_value;

  logic cnn_valid;
  logic [1:0] cnn_class;
  logic signed [31:0] cnn_score;

  // ------------------------------------------------------------
  // Metrics Counters
  // ------------------------------------------------------------
  integer cycle_count;

  integer input_accept_count;
  integer window_count;
  integer conv_output_count;
  integer pool_output_count;
  integer l2_output_count;
  integer classifier_output_count;

  integer first_input_cycle;
  integer fmap_done_cycle;
  integer first_l2_cycle;
  integer last_l2_cycle;
  integer cnn_valid_cycle;

  logic first_input_seen;
  logic fmap_done_seen;
  logic first_l2_seen;
  logic cnn_valid_seen;

  // ------------------------------------------------------------
  // DUT
  // ------------------------------------------------------------
  cnn_layer1_iq_top dut (
    .clk       (clk),
    .rst_n     (rst_n),
    .in_valid  (in_valid),
    .in_I      (in_I),
    .in_Q      (in_Q),
    .in_ready  (in_ready),
    .cnn_valid (cnn_valid),
    .cnn_class (cnn_class),
    .cnn_score (cnn_score)
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
    f_win             = $fopen("C:/Users/sagar/Documents/FPGA_AI_STUFF/Week_16/rtl_windows.txt", "w");
    f_conv_raw        = $fopen("C:/Users/sagar/Documents/FPGA_AI_STUFF/Week_16/rtl_conv_raw.txt", "w");
    f_conv            = $fopen("C:/Users/sagar/Documents/FPGA_AI_STUFF/Week_16/rtl_conv_out.txt", "w");
    f_pool            = $fopen("C:/Users/sagar/Documents/FPGA_AI_STUFF/Week_16/rtl_out.txt", "w");
    f_l2_full         = $fopen("C:/Users/sagar/Documents/FPGA_AI_STUFF/Week_16/rtl_layer2_full_pipeline_out.txt", "w");
    f_classifier_full = $fopen("C:/Users/sagar/Documents/FPGA_AI_STUFF/Week_16/rtl_classifier_full_pipeline_out.txt", "w");
    f_metrics         = $fopen("C:/Users/sagar/Documents/FPGA_AI_STUFF/Week_16/rtl_metrics.txt", "w");

    if (f_win == 0 ||
        f_conv_raw == 0 ||
        f_conv == 0 ||
        f_pool == 0 ||
        f_l2_full == 0 ||
        f_classifier_full == 0 ||
        f_metrics == 0) begin
      $display("ERROR: failed to open one or more output files");
      $finish;
    end

    expected_l2[0] = 32'sd138;
    expected_l2[1] = 32'sd108;
    expected_l2[2] = 32'sd970;
    expected_l2[3] = 32'sd474;

    expected_class     = 2'd2;
    expected_max_value = 32'sd970;

    l2_pass_count         = 0;
    l2_fail_count         = 0;
    classifier_pass_count = 0;
    classifier_fail_count = 0;

    // ----------------------------------------------------------
    // Latency Metrics initialization
    // ----------------------------------------------------------
    cycle_count = 0;

    input_accept_count      = 0;
    window_count            = 0;
    conv_output_count       = 0;
    pool_output_count       = 0;
    l2_output_count         = 0;
    classifier_output_count = 0;

    first_input_cycle = -1;
    fmap_done_cycle   = -1;
    first_l2_cycle    = -1;
    last_l2_cycle     = -1;
    cnn_valid_cycle   = -1;

    first_input_seen = 1'b0;
    fmap_done_seen   = 1'b0;
    first_l2_seen    = 1'b0;
    cnn_valid_seen   = 1'b0;

    rst_n    = 1'b0;
    in_valid = 1'b0;
    in_I     = '0;
    in_Q     = '0;
    idx      = 0;

    repeat (3) @(posedge clk);
    rst_n = 1'b1;
    @(posedge clk);

    $display("\n==============================================");
    $display("Starting Week 16 full CNN pipeline cleanup/metrics test");
    $display("Input: 8x8 I/Q stream");
    $display("Expected Layer-2 outputs:");
    $display("filter 0 = %0d", expected_l2[0]);
    $display("filter 1 = %0d", expected_l2[1]);
    $display("filter 2 = %0d", expected_l2[2]);
    $display("filter 3 = %0d", expected_l2[3]);
    $display("Expected classifier output:");
    $display("class = %0d", expected_class);
    $display("max_value = %0d", expected_max_value);
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

    wait_cycles = 0;

    while (!cnn_valid_seen && wait_cycles < TIMEOUT_CYCLES) begin
      @(posedge clk);
      wait_cycles = wait_cycles + 1;
    end

    repeat (20) @(posedge clk);

    $display("\n==============================================");
    $display("Simulation done");
    $display("==============================================");

    $display("\n==============================================");
    $display("Layer-1 Feature Map Buffer Dump");
    $display("==============================================");

    for (int ch = 0; ch < 4; ch++) begin
      $display("\nChannel %0d:", ch);
      for (int r = 0; r < 3; r++) begin
        $display("%0d %0d %0d",
                 dut.fmap_l1[ch][r][0],
                 dut.fmap_l1[ch][r][1],
                 dut.fmap_l1[ch][r][2]);
      end
    end

    $display("\n==============================================");
    $display("Layer-2 Full Pipeline Result");
    $display("PASS count = %0d", l2_pass_count);
    $display("FAIL count = %0d", l2_fail_count);
    $display("==============================================");

    if (l2_pass_count == 4 && l2_fail_count == 0) begin
      $display("FULL PIPELINE LAYER-2 COMPARISON: PASS");
    end else begin
      $display("FULL PIPELINE LAYER-2 COMPARISON: FAIL");
    end

    $display("\n==============================================");
    $display("Classifier Full Pipeline Result");
    $display("PASS count = %0d", classifier_pass_count);
    $display("FAIL count = %0d", classifier_fail_count);
    $display("==============================================");

    if (classifier_pass_count == 1 && classifier_fail_count == 0) begin
      $display("FULL PIPELINE CLASSIFIER COMPARISON: PASS");
    end else begin
      $display("FULL PIPELINE CLASSIFIER COMPARISON: FAIL");
    end

    // ----------------------------------------------------------
    // Latency Metrics summary: console
    // ----------------------------------------------------------
    $display("\n==============================================");
    $display("Pipeline Metrics");
    $display("==============================================");

    $display("Input pixels accepted      = %0d", input_accept_count);
    $display("3x3 windows generated      = %0d", window_count);
    $display("Layer-1 conv outputs       = %0d", conv_output_count);
    $display("Pooled outputs             = %0d", pool_output_count);
    $display("Layer-2 outputs            = %0d", l2_output_count);
    $display("Classifier outputs         = %0d", classifier_output_count);

    $display("");
    $display("first_input_cycle          = %0d", first_input_cycle);
    $display("fmap_done_cycle            = %0d", fmap_done_cycle);
    $display("first_l2_cycle             = %0d", first_l2_cycle);
    $display("last_l2_cycle              = %0d", last_l2_cycle);
    $display("cnn_valid_cycle            = %0d", cnn_valid_cycle);

    $display("");

    if (first_input_seen && fmap_done_seen) begin
      $display("Latency: input -> fmap_done     = %0d cycles",
               fmap_done_cycle - first_input_cycle);
    end

    if (first_input_seen && first_l2_seen) begin
      $display("Latency: input -> first L2 out  = %0d cycles",
               first_l2_cycle - first_input_cycle);
    end

    if (first_input_seen && first_l2_seen) begin
      $display("Latency: input -> last L2 out   = %0d cycles",
               last_l2_cycle - first_input_cycle);
    end

    if (first_input_seen && cnn_valid_seen) begin
      $display("Latency: input -> cnn_valid     = %0d cycles",
               cnn_valid_cycle - first_input_cycle);
    end

    if (fmap_done_seen && cnn_valid_seen) begin
      $display("Latency: fmap_done -> cnn_valid = %0d cycles",
               cnn_valid_cycle - fmap_done_cycle);
    end

    $display("==============================================");

    // ----------------------------------------------------------
    // Latency Metrics summary: file dump
    // ----------------------------------------------------------
    $fwrite(f_metrics, "Week 16 Pipeline Metrics\n");
    $fwrite(f_metrics, "========================\n\n");

    $fwrite(f_metrics, "Input pixels accepted      = %0d\n", input_accept_count);
    $fwrite(f_metrics, "3x3 windows generated      = %0d\n", window_count);
    $fwrite(f_metrics, "Layer-1 conv outputs       = %0d\n", conv_output_count);
    $fwrite(f_metrics, "Pooled outputs             = %0d\n", pool_output_count);
    $fwrite(f_metrics, "Layer-2 outputs            = %0d\n", l2_output_count);
    $fwrite(f_metrics, "Classifier outputs         = %0d\n", classifier_output_count);

    $fwrite(f_metrics, "\n");
    $fwrite(f_metrics, "first_input_cycle          = %0d\n", first_input_cycle);
    $fwrite(f_metrics, "fmap_done_cycle            = %0d\n", fmap_done_cycle);
    $fwrite(f_metrics, "first_l2_cycle             = %0d\n", first_l2_cycle);
    $fwrite(f_metrics, "last_l2_cycle              = %0d\n", last_l2_cycle);
    $fwrite(f_metrics, "cnn_valid_cycle            = %0d\n", cnn_valid_cycle);

    $fwrite(f_metrics, "\n");

    if (first_input_seen && fmap_done_seen) begin
      $fwrite(f_metrics, "Latency: input -> fmap_done     = %0d cycles\n",
              fmap_done_cycle - first_input_cycle);
    end

    if (first_input_seen && first_l2_seen) begin
      $fwrite(f_metrics, "Latency: input -> first L2 out  = %0d cycles\n",
              first_l2_cycle - first_input_cycle);
    end

    if (first_input_seen && first_l2_seen) begin
      $fwrite(f_metrics, "Latency: input -> last L2 out   = %0d cycles\n",
              last_l2_cycle - first_input_cycle);
    end

    if (first_input_seen && cnn_valid_seen) begin
      $fwrite(f_metrics, "Latency: input -> cnn_valid     = %0d cycles\n",
              cnn_valid_cycle - first_input_cycle);
    end

    if (fmap_done_seen && cnn_valid_seen) begin
      $fwrite(f_metrics, "Latency: fmap_done -> cnn_valid = %0d cycles\n",
              cnn_valid_cycle - fmap_done_cycle);
    end

    $fclose(f_win);
    $fclose(f_conv_raw);
    $fclose(f_conv);
    $fclose(f_pool);
    $fclose(f_l2_full);
    $fclose(f_classifier_full);
    $fclose(f_metrics);

    $finish;
  end

  // ------------------------------------------------------------
  // Metrics monitor
  // ------------------------------------------------------------
  always @(posedge clk) begin
    #1step;

    if (!rst_n) begin
      cycle_count = 0;
    end else begin
      cycle_count = cycle_count + 1;

      if (in_valid && in_ready) begin
        input_accept_count = input_accept_count + 1;

        if (!first_input_seen) begin
          first_input_seen  = 1'b1;
          first_input_cycle = cycle_count;
        end
      end

      if (dut.lb_window_valid) begin
        window_count = window_count + 1;
      end

      if (dut.conv_valid) begin
        conv_output_count = conv_output_count + 1;
      end

      if (dut.pool_valid) begin
        pool_output_count = pool_output_count + 1;
      end

      if (dut.fmap_done && !fmap_done_seen) begin
        fmap_done_seen  = 1'b1;
        fmap_done_cycle = cycle_count;
      end

      if (dut.l2_valid) begin
        l2_output_count = l2_output_count + 1;
        last_l2_cycle   = cycle_count;

        if (!first_l2_seen) begin
          first_l2_seen  = 1'b1;
          first_l2_cycle = cycle_count;
        end
      end

      if (cnn_valid) begin
        classifier_output_count = classifier_output_count + 1;

        if (!cnn_valid_seen) begin
          cnn_valid_seen  = 1'b1;
          cnn_valid_cycle = cycle_count;
        end
      end
    end
  end

  // ------------------------------------------------------------
  // Window dump
  // ------------------------------------------------------------
  always @(posedge clk) begin
    #1step;

    if (dut.lb_window_valid) begin
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

  // ------------------------------------------------------------
  // Raw conv dump
  // ------------------------------------------------------------
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

  // ------------------------------------------------------------
  // Quantized conv dump
  // ------------------------------------------------------------
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

  // ------------------------------------------------------------
  // Pool dump
  // ------------------------------------------------------------
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

  // ------------------------------------------------------------
  // fmap_done monitor
  // ------------------------------------------------------------
  always @(posedge clk) begin
    #1step;

    if (dut.fmap_done) begin
      $display("\n==============================================");
      $display("FMAP_DONE @ t=%0t", $time);
      $display("Layer-1 fmap complete. Starting Layer-2.");
      $display("==============================================");
    end
  end

  // ------------------------------------------------------------
  // Layer-2 full-pipeline output monitor/dump/check
  // ------------------------------------------------------------
  always @(posedge clk) begin
    #1step;

    if (dut.l2_valid) begin
      $display("L2_FULL_OUT filter=%0d value=%0d expected=%0d",
               dut.l2_out_filter,
               dut.l2_out_data,
               expected_l2[dut.l2_out_filter]);

      $fwrite(f_l2_full, "%0d %0d\n",
              dut.l2_out_filter,
              dut.l2_out_data);

      if (dut.l2_out_data === expected_l2[dut.l2_out_filter]) begin
        $display("  PASS");
        l2_pass_count = l2_pass_count + 1;
      end else begin
        $display("  FAIL");
        l2_fail_count = l2_fail_count + 1;
      end
    end
  end

  // ------------------------------------------------------------
  // Classifier full-pipeline output monitor/dump/check
  // ------------------------------------------------------------
  always @(posedge clk) begin
    #1step;

    if (cnn_valid) begin
      $display("\n==============================================");
      $display("FULL PIPELINE CLASSIFIER OUTPUT");
      $display("==============================================");
      $display("CLASSIFIER_OUT class=%0d max_value=%0d expected_class=%0d expected_max=%0d",
               cnn_class,
               cnn_score,
               expected_class,
               expected_max_value);

      $fwrite(f_classifier_full, "%0d %0d\n",
              cnn_class,
              cnn_score);

      if ((cnn_class === expected_class) &&
          (cnn_score === expected_max_value)) begin
        $display("FULL PIPELINE CLASSIFIER OUTPUT: PASS");
        classifier_pass_count = classifier_pass_count + 1;
      end else begin
        $display("FULL PIPELINE CLASSIFIER OUTPUT: FAIL");
        classifier_fail_count = classifier_fail_count + 1;
      end
    end
  end

endmodule