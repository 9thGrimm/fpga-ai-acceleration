Date: Week 13



Topic: Layer-2 Python Golden Model Integration



\* Started Week 13 by extending the verified Layer-1 pipeline toward a second CNN layer

\* Selected Layer-2 architecture direction:



&#x20; \* 4 input channels

&#x20; \* 4 output filters

&#x20; \* 3×3 multi-channel convolution

&#x20; \* output shape: 4 scalar values



\* Used the verified Layer-1 pooled feature map as the input to Layer-2

\* Added Python golden model support for Layer-2 multi-channel convolution

\* Added simple RTL-friendly weights using small values such as -1, 0, and +1

\* Added debug support to print Layer-2 inputs, weights, partial sums, and final outputs

\* Verified Layer-2 golden outputs in Python:



&#x20; \* Raw: \[138, 108, 970, 474]

&#x20; \* ReLU: \[138, 108, 970, 474]

&#x20; \* Quantized: \[138, 108, 970, 474]



\* Confirmed Layer-2 Python reference is ready for future RTL comparison

