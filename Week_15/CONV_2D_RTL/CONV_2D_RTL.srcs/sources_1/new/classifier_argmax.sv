`timescale 1ns/1ps

module classifier_argmax #(
    parameter int NUM_CLASSES = 4,
    parameter int DATA_W      = 32,
    parameter int CLASS_W     = 2
)(
    input  logic clk,
    input  logic rst_n,

    input  logic start,
    input  logic signed [DATA_W-1:0] logits [0:NUM_CLASSES-1],

    output logic valid,
    output logic [CLASS_W-1:0] predicted_class,
    output logic signed [DATA_W-1:0] max_value
);

    integer i;

    logic signed [DATA_W-1:0] max_comb;
    logic [CLASS_W-1:0] class_comb;

    always_comb begin
        max_comb   = logits[0];
        class_comb = '0;

        for (i = 1; i < NUM_CLASSES; i = i + 1) begin
            if (logits[i] > max_comb) begin
                max_comb   = logits[i];
                class_comb = i[CLASS_W-1:0];
            end
        end
    end

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            valid           <= 1'b0;
            predicted_class <= '0;
            max_value       <= '0;
        end else begin
            valid <= 1'b0;

            if (start) begin
                predicted_class <= class_comb;
                max_value       <= max_comb;
                valid           <= 1'b1;
            end
        end
    end

endmodule