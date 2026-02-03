module mac9 #(
  parameter int PIX_W  = 8,
  parameter int W_W    = 3,
  parameter int PROD_W = PIX_W + W_W,
  parameter int ACC_W  = 16,

  // Sobel-like kernel
  // [ 1  0 -1
  //   2  0 -2
  //   1  0 -1 ]
  parameter logic signed [W_W-1:0] W0 =  16'sd1,
  parameter logic signed [W_W-1:0] W1 =  16'sd0,
  parameter logic signed [W_W-1:0] W2 = -16'sd1,
  parameter logic signed [W_W-1:0] W3 =  16'sd2,
  parameter logic signed [W_W-1:0] W4 =  16'sd0,
  parameter logic signed [W_W-1:0] W5 = -16'sd2,
  parameter logic signed [W_W-1:0] W6 =  16'sd1,
  parameter logic signed [W_W-1:0] W7 =  16'sd0,
  parameter logic signed [W_W-1:0] W8 = -16'sd1
)(
  input  logic signed [PIX_W-1:0] p [0:8],  // 3x3 window pixels flattened
  output logic signed [ACC_W-1:0]  y         // accumulated output
);

  // Products
  logic signed [PROD_W-1:0] prod [0:8];

  mul_unit #(.A_W(PIX_W), .B_W(W_W), .P_W(PROD_W)) m0(.a(p[0]), .b(W0), .p(prod[0]));
  mul_unit #(.A_W(PIX_W), .B_W(W_W), .P_W(PROD_W)) m1(.a(p[1]), .b(W1), .p(prod[1]));
  mul_unit #(.A_W(PIX_W), .B_W(W_W), .P_W(PROD_W)) m2(.a(p[2]), .b(W2), .p(prod[2]));
  mul_unit #(.A_W(PIX_W), .B_W(W_W), .P_W(PROD_W)) m3(.a(p[3]), .b(W3), .p(prod[3]));
  mul_unit #(.A_W(PIX_W), .B_W(W_W), .P_W(PROD_W)) m4(.a(p[4]), .b(W4), .p(prod[4]));
  mul_unit #(.A_W(PIX_W), .B_W(W_W), .P_W(PROD_W)) m5(.a(p[5]), .b(W5), .p(prod[5]));
  mul_unit #(.A_W(PIX_W), .B_W(W_W), .P_W(PROD_W)) m6(.a(p[6]), .b(W6), .p(prod[6]));
  mul_unit #(.A_W(PIX_W), .B_W(W_W), .P_W(PROD_W)) m7(.a(p[7]), .b(W7), .p(prod[7]));
  mul_unit #(.A_W(PIX_W), .B_W(W_W), .P_W(PROD_W)) m8(.a(p[8]), .b(W8), .p(prod[8]));

  // Adder tree (balanced-ish) into ACC_W
  logic signed [ACC_W-1:0] s0, s1, s2, s3, s4;
  logic signed [ACC_W-1:0] t0, t1, t2;

  always_comb begin
    // widen products to accumulator width before summing
    s0 = $signed(prod[0]) + $signed(prod[1]);
    s1 = $signed(prod[2]) + $signed(prod[3]);
    s2 = $signed(prod[4]) + $signed(prod[5]);
    s3 = $signed(prod[6]) + $signed(prod[7]);
    s4 = $signed(prod[8]);

    t0 = s0 + s1;
    t1 = s2 + s3;
    t2 = t0 + t1;

    y  = t2 + s4;
  end

endmodule
