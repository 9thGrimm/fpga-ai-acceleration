`timescale 1ns / 1ps

module conv2d_8x8_3x3 #(
  parameter int PIX_W  = 8,
  parameter int W_W    = 3,
  parameter int ACC_W  = 16
)(
  input  logic clk,
  input  logic rst_n,

  input  logic start,
  output logic busy,
  output logic done,

  output logic out_valid,
  output logic signed [ACC_W-1:0] out_y,
  

  output logic [2:0] out_row,
  output logic [2:0] out_col
);

  // ----------------------------
  // Internal image storage (8x8)
  // ----------------------------
  logic signed [PIX_W-1:0] img [0:7][0:7];

  // 3x3 window pixels flattened
  logic signed [PIX_W-1:0] p [0:8];

  // MAC output
  logic signed [ACC_W-1:0] mac_y;

  // Output scanning counters for 6x6 output
  logic [2:0] row, col;        // 0..5
  logic [5:0] out_count;       // 0..35

  typedef enum logic [1:0] {S_IDLE, S_BUSY, S_DONE} state_t;
  state_t state;

  // -----------------------------------------
  // Window extraction (combinational selection)
  // -----------------------------------------
  always_comb begin
    // Only valid when row/col are 0..5, which the FSM guarantees in BUSY.
    p[0] = img[row+0][col+0];
    p[1] = img[row+0][col+1];
    p[2] = img[row+0][col+2];
    p[3] = img[row+1][col+0];
    p[4] = img[row+1][col+1];
    p[5] = img[row+1][col+2];
    p[6] = img[row+2][col+0];
    p[7] = img[row+2][col+1];
    p[8] = img[row+2][col+2];
  end

  // ----------------------------
  // 9-tap MAC (weights constant)
  // ----------------------------
  mac9 #(
    .PIX_W(PIX_W),
    .W_W(W_W),
    .ACC_W(ACC_W)
    // weights use defaults (Sobel-like) unless overridden
  ) u_mac9 (
    .p(p),
    .y(mac_y)
  );

  // Connect MAC to output
  always_comb begin
    out_y = mac_y;
  end

  // -----------------------------------------
  // FSM: IDLE -> BUSY (emit 36 outputs) -> DONE
  // -----------------------------------------
  always_ff @(posedge clk) begin
    if (!rst_n) begin
      state     <= S_IDLE;
      row       <= '0;
      col       <= '0;
      out_count <= '0;

      busy      <= 1'b0;
      done      <= 1'b0;
      out_valid <= 1'b0;

      out_row   <= '0;
      out_col   <= '0;
    end else begin
      done      <= 1'b0;  // pulse done
      out_valid <= 1'b0;  // pulse out_valid (1/cycle during BUSY)

      case (state)
        S_IDLE: begin
          busy      <= 1'b0;
          row       <= '0;
          col       <= '0;
          out_count <= '0;

          if (start) begin
            state <= S_BUSY;
            busy  <= 1'b1;
          end
        end

        S_BUSY: begin
          busy      <= 1'b1;
          out_valid <= 1'b1;

          // Provide row/col tags (optional debug)
          out_row <= row;
          out_col <= col;

          // Advance scan position
          if (col == 3'd5) begin
            col <= 3'd0;
            row <= row + 3'd1;
          end else begin
            col <= col + 3'd1;
          end

          // Count outputs. When we have emitted 36, finish.
          if (out_count == 6'd35) begin
            state <= S_DONE;
          end
          out_count <= out_count + 6'd1;
        end

        S_DONE: begin
          busy <= 1'b0;
          done <= 1'b1;     // one-cycle done pulse
          state <= S_IDLE;  // auto-return
        end

        default: state <= S_IDLE;
      endcase
    end
  end
endmodule
