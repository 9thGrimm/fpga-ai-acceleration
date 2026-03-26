## Week 8 – Multi-Channel Conv Design

Extended Conv1 architecture to support multi-input channels (I/Q).

Key changes:
- Each output channel now accumulates contributions from both I and Q inputs
- Conv equation:
  Y = (I * W_I) + (Q * W_Q)

Architecture decision:
- Sequential MAC reuse for I and Q paths
- Two passes per output channel

Design updates:
- Weight storage extended to weight[ch][input_channel][kernel]
- Two line buffers required (I and Q)
- Dual window inputs: win_I and win_Q

Throughput impact:
- Processing time per window doubles (from 4 to 8 cycles)

- Implemented `mac9_dual_channel` for I/Q-aware convolution
- Added sequential accumulation across I and Q channels
- FSM states: IDLE → MAC_I → MAC_Q → DONE
- Reused existing runtime MAC instead of duplicating compute
- Prepared dual-channel compute block for multi-channel Conv1 integration