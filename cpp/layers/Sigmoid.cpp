// Copyright (c) Facebook, Inc. and its affiliates. All Rights Reserved.
// All rights reserved.
//
// This source code is licensed under the license found in the
// LICENSE file in the root directory of this source tree.
#include "layers/Sigmoid.h"

#include "ops/TensorMath.h"
#include <cmath>

namespace facebook { namespace cl {

Sigmoid::Sigmoid(Context& context,
                 Program& program,
                 Queue& queue) {
}

std::string
Sigmoid::str() const {
  return "Sigmoid";
}

CLTensor<FloatType<kWidth>::T>&
Sigmoid::forward(Context& context,
                 Program& program,
                 Queue& queue,
                 const CLTensor<FloatType<kWidth>::T>& input) {
  if (!input.isSameSize(output_)) {
    output_ = CLTensor<FloatType<kWidth>::T>(context, input.sizes());
  }

  input_ = input;

  runSigmoid(context, program, queue, input, output_);

  return output_;
}

CLTensor<FloatType<kWidth>::T>&
Sigmoid::updateGradInput(Context& context,
                         Program& program,
                         Queue& queue,
                         const CLTensor<FloatType<kWidth>::T>& input,
                         const CLTensor<FloatType<kWidth>::T>& gradOutput) {
  if (!gradInput_.isSameSize(input_)) {
    gradInput_ = CLTensor<FloatType<kWidth>::T>(context, input_.sizes());
  }

  // gradOutput * (1 - output) * output

  // (1 - output) = (-output + 1)
  runBinaryMath(context, program, queue,
                MathArg<FloatType<kWidth>::T>(output_),
                MathArg<FloatType<kWidth>::T>(FloatType<kWidth>::neg(FloatType<kWidth>::kOne)),
                MathOp::Mul,
                getRoundMode(),
                gradInput_);

  runBinaryMath(context, program, queue,
                MathArg<FloatType<kWidth>::T>(gradInput_),
                MathArg<FloatType<kWidth>::T>(FloatType<kWidth>::kOne),
                MathOp::Add,
                getRoundMode(),
                gradInput_);

  runBinaryMath(context, program, queue,
                MathArg<FloatType<kWidth>::T>(gradInput_),
                MathArg<FloatType<kWidth>::T>(output_),
                MathOp::Mul,
                getRoundMode(),
                gradInput_);

  runBinaryMath(context, program, queue,
                MathArg<FloatType<kWidth>::T>(gradInput_),
                MathArg<FloatType<kWidth>::T>(gradOutput),
                MathOp::Mul,
                getRoundMode(),
                gradInput_);

  return gradInput_;
}

} }
