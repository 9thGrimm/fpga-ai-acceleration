Date: Week 11



Topic: Bit-Accurate Verification and Streaming Debug (Conv Pipeline)



* Revalidated TB input stream (I: 0–63, Q: 64–127) → no skips or duplication
* Verified line buffer 3×3 sliding window against Python golden model
* Fixed earlier window misalignment and stale shift register issues
* Confirmed correct (row\_idx, col\_idx) mapping to spatial windows
* Dumped full RTL windows and matched against Python (all windows correct)
* Verified convolution MAC correctness per channel for all accepted windows
* Confirmed raw convolution outputs match Python on populated entries
* Verified ReLU and quantizer stages are numerically correct
* Updated Python script to:

  * print all windows
  * reconstruct conv feature maps
  * compare raw, relu, quant, and pooled outputs
  * handle RTL channel ordering
  * Identified sparse conv output pattern (only alternate columns produced)
* Observed missing spatial positions: col = 3,5,7 not processed
* Verified maxpool not triggering due to incomplete 2×2 regions
* Confirmed feature map buffer remains zero due to missing upstream data
* Debugged multiple control-path fixes:

  * line buffer valid/ready timing
  * metadata alignment fixes
  * top-level capture stage
  * 1-entry buffer between LB and conv
  * skid-buffer overwrite logic
  * start\_window pulse-based triggering for conv engine
* Root cause identified:

  * conv engine processes 1 window over 4 cycles (channel-serialized)
  * line buffer produces 1 window per cycle
  * lack of buffering causes window drops → sparse conv map
* Concluded datapath correctness but streaming pipeline limitation

