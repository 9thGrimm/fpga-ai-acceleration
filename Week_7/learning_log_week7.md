## Week 7

- Added one pipeline register stage after Conv1 + ReLU output
- Registered output data, valid, and channel index
- Improved timing-friendliness of the streaming datapath
- Verified functionality preserved after pipelining
- Implemented `feature_map_buffer` to store Conv1 outputs
- Buffer shape: 4 channels × 6 rows × 6 cols
- Mapped streaming valid coordinates `(row_idx, col_idx)` from 2..7 into stored indices 0..5
- Integrated write-side storage for multi-channel Conv1 outputs
- Prepared design for full Conv1 layer buffering
- Added per-channel write counters in testbench
- Verified Conv1 output distribution across 4 channels
- Read back selected entries from feature map buffer
- Confirmed feature-map storage is populated and index mapping is correct
- Verified total writes = 144 and per-channel writes = 36
- Studied mapping of I/Q signals into CNN-compatible input format
- Decided to use interleaved streaming: I0, Q0, I1, Q1, ...
- Implemented `iq_stream_adapter` to convert I/Q pairs into single pixel stream
- Identified that future Conv layers must support multi-input channels
- Understood that AMR input is fundamentally different from image input

AMR input architecture refined:

- Use two separate input channels:
  - channel 0 = I
  - channel 1 = Q
- First target frame size: 16×8×2
- Conv1 configuration:
  - 3×3 kernel
  - 2 input channels
  - 4 output channels
  - VALID convolution
- Conv1 output shape: 14×6×4
- Pool output shape: 7×3×4
- This will serve as the first realistic AMR-oriented CNN layer target