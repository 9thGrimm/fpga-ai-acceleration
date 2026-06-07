`timescale 1ns/1ps

module mac9_dual_channel #(
  parameter int PIX_W = 8,
  parameter int W_W   = 8,
  parameter int ACC_W = 32
)(
  input  logic clk,
  input  logic rst_n,

  input  logic start,

  input  logic signed [PIX_W-1:0] win_I [0:8],
  input  logic signed [PIX_W-1:0] win_Q [0:8],

  input  logic signed [W_W-1:0] w_I [0:8],
  input  logic signed [W_W-1:0] w_Q [0:8],

  output logic done,
  output logic signed [ACC_W-1:0] y
);

  typedef enum logic [1:0] {
    S_IDLE,
    S_MAC_I,
    S_MAC_Q,
    S_DONE
  } state_t;

  state_t state;

  logic signed [ACC_W-1:0] acc;
  logic signed [ACC_W-1:0] mac_out;

  logic signed [PIX_W-1:0] mac_p [0:8];
  logic signed [W_W-1:0]   mac_w [0:8];

  // Select which path feeds the runtime MAC
  always_comb begin
    if (state == S_MAC_I) begin
      mac_p[0] = win_I[0]; mac_p[1] = win_I[1]; mac_p[2] = win_I[2];
      mac_p[3] = win_I[3]; mac_p[4] = win_I[4]; mac_p[5] = win_I[5];
      mac_p[6] = win_I[6]; mac_p[7] = win_I[7]; mac_p[8] = win_I[8];

      mac_w[0] = w_I[0]; mac_w[1] = w_I[1]; mac_w[2] = w_I[2];
      mac_w[3] = w_I[3]; mac_w[4] = w_I[4]; mac_w[5] = w_I[5];
      mac_w[6] = w_I[6]; mac_w[7] = w_I[7]; mac_w[8] = w_I[8];
    end else begin
      mac_p[0] = win_Q[0]; mac_p[1] = win_Q[1]; mac_p[2] = win_Q[2];
      mac_p[3] = win_Q[3]; mac_p[4] = win_Q[4]; mac_p[5] = win_Q[5];
      mac_p[6] = win_Q[6]; mac_p[7] = win_Q[7]; mac_p[8] = win_Q[8];

      mac_w[0] = w_Q[0]; mac_w[1] = w_Q[1]; mac_w[2] = w_Q[2];
      mac_w[3] = w_Q[3]; mac_w[4] = w_Q[4]; mac_w[5] = w_Q[5];
      mac_w[6] = w_Q[6]; mac_w[7] = w_Q[7]; mac_w[8] = w_Q[8];
    end
  end

  mac9_runtime #(
    .PIX_W(PIX_W),
    .W_W(W_W),
    .ACC_W(ACC_W)
  ) u_mac (
    .p(mac_p),
    .w(mac_w),
    .y(mac_out)
  );

  always_ff @(posedge clk) begin
    if (!rst_n) begin
      state <= S_IDLE;
      acc   <= '0;
      y     <= '0;
      done  <= 1'b0;
    end else begin
      done <= 1'b0;

      case (state)
        S_IDLE: begin
          if (start) begin
            acc   <= '0;
            state <= S_MAC_I;
          end
        end

        S_MAC_I: begin
          acc   <= mac_out;
          state <= S_MAC_Q;
        end

        S_MAC_Q: begin
          acc   <= acc + mac_out;
          state <= S_DONE;
        end

        S_DONE: begin
          y    <= acc;
          done <= 1'b1;
          state <= S_IDLE;
        end

        default: state <= S_IDLE;
      endcase
    end
  end

endmodule