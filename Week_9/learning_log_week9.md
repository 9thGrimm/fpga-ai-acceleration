## Week 9 – Conv1 Feature Map & Pooling Integration (I/Q Path)

### Objective
Extend the I/Q-aware Conv1 pipeline to support:
- feature map storage for Conv1 outputs
- multi-channel 2×2 MaxPooling

---

### Conv1 Output Feature Map (Monday)

- Implemented `feature_map_buffer_iq` for storing Conv1 outputs
- Updated buffer dimensions to:
  - 4 output channels × 14 rows × 6 cols
- Mapped streaming indices:
  - row_idx 2..15 → stored rows 0..13
  - col_idx 2..7  → stored cols 0..5
- Integrated feature map buffer into I/Q Conv1 streaming top
- Expanded row index width to support larger spatial dimensions
- Fixed line buffer issues:
  - corrected row counter width
  - fixed last-column write into LB1

---

### Multi-Channel MaxPooling (Tuesday)

- Implemented `maxpool_iq` for 2×2 stride-2 pooling
- Supports per-channel pooling (no channel mixing)
- Designed streaming pooling architecture:
  - maintains previous row and current row buffers
  - computes max over 2×2 windows
- Pooling condition:
  - triggered at (row_idx odd, col_idx odd)
- Output feature map size:
  - 7 × 3 × 4
- Preserved channel-wise independence throughout pooling stage

---

### Full CNN Layer Integration (Wednesday)

- Integrated full pipeline:
  I/Q → Conv1 → ReLU → MaxPool → Feature Map Buffer
- Built `cnn_layer1_iq_top` as first complete CNN layer
- Connected multi-channel Conv1 with streaming MaxPool
- Established full dataflow from input to pooled feature map
- Verified structural integration across all modules

---

### Key Learnings

- Handling spatial indexing across streaming pipelines requires careful alignment
- Multi-channel designs introduce additional state tracking (per-channel buffers)
- Small timing bugs (like last-column writes) can silently corrupt data
- Streaming pooling requires thinking in terms of dataflow, not static matrices

---

### Status

- Conv1 I/Q pipeline: functional and verified
- Feature map buffer: integrated
- MaxPool: implemented and ready for integration\
- CNN Layer 1 Integrated with other Components of the data flow