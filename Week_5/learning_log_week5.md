## Week 5 – Monday (ReLU Primitive)

- Implemented a combinational ReLU block (signed clamp-to-zero)
- Integrated ReLU after MAC in streaming Conv2D datapath
- Re-ran streaming sanity test (out_valid count remained 36)
- Confirmed negative outputs are clipped to 0