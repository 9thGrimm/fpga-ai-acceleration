`timescale 1ns/1ps

module maxpool_iq #(
    parameter int DATA_W = 32
    )(
        input logic clk,
        input logic rst_n,
        
        input logic in_valid,
        input logic signed [DATA_W-1:0] in_data,
        input logic [1:0] channel_idx,
        input logic [4:0] row_idx,
        input logic [2:0] col_idx,
        
        output logic out_valid,
        output logic signed [DATA_W-1:0] out_data,
        output logic [1:0] out_channel,
        output logic [4:0] out_row,
        output logic [2:0] out_col
     );
     
     // store previous values for 2x2 window
  logic signed [DATA_W-1:0] prev_row [0:3][0:5]; // per channel, per col
  logic signed [DATA_W-1:0] curr_row [0:3][0:5];

  logic signed [DATA_W-1:0] max_val;

  always_ff @(posedge clk) begin
    if (!rst_n) begin
      out_valid <= 1'b0;
      out_data  <= '0;
      out_channel <= '0;
      out_row <= '0;
      out_col <= '0;
    end else begin
      out_valid <= 1'b0;

      if (in_valid) begin
        // store current row
        curr_row[channel_idx][col_idx - 3'd2] <= in_data;

        // when we hit odd row and odd col → compute pool
        if ((row_idx >= 5'd2) && (col_idx >= 3'd2)) begin

          if ((row_idx[0] == 1'b1) && (col_idx[0] == 1'b1)) begin

            // 2x2 values
            logic signed [DATA_W-1:0] a, b, c, d;

            a = prev_row[channel_idx][col_idx - 3'd3];
            b = prev_row[channel_idx][col_idx - 3'd2];
            c = curr_row[channel_idx][col_idx - 3'd3];
            d = curr_row[channel_idx][col_idx - 3'd2];

            // max of 4
            max_val = a;
            if (b > max_val) max_val = b;
            if (c > max_val) max_val = c;
            if (d > max_val) max_val = d;

            out_valid   <= 1'b1;
            out_data    <= max_val;
            out_channel <= channel_idx;
            out_row     <= (row_idx - 5'd2) >> 1;
            out_col     <= (col_idx - 3'd2) >> 1;
          end
        end

        // update prev_row at end of row
        if (col_idx == 3'd7) begin
          prev_row[channel_idx][0] <= curr_row[channel_idx][0];
          prev_row[channel_idx][1] <= curr_row[channel_idx][1];
          prev_row[channel_idx][2] <= curr_row[channel_idx][2];
          prev_row[channel_idx][3] <= curr_row[channel_idx][3];
          prev_row[channel_idx][4] <= curr_row[channel_idx][4];
          prev_row[channel_idx][5] <= curr_row[channel_idx][5];
        end
      end
    end
  end

endmodule
     