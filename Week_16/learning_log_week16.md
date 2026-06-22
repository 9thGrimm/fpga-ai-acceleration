Date: Week 16

Topic: Printing Debug Clean-up and Latency Counters Incorporation

* Started Week 16 after completing the full Layer-1 → Layer-2 → classifier CNN pipeline
* Focused Week 16 work on cleanup, observability, and measurable pipeline behavior
* Added a debug control parameter to the 3×3 line buffer module
* Used the debug parameter to disable verbose simulation prints during normal regression runs
* Preserved the option to re-enable detailed line buffer debug output when needed
* Updated the CNN top module to instantiate line buffers with debug printing disabled by default
* Cleaned the full-pipeline simulation output so only key milestones are printed
* Confirmed that removing debug print noise did not affect functional behavior
* Exposed the final CNN classifier outputs cleanly from the top-level module:
  * `cnn_valid`
  * `cnn_class`
  * `cnn_score`
* Updated the full-pipeline testbench to use top-level CNN output ports instead of internal classifier signals
* Created a clean Week 16 simulation output directory
* Updated RTL dump paths to use the Week 16 folder
* Re-ran full-pipeline simulation after cleanup
* Reconfirmed Layer-2 full-pipeline outputs:
  * filter 0 output: 138
  * filter 1 output: 108
  * filter 2 output: 970
  * filter 3 output: 474
* Reconfirmed final classifier output:
  * predicted class: 2
  * score: 970
* Added latency and event-count counters to the full-pipeline testbench
* Counted the major pipeline events:
  * input pixels accepted
  * 3×3 windows generated
  * Layer-1 convolution outputs
  * pooled outputs
  * Layer-2 outputs
  * classifier outputs
* Captured key pipeline timestamps:
  * first input accepted
  * Layer-1 feature map completion
  * first Layer-2 output
  * last Layer-2 output
  * final CNN classifier valid output
* Verified expected event counts:
  * 64 input pixels accepted
  * 36 valid 3×3 windows generated
  * 144 Layer-1 convolution outputs
  * 36 pooled outputs
  * 4 Layer-2 outputs
  * 1 classifier output
* Measured end-to-end pipeline latency:
  * input to Layer-1 feature map completion: 777 cycles
  * input to first Layer-2 output: 779 cycles
  * input to last Layer-2 output: 782 cycles
  * input to final CNN valid output: 785 cycles
  * Layer-1 feature map completion to final CNN valid output: 8 cycles