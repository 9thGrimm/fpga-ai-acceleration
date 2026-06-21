Date: Week 15

Topic: Classifier / Decision Stage Integration

* Started Week 15 by extending the verified Layer-1 → Layer-2 CNN pipeline with a decision stage
* Added a simple Python classifier golden model using argmax over the Layer-2 output vector
* Used the verified Layer-2 output vector as classifier input:
  * filter 0 output: 138
  * filter 1 output: 108
  * filter 2 output: 970
  * filter 3 output: 474
* Confirmed the Python classifier selects:
  * predicted class: 2
  * max score: 970
* Implemented standalone `classifier_argmax` RTL block
* Designed the classifier to compare multiple output logits and return:
  * predicted class index
  * maximum score value
* Created a standalone SystemVerilog testbench for classifier verification
* Verified standalone classifier RTL against the Python expected result
* Integrated the classifier after the Layer-2 convolution engine in the full CNN top module
* Added buffering for Layer-2 outputs before starting classifier execution
* Ensured the classifier starts only after all Layer-2 outputs are captured
* Updated the full-pipeline testbench to capture classifier output
* Added RTL output dumping for the full-pipeline classifier result
* Added Python-side comparison for the full-pipeline classifier output
* Revalidated that earlier pipeline stages still pass after classifier integration:
  * Layer-1 raw convolution
  * Layer-1 quantized convolution
  * Layer-1 pooled feature map
  * Layer-2 output vector
* Verified full pipeline classifier result against Python golden model
* Confirmed full CNN pipeline now produces a final predicted class from the original I/Q input stream