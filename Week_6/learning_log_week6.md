\## Week 6 – Multi-Channel Conv1 Engine



\- Created runtime-weight 3×3 MAC module (`mac9\_runtime`)

\- Implemented `conv1\_engine` with 4 output channels

\- Added weight storage as `weight\[channel]\[kernel\_idx]`

\- Added channel FSM to reuse one MAC across 4 kernels

\- Prepared architecture for multi-channel Conv1 scaling


Attempted integration of `conv1_engine` with streaming line-buffer output.

Observed behavior:
- Only 36 outputs produced instead of expected 144
- Output coordinates advanced while channel index changed
- This indicates the window source continued advancing while `conv1_engine` was still processing the previous window

Root cause:
- Throughput mismatch between producer and consumer
- `line_buffer_3x3` generates 1 window per cycle
- `conv1_engine` consumes 1 window every 4 cycles (time-multiplexed over 4 channels)
- No backpressure or window buffering currently implemented

Conclusion:
- Multi-channel Conv1 requires either:
  - ready/valid handshake with stalling, or
  - a FIFO of windows, or
  - parallel MAC instances
- Chosen next step: implement ready/valid handshake between line buffer and Conv1 engine
