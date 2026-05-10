Date: Week 13



Topic: Layer-2 Golden Model and Standalone RTL Bring-Up



\* Started Week 13 by extending the verified Layer-1 pipeline toward a second CNN layer

\* Selected Layer-2 architecture direction:

&#x20; \* 4 input channels

&#x20; \* 4 output filters

&#x20; \* 3×3 multi-channel convolution

&#x20; \* output shape: 4 scalar values

\* Used the verified Layer-1 pooled feature map as the input to Layer-2

\* Added Python golden model support for Layer-2 multi-channel convolution

\* Added simple RTL-friendly weights using small deterministic values

\* Added debug support to inspect:

&#x20; \* Layer-2 input feature map

&#x20; \* selected weights

&#x20; \* partial sums

&#x20; \* final Layer-2 outputs

\* Generated Layer-2 Python reference outputs for future RTL comparison

\* Implemented standalone Layer-2 RTL convolution engine

\* Designed the RTL block to accumulate across:

&#x20; \* multiple input channels

&#x20; \* 3×3 spatial kernels

&#x20; \* multiple output filters

\* Created a standalone SystemVerilog testbench for Layer-2 verification

\* Drove the verified Layer-1 pooled feature map directly into the Layer-2 RTL block

\* Added RTL output dumping for Layer-2 results

\* Verified Layer-2 RTL outputs against the Python golden model

\* Confirmed standalone Layer-2 RTL comparison passes successfully

\* Kept Layer-2 verification standalone to avoid disturbing the already verified Layer-1 pipeline



