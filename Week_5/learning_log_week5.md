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
- Integrated MaxPool into t