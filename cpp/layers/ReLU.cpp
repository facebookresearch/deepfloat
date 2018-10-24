// Copyright (c) Facebook, Inc. and its affiliates. All Rights Reserved.
// All rights reserved.
//
// This source code is licensed under the license found in the
// LICENSE file in the root directory of this source tree.
#include "layers/ReLU.h"

#include "ops/TensorMath.h"
#include <cmath>

namespace facebook { namespace cl {

ReLU::ReLU(Context& context,
           Program& program,
           Queue& queue) {
}

std::string
ReLU::str() const {
  return "ReLU";
}

CLTensor<FloatType<kWidth>::T>&
ReLU::forward(Context& context,
              Program& program,
              Queue& queue,
              const CLTensor<FloatType<kWidth>::T>& input) {
  if (!output_.isSameSize(input)) {
    output_ = CLTensor<FloatType<kWidth>::T>(context, input.sizes());
  }

  input_ = input;

  runBinaryMath(context, program, queue,
                MathArg<FloatType<kWidth>::T>(input),
                MathArg<FloatType<kWidth>::T>(FloatType<kWidth>::kZero),
                MathOp::Max,
                getRoundMode(),
                output_);

  return output_;
}

CLTensor<FloatType<kWidth>::T>&
ReLU::updateGradInput(Context& context,
                      Program& program,
                      Queue& queue,
                      const CLTensor<FloatType<kWidth>::T>& input,
                      const CLTensor<FloatType<kWidth>::T>& gradOutput) {
  CL_ASSERT(input.isSameSize(gradOutput));
  CL_ASSERT(input.isSameInstance(input_));

  if (!gradInput_.isSameSize(gradOutput)) {
    gradInput_ = CLTensor<FloatType<kWidth>::T>(context, gradOutput.sizes());
  }

  // gradInput = input > 0 ? gradOutput : 0
  runThresholdScalarHost(context, program, queue,
                         input, FloatType<kWidth>::kZero, gradOutput,
                         CompareOp::GT, gradInput_);

  return gradInput_;
}

} }
