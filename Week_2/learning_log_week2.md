## Week of Jan 26th 2026

* Successfully connected Zybo Z7-20 to Vivado Hardware Manager
* Built and programmed a simple RTL LED blink design
* Resolved UCIO-1 DRC by mapping rst\_n to BTN0
* Verified reset polarity and functionality on hardware
* Completed full RTL → synth → impl → bitstream → program → validate loop
* Practiced safe power-down and ESD handling
* Implemented 2D VALID convolution using explicit nested loops on python
* Used integer arithmetic suitable for FPGA mapping
* Verified output determinism using Sobel-like kernel
* Observed constant -8 output due to linear input gradient
* Generated reference files for RTL testbench comparison
* Mapped Python conv2d loops to FSM + MAC hardware structure
* Identified registers, combinational blocks, and control logic
* Selected serial MAC architecture with accumulator
* Finalized safe bit-widths for input, weight, and accumulation
