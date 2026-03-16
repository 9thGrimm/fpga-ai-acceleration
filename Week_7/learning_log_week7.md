## Week 7 – Sunday (Pipeline Register Insertion)

- Added one pipeline register stage after Conv1 + ReLU output
- Registered output data, valid, and channel index
- Improved timing-friendliness of the streaming datapath
- Verified functionality preserved after pipelining