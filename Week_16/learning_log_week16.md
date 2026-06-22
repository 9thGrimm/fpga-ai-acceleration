Date: Week 16

Topic: Printing Debug Clean-up and Latency Counters Incorporation

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
* Confirmed that the full pipeline still passes after adding cleanup and metrics logic

* Added a dedicated metrics output file:
  * `rtl_metrics.txt`
* Added a new file handle in the full-pipeline testbench:
  * `f_metrics`
* Opened the metrics file in the Week 16 output directory
* Added the metrics file handle to the output-file open error check
* Added `$fwrite` support for saving the same pipeline metrics that are printed to the console
* Saved event-count metrics to file:
  * input pixels accepted: 64
  * 3×3 windows generated: 36
  * Layer-1 convolution outputs: 144
  * pooled outputs: 36
  * Layer-2 outputs: 4
  * classifier outputs: 1
* Saved cycle timestamp metrics to file:
  * first input cycle: 2
  * feature map done cycle: 779
  * first Layer-2 output cycle: 781
  * last Layer-2 output cycle: 784
  * final CNN valid cycle: 787
* Saved latency metrics to file:
  * input to feature map completion: 777 cycles
  * input to first Layer-2 output: 779 cycles
  * input to last Layer-2 output: 782 cycles
  * input to final CNN valid output: 785 cycles
  * feature map completion to final CNN valid output: 8 cycles
* Verified that `rtl_metrics.txt` is generated correctly
* Confirmed that the saved metrics match the console metrics
* Confirmed that the full CNN pipeline remains functionally correct after adding the metrics file dump

## Current Verified Pipeline Result

* Layer-2 logits:
  * `[138, 108, 970, 474]`
* Final classifier output:
  * class: 2
  * score: 970
* End-to-end latency for current 8×8 I/Q test:
  * 785 cycles
  * 7.85 us at a 100 MHz clock

* Performed the final Week 16 end-to-end rerun before closing the week
* Re-ran the RTL full-pipeline simulation to regenerate all Week 16 output files
* Confirmed that the full CNN pipeline still produces the expected final classifier result:
  * predicted class: 2
  * score: 970
* Updated the Python golden model to read RTL dump files from the Week 16 output directory
* Added an absolute Week 16 base directory for all RTL verification files
* Added an RTL file path helper to print the exact file being loaded
* Added file-size and loaded-shape debug prints for RTL dump files
* Fixed the stale relative-path issue where Python could accidentally read old or empty local files
* Added support for reading and printing `rtl_metrics.txt`
* Integrated RTL pipeline metrics into the Python verification flow
* Confirmed that the Python script now reports both:
  * functional correctness checks
  * RTL latency and event-count metrics
* Verified pooled feature map comparison:
  * RTL pooled feature map matches Python pooled feature map
  * pooled feature map comparison: PASS
* Verified final RTL pipeline metrics:
  * input pixels accepted: 64
  * 3×3 windows generated: 36
  * Layer-1 convolution outputs: 144
  * pooled outputs: 36
  * Layer-2 outputs: 4
  * classifier outputs: 1
* Verified latency metrics:
  * input to feature map completion: 777 cycles
  * input to first Layer-2 output: 779 cycles
  * input to last Layer-2 output: 782 cycles
  * input to final CNN valid output: 785 cycles
  * feature map completion to final CNN valid output: 8 cycles
* Confirmed that the final Python verification flow prints the RTL metrics successfully

## Week 16 Final Conclusion

* Simulation debug output is clean
* Final CNN outputs are exposed at the top level
* Full Layer-1 → Layer-2 → classifier CNN pipeline remains functionally correct
* Latency and event counters are integrated into the RTL testbench
* Metrics are printed to the simulation console
* Metrics are saved automatically to `rtl_metrics.txt`
* Python golden model reads the correct Week 16 RTL dump files
* Python verification now reports both correctness and performance metrics
* Week 16 cleanup, metrics, and verification-flow integration is complete