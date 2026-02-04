## Week of Feb 2nd 2026

\## Week 3 – Tuesday (Conv2D RTL Verification Complete)



\### Objective

Finish Week 3 by implementing and verifying a synthesizable RTL Conv2D (8×8 input, 3×3 kernel, VALID) against the Python golden model.



\### What I built

\*\*RTL Modules\*\*

\- `mul\_unit.sv`: Signed multiplier unit (8-bit pixel × 3-bit weight → 11-bit product)

\- `mac9.sv`: 3×3 MAC with constant weights (9 multipliers + adder reduction)

\- `conv2d\_8x8\_3x3.sv` (top): 

&nbsp; - Internal 8×8 image storage

&nbsp; - 3×3 window extractor → `p\[0..8]` bus

&nbsp; - FSM that traverses output grid (6×6) and emits 36 outputs

&nbsp; - Control signals: `start`, `busy`, `out\_valid`, `done`

&nbsp; - Debug tags: `out\_row`, `out\_col`



\*\*Arithmetic choices\*\*

\- Pixel: signed 8-bit

\- Weight: signed 3-bit

\- Product: signed 11-bit

\- Accumulator/output: signed 16-bit (safe for 9-tap accumulation)



\### Verification Method

\*\*Golden Model\*\*

\- Python reference: manual nested-loop `conv2d\_valid` (cross-correlation style, no kernel flip)

\- Input: `x\_8x8.txt`

\- Expected output: `y\_6x6.txt`

\- Kernel weights are constant in RTL (Sobel-like):  

&nbsp; `\[ 1  0 -1; 2  0 -2; 1  0 -1 ]`



\*\*Testbench\*\*

\- `tb\_conv2d\_top.sv`

\- Preloaded `dut.img\[r]\[c]` using hierarchical assignment

\- Loaded expected `gold\[6]\[6]` from `y\_6x6.txt`

\- Comparison performed on every `out\_valid` cycle using `(out\_row, out\_col)`

\- Abort on first mismatch using `$fatal`



\### Key Debug/Integration Issues Encountered \& Fixes

1\. \*\*SystemVerilog compile issue ("signed" syntax error)\*\*

&nbsp;  - Root cause: files were being treated as Verilog instead of SystemVerilog

&nbsp;  - Fix: ensure sources are `.sv` and file type set to SystemVerilog



2\. \*\*XSIM `$fscanf` usage error\*\*

&nbsp;  - `$fscanf` must be used as a function with LHS: `rc = $fscanf(...)`



3\. \*\*File open failures for x\_8x8/y\_6x6\*\*

&nbsp;  - Root cause: malformed file path missing slash (`.../newx\_8x8.txt`)

&nbsp;  - Fix: use explicit absolute paths or correct string concatenation; verified `fopen` succeeds



\### Results

\- PASS: \*\*All 36 outputs match Python golden model\*\*

\- Observed output values: consistent `-8` for this specific ramp input and Sobel-like kernel (expected due to constant horizontal gradient)

\- Convolution throughput: \*\*1 output per cycle\*\* during BUSY

\- Done asserted after completion of full 6×6 output sweep



\### Artifacts Produced

\- RTL: `mul\_unit.sv`, `mac9.sv`, `conv2d\_8x8\_3x3.sv`

\- TB: `tb\_conv2d\_top.sv`

\- Golden files: `x\_8x8.txt`, `y\_6x6.txt`

\- Evidence: waveform + console PASS screenshot

