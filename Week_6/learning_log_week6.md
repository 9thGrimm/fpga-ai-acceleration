## Week 6 – Sunday (Multi-Channel Conv1 Architecture)

Designed architecture for Conv1 with 4 output channels.

Input:
16×16×1 spectrogram frame

Kernel:
3×3 per channel
4 output channels

Architecture decision:
Time-multiplex MAC across channels.

Implementation plan:
- Single 9-multiplier MAC block reused
- Channel FSM iterates over 4 kernels
- Weight storage = 36 int8 values

Throughput:
1 convolution window every 4 cycles

Resource planning:
DSP slices = 9
Weight storage = 288 bits
Line buffers unchanged

Pipeline:
Pixel → Line Buffer → Window → MAC → ReLU → Pool