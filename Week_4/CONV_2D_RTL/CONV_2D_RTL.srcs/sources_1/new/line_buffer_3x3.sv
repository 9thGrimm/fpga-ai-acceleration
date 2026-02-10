`timescale 1ns/1ps

module line_buffer_3x3 #(
    parameter int PIX_W = 8
)(
   input logic clk,
   input logic rst_n,
   
   input logic in_valid,
   input logic signed [PIX_W-1:0] in_pixel,
   
   output logic window_valid,
   output logic signed [PIX_W-1:0] w [0:8],
   
   output logic [2:0] row_idx,
   output logic [2:0] col_idx
  );
   
   
  localparam int W = 8;
   
  //Row Buffers
  logic signed [PIX_W-1:0] lb2 [0:W-1]; // row r-2
  logic signed [PIX_W-1:0] lb1 [0:W-1]; // row r-1
  logic signed [PIX_W-1:0] cur [0:W-1]; // row r
   
  // 2-deep shift regs for column history (per row tap stream)
  logic signed [PIX_W-1:0] sr2_0, sr2_1; // for lb2 taps
  logic signed [PIX_W-1:0] sr1_0, sr1_1; // for lb1 taps
  logic signed [PIX_W-1:0] src_0, src_1; // for current row taps
  
  logic [2:0] col;
  logic [2:0] row;
  
  // Current column taps from stored rows
  logic signed [PIX_W-1:0] tap2, tap1; 
  
  assign row_idx = row;
  assign col_idx = col;
  
  always_comb begin
    unique case (col)
      3'd0: begin tap2 = lb2[0]; tap1 = lb1[0]; end
      3'd1: begin tap2 = lb2[1]; tap1 = lb1[1]; end
      3'd2: begin tap2 = lb2[2]; tap1 = lb1[2]; end
      3'd3: begin tap2 = lb2[3]; tap1 = lb1[3]; end
      3'd4: begin tap2 = lb2[4]; tap1 = lb1[4]; end
      3'd5: begin tap2 = lb2[5]; tap1 = lb1[5]; end
      3'd6: begin tap2 = lb2[6]; tap1 = lb1[6]; end
      default: begin tap2 = lb2[7]; tap1 = lb1[7]; end
    endcase
  end
  
  always_comb begin
    window_valid = in_valid && (row >= 3'd2) && (col >= 3'd2);
  end
  
  // Window outputs (3x3)
  always_comb begin
    // row r-2
    w[0] = sr2_1;
    w[1] = sr2_0;
    w[2] = tap2;

    // row r-1
    w[3] = sr1_1;
    w[4] = sr1_0;
    w[5] = tap1;

    // row r (current row)
    w[6] = src_1;
    w[7] = src_0;
    w[8] = in_pixel;
  end
    
  always_ff @(posedge clk) begin
    if (!rst_n) begin
      col <= 3'd0;
      row <= 3'd0;

      sr2_0 <= '0; sr2_1 <= '0;
      sr1_0 <= '0; sr1_1 <= '0;
      src_0 <= '0; src_1 <= '0;

      lb2[0] <= '0; lb2[1] <= '0; lb2[2] <= '0; lb2[3] <= '0;
      lb2[4] <= '0; lb2[5] <= '0; lb2[6] <= '0; lb2[7] <= '0;

      lb1[0] <= '0; lb1[1] <= '0; lb1[2] <= '0; lb1[3] <= '0;
      lb1[4] <= '0; lb1[5] <= '0; lb1[6] <= '0; lb1[7] <= '0;

      cur[0] <= '0; cur[1] <= '0; cur[2] <= '0; cur[3] <= '0;
      cur[4] <= '0; cur[5] <= '0; cur[6] <= '0; cur[7] <= '0;

    end else if (in_valid) begin
        // Write incoming pixel into CUR at [col]
      unique case (col)
        3'd0: cur[0] <= in_pixel;
        3'd1: cur[1] <= in_pixel;
        3'd2: cur[2] <= in_pixel;
        3'd3: cur[3] <= in_pixel;
        3'd4: cur[4] <= in_pixel;
        3'd5: cur[5] <= in_pixel;
        3'd6: cur[6] <= in_pixel;
        default: cur[7] <= in_pixel;
      endcase

      // Shift column histories (taps shift each cycle)
      sr2_1 <= sr2_0;  sr2_0 <= tap2;
      sr1_1 <= sr1_0;  sr1_0 <= tap1;
      src_1 <= src_0;  src_0 <= in_pixel;

      // Advance column; on col==7, rotate row buffers
      if (col == 3'd7) begin
        col <= 3'd0;
        row <= row + 3'd1;

        // Write LB1 to LB2
        lb2[0] <= lb1[0]; lb2[1] <= lb1[1]; lb2[2] <= lb1[2]; lb2[3] <= lb1[3];
        lb2[4] <= lb1[4]; lb2[5] <= lb1[5]; lb2[6] <= lb1[6]; lb2[7] <= lb1[7];

        //Write Current Row Buffer to LB1
        lb1[0] <= cur[0]; lb1[1] <= cur[1]; lb1[2] <= cur[2]; lb1[3] <= cur[3];
        lb1[4] <= cur[4]; lb1[5] <= cur[5]; lb1[6] <= cur[6]; lb1[7] <= cur[7];

        // Reset current-row shift regs for the next row
        src_0 <= '0;
        src_1 <= '0;
      end else begin
        col <= col + 3'd1;
      end
    end
  end

endmodule  
    