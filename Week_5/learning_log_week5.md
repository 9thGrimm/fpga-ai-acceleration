## Week 5 – ReLU + Streaming MaxPool

- Implemented a combinational ReLU block (signed clamp-to-zero)
- Integrated ReLU after MAC in streaming Conv2D datapath
- Re-ran streaming sanity test (out_valid count remained 36)
- Confirmed negative outputs are clipped to 0
- Implemented `maxpool_2x2_streaming` with stride=2
- Streaming approach:
  - Two-cycle horizontal max (even/odd column pairing)
  - One-row buffering of horizontal maxima for vertical comparison
  - Output produced only for valid 2×2 blocks
- Integrated MaxPool into the Convolution 2D RTL design.


## Week 5 - AMR Preliminary Planning
- Detailed plan noted from iPad pushed into Git
- 16×16 spectrogram input
- int8 quantized activations and weights
- 2-layer CNN architecture planned
- PL: CNN accelerator
- PS: IQ loading, initial FFT (Phase 1), classification logic

## Defined complete Layer 1 hardware specification:

Input:
- 16×16×1 int8 spectrogram frame

Conv1:
- 3×3 kernel, stride 1, VALID
- 4 output channels
- int8 weights, int32 accumulate
- ReLU activation

Pooling:
- 2×2 stride 2
- Output 7×7×4

Throughput model:
- Streaming architecture
- Line buffer based
- Deterministic output rate
 