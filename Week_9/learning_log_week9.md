Date: Week 9

Topic: complete CNN Layer1 I/Q pipeline with Conv1, ReLU, MaxPool, and feature map buffer

- Built end-to-end streaming CNN pipeline:
  I/Q → Line Buffer → Conv1 → ReLU → MaxPool → Feature Map Buffer
- Implemented multi-channel Conv1 engine (4 output channels)
- Integrated streaming 3x3 line buffers for I/Q paths
- Added ReLU activation stage

- Implemented maxpool_iq:
  - 2x2 stride-2 pooling
  - per-channel independence
  - row-buffer-based streaming architecture
  - correct pooling trigger (odd row/col)

- Developed feature_map_buffer_iq:
  - initially designed for conv-map storage (14x6)
  - later corrected to store pooled outputs (3x3 per channel)
  - fixed indexing mismatch (conv-space vs pool-space)
  - added reset initialization for deterministic simulation

- Debug & fixes:
  - Fixed critical ReLU width mismatch (16-bit → 32-bit)
  - Eliminated partial Z propagation in pipeline
  - Corrected maxpool boundary/indexing issues
  - Fixed feature map write addressing bug
  - Verified valid/ready handshake behavior under backpressure

- Testbench improvements:
  - Added handshake-aware stimulus
  - Introduced stage-wise debug logs (conv/relu/pool)
  - Implemented unknown (X/Z) detection counters
  - Added full feature map dump (matrix + indexed view)

- Verification results:
  - 36 pooled outputs generated (expected)
  - 9 outputs per channel confirmed
  - Zero unknown propagation across all stages
  - Correct spatial mapping validated in feature map

This commit marks a fully functional and verified CNN Layer1 hardware pipeline.