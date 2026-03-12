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

### Problem
After introducing multi-channel Conv1 processing, the consumer (Conv1 engine) required multiple cycles per window, while the producer (line buffer) continued producing windows every cycle.

This created a throughput mismatch, causing dropped windows and incomplete output coverage.

### Root Cause
The testbench and upstream logic did not honor backpressure. Input pixels continued to advance every cycle regardless of the readiness of the downstream compute engine.

### Solution
Implemented full ready/valid handshake propagation:

Conv1 Engine → window_ready  
Line Buffer → advances only when (in_valid && window_ready)

Additionally:
- propagated `in_ready` to the top module
- modified testbench to hold input pixel until accepted

### Result
Producer and consumer are now rate-matched.

The system correctly processes:
- 64 input pixels
- 36 convolution windows
- 4 output channels per window

Final output count: **144 outputs**

### Key Learning
Streaming hardware systems must propagate backpressure upstream. Any stage that can stall must expose a ready signal so producers do not overrun consumers.
