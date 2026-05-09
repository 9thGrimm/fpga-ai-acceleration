Date: Week 12



Topic: FIFO-Based Streaming Fix and End-to-End CNN Layer1 Verification



\* Implemented a window FIFO between the 3×3 line buffer and serialized convolution engine

\* Updated top module flow to:



&#x20; \* Line Buffer → Window FIFO → Conv → ReLU → Quantizer → MaxPool → Feature Map Buffer

\* Stored full window packet inside FIFO:



&#x20; \* I 3×3 window

&#x20; \* Q 3×3 window

&#x20; \* row\_idx

&#x20; \* col\_idx

\* Increased FIFO depth to safely absorb producer/consumer throughput mismatch

\* Fixed sparse convolution output issue caused by line buffer producing windows faster than conv engine consumed them

\* Confirmed all 36 valid 3×3 windows are preserved and processed

\* Verified raw convolution output is now fully dense:



&#x20; \* 6×6×4 = 144 outputs

\* Confirmed raw convolution feature map matches Python golden model:



&#x20; \* Compared populated entries: 144/144

&#x20; \* PASS

\* Verified quantized convolution feature map matches Python golden model:



&#x20; \* Compared populated entries: 144/144

&#x20; \* PASS

\* Verified maxpool now receives complete 2×2 regions

\* Confirmed pooled RTL stream produces all expected outputs:



&#x20; \* 3×3×4 = 36 outputs

\* Verified final pooled feature map against Python golden model:



&#x20; \* PASS

\* Confirmed feature map buffer stores correct final 3×3 outputs for all 4 channels

\* Final RTL pooled feature map:



&#x20; \* Channel 0:



&#x20;   \* 18 20 22

&#x20;   \* 34 36 38

&#x20;   \* 50 52 54



&#x20; \* Channel 1:



&#x20;   \* 0 0 0

&#x20;   \* 0 0 0

&#x20;   \* 0 0 0



&#x20; \* Channel 2:



&#x20;   \* 8 8 8

&#x20;   \* 8 8 8

&#x20;   \* 8 8 8



&#x20; \* Channel 3:



&#x20;   \* 114 118 122

&#x20;   \* 146 150 154

&#x20;   \* 178 182 186

\* Resolved Week 11 carryover issue:



&#x20; \* previous sparse conv map

&#x20; \* missing intermediate columns

&#x20; \* empty/incomplete maxpool output

&#x20; \* zero feature map buffer

\* Validated full bit-accurate pipeline from RTL dumps against Python:



&#x20; \* windows

&#x20; \* raw conv

&#x20; \* ReLU

&#x20; \* quantized conv

&#x20; \* maxpool

&#x20; \* final feature map

