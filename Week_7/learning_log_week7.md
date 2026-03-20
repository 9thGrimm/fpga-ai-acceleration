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