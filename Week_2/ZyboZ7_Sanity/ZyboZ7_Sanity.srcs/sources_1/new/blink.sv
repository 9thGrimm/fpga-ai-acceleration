`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 01/27/2026 12:02:08 AM
// Design Name: 
// Module Name: blink
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module blink(
    input  wire       clk,
    input  wire       rst_n,
    output reg  [3:0] led
);

    // Divider: adjust for visible blink.
    // If board clock is 125 MHz, toggling around 1-2 Hz is comfortable.
    reg [31:0] cnt;

    always @(posedge clk) begin
        if (rst_n) begin
            cnt <= 32'd0;
            led <= 4'b0001;
        end else begin
            cnt <= cnt + 1;

            // Toggle every ~0.5s-1s depending on clock and threshold.
            // For 125MHz: 125_000_000 cycles ≈ 1 sec.
            if (cnt == 32'd125_000_000) begin
                cnt <= 32'd0;
                led <= {led[2:0], led[3]}; // rotate
            end
        end
    end

endmodule
