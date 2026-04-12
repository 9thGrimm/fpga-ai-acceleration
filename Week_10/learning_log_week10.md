Date: Week 10

Topic: Quantization Integration between ReLU and Maxpool Stage

* Integrated quantizer (32 → 16-bit) after ReLU
* Updated top module and feature map buffer for quantized data
* Fixed I/Q valid alignment
* Added stage-wise debug + X/Z checks in TB
* Verified full pipeline: 64 inputs → 36 outputs (9/channel)
* No unknowns; outputs correct and stable

