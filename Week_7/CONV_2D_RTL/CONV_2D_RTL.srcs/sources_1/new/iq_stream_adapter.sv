`timescale 1ns / 1ps

module iq_stream_adapter#(
      parameter int W = 8  
    )(
      input logic clk,
      input logic rst_n,
      
      input logic in_valid,
      input logic signed [W-1:0] i_data,
      input logic signed [W-1:0] q_data,
      
      output logic out_valid,
      output logic signed [W-1:0] out_pixel
      );
      
      logic toggle;
      
      always_ff @ (posedge clk) begin
        if (!rst_n) begin
            toggle <= 1'b0;
            out_valid <= 1'b0;
            out_pixel <= 1'b0;
        end else begin
           if (in_valid) begin  
            out_valid <= 1'b1;
            
            if (toggle == 1'b0) begin
                out_pixel <= i_data;
                toggle <= 1'b1;
            end else begin
                out_pixel <= q_data;
                toggle <= 1'b0;
            end
           end else begin
            out_valid <= 1'b0;
           end
          end
         end          
endmodule
