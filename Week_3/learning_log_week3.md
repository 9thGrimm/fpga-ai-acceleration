## Week of Feb 2nd 2026

* Implemented Conv2D top-level RTL with FSM control
* Integrated 9-tap MAC using signed arithmetic
* Finalized pixel/weight/accumulator bit-widths
* Resolved SystemVerilog compilation issues
* Design compiles cleanly in Vivado
* Idea is to produce zero-latency MAC operator and finish the computation within 36 cycles
* Testing and Verification of values against python golden model is pending
