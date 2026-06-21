`timescale 1ns/1ps

module tb_classifier_argmax;

    localparam int NUM_CLASSES = 4;
    localparam int DATA_W      = 32;
    localparam int CLASS_W     = 2;

    logic clk;
    logic rst_n;
    logic start;

    logic signed [DATA_W-1:0] logits [0:NUM_CLASSES-1];

    logic valid;
    logic [CLASS_W-1:0] predicted_class;
    logic signed [DATA_W-1:0] max_value;

    integer fd;
    integer pass_count;
    integer fail_count;

    classifier_argmax #(
        .NUM_CLASSES(NUM_CLASSES),
        .DATA_W(DATA_W),
        .CLASS_W(CLASS_W)
    ) dut (
        .clk(clk),
        .rst_n(rst_n),
        .start(start),
        .logits(logits),
        .valid(valid),
        .predicted_class(predicted_class),
        .max_value(max_value)
    );

    initial begin
        clk = 1'b0;
        forever #5 clk = ~clk;
    end

    initial begin
        rst_n = 1'b0;
        start = 1'b0;

        logits[0] = '0;
        logits[1] = '0;
        logits[2] = '0;
        logits[3] = '0;

        pass_count = 0;
        fail_count = 0;

        fd = $fopen("rtl_classifier_out.txt", "w");
        if (fd == 0) begin
            $display("ERROR: Could not open rtl_classifier_out.txt");
            $finish;
        end

        repeat (5) @(posedge clk);
        rst_n = 1'b1;
        repeat (2) @(posedge clk);

        // Layer-2 golden output from existing testset:
        // [138, 108, 970, 474]
        logits[0] = 32'sd138;
        logits[1] = 32'sd108;
        logits[2] = 32'sd970;
        logits[3] = 32'sd474;

        @(posedge clk);
        start = 1'b1;

        @(posedge clk);
        start = 1'b0;

        wait (valid == 1'b1);

        $display("");
        $display("============================================================");
        $display("STANDALONE CLASSIFIER OUTPUT");
        $display("============================================================");
        $display("predicted_class=%0d max_value=%0d", predicted_class, max_value);

        $fwrite(fd, "%0d %0d\n", predicted_class, max_value);

        if ((predicted_class == 2'd2) && (max_value == 32'sd970)) begin
            $display("CLASSIFIER COMPARISON: PASS");
            pass_count = pass_count + 1;
        end else begin
            $display("CLASSIFIER COMPARISON: FAIL");
            $display("Expected class=2 max_value=970");
            fail_count = fail_count + 1;
        end

        $display("");
        $display("PASS count = %0d", pass_count);
        $display("FAIL count = %0d", fail_count);

        $fclose(fd);

        repeat (5) @(posedge clk);
        $finish;
    end

endmodule