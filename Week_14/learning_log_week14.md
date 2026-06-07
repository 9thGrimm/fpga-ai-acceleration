Date: Week 14



Topic: Full CNN Pipeline Integration: Layer-1 to Layer-2



\* Started Week 14 by moving from standalone Layer-2 verification to full-pipeline integration

\* Integrated the verified Layer-2 convolution engine into the main CNN top module

\* Updated the full pipeline flow to:

&#x20; \* 8×8 I/Q input stream

&#x20; \* 3×3 line buffer

&#x20; \* window FIFO

&#x20; \* Layer-1 convolution

&#x20; \* ReLU

&#x20; \* quantizer

&#x20; \* maxpool

&#x20; \* feature map buffer

&#x20; \* Layer-2 convolution engine

\* Modified the feature map buffer to expose the completed Layer-1 pooled feature map

\* Added `fmap\_done` signaling to indicate when all Layer-1 pooled outputs are available

\* Used `fmap\_done` to trigger Layer-2 execution after Layer-1 completion

\* Connected the Layer-1 feature map buffer output directly into the Layer-2 RTL engine

\* Updated the full-pipeline SystemVerilog testbench to:

&#x20; \* drive the original 8×8 I/Q input stream

&#x20; \* monitor Layer-1 completion

&#x20; \* capture full-pipeline Layer-2 outputs

&#x20; \* dump Layer-2 results to a text file

\* Verified that Layer-2 now runs from the generated Layer-1 feature map instead of manually loaded standalone inputs

\* Added Python-side comparison support for full-pipeline Layer-2 RTL output

\* Revalidated that Layer-1 outputs remained correct after integration:

&#x20; \* raw convolution feature map

&#x20; \* quantized convolution feature map

&#x20; \* pooled feature map

\* Verified full-pipeline Layer-2 outputs against Python golden model

\* Confirmed full CNN pipeline comparison passes successfully

