## Week 9 – Monday (I/Q Conv1 Feature Map Integration)

### Objective
Extend the I/Q streaming Conv1 pipeline to store outputs in a structured feature map buffer corresponding to the full Conv1 output dimensions.

### Key Updates

- Implemented `feature_map_buffer_iq` for storing Conv1 outputs
- Updated buffer dimensions to:
  - 4 channels × 14 rows × 6 columns
- Mapped streaming indices to buffer indices:
  - `row_idx 2..15 → 0..13`
  - `col_idx 2..7  → 0..5`
- Integrated feature map buffer into `conv1_iq_streaming_top`

### Line Buffer Fixes

- Expanded `row` counter from 3-bit to 5-bit to support larger input height
- Fixed row-boundary write issue:
  - ensured last pixel of each row is correctly written into LB1
- Maintained synchronized backpressure across I/Q line buffers

### Dataflow Established

I/Q Input → Line Buffers → Conv1 (I/Q) → ReLU → Feature Map Buffer

### Outcome

- Full I/Q Conv1 pipeline now supports correct spatial dimensions
- Output storage aligned with CNN layer expectations (14×6×4)
- Design compiles cleanly with updated index widths and buffer integration