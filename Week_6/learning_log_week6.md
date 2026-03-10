\## Week 6 – Multi-Channel Conv1 Engine



\- Created runtime-weight 3×3 MAC module (`mac9\_runtime`)

\- Implemented `conv1\_engine` with 4 output channels

\- Added weight storage as `weight\[channel]\[kernel\_idx]`

\- Added channel FSM to reuse one MAC across 4 kernels

\- Prepared architecture for multi-channel Conv1 scaling

