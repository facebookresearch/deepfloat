// Copyright (c) Facebook, Inc. and its affiliates. All Rights Reserved.
// All rights reserved.
//
// This source code is licensed under the license found in the
// LICENSE file in the root directory of this source tree.
#include "layers/LogSoftmax.h"

#include "ops/TensorMath.h"
#include "ops/TensorMemory.h"
#include "ops/TensorPrint.h"
#include <cmath>

namespace facebook { namespace cl {

LogSoftmax::LogSoftmax(Context& context,
                       Program& program,
                       Queue& queue)
    : max_(context, {1}),
      sum_(context, {1}) {
}

std::string
LogSoftmax::str() const {
  return "LogSoftmax";
}

CLTensor<FloatType<kWidth>::T>&
LogSoftmax::forward(Context& context,
                    Program& program,
                    Queue& queue,
                    const CLTensor<FloatType<kWidth>::T>& input) {
  if (!input.isSameSize(output_)) {
    output_ = CLTensor<FloatType<kWidth>::T>(context, input.sizes());
  }

  input_ = input;

  // max_ = max(x_i)
  runReduce(context, program, queue,
            input,
            MathOp::Max,
            getRoundMode(),
            max_);

  // tmp = x_i - max(x_i)
  output_.copyFrom(queue, input);

  runBinaryMath(context, program, queue,
                MathArg<FloatType<kWidth>::T>(output_),
                MathArg<FloatType<kWidth>::T>(max_, ScalarOp::Scalar),
                MathOp::Sub,
                getRoundMode(),
                output_);

  // tmp = exp(x_i - max(x_i))
  runExp(context, program, queue, output_, output_);

  // sum_ = sum(exp(x_i - max(x_i)))
  runReduce(context, program, queue,
            output_,
            MathOp::Add,
            getRoundMode(),
            sum_);

  // sum_ = max(x_i) + log(sum_)
  runLn(context, program, queue, sum_, sum_);
  runBinaryMath(context, program, queue,
                MathArg<FloatType<kWidth>::T>(max_),
                MathArg<FloatType<kWidth>::T>(sum_),
                MathOp::Add,
                getRoundMode(),
                sum_);

  // out = x_i - (max(x_i) + log(sum_))
  output_.copyFrom(queue, input);
  runBinaryMath(context, program, queue,
                MathArg<FloatType<kWidth>::T>(output_),
                MathArg<FloatType<kWidth>::T>(sum_, ScalarOp::Scalar),
                MathOp::Sub,
                getRoundMode(),
                output_);

  return output_;
}

CLTensor<FloatType<kWidth>::T>&
LogSoftmax::updateGradInput(Context& context,
                            Program& program,
                            Queue& queue,
                            const CLTensor<FloatType<kWidth>::T>& input,
                            const CLTensor<FloatType<kWidth>::T>& gradOutput) {
  CL_ASSERT(input.isSameSize(gradOutput));
  CL_ASSERT(input.isSameInstance(input_));

  if (!gradInput_.isSameSize(gradOutput)) {
    gradInput_ = CLTensor<FloatType<kWidth>::T>(context, gradOutput.sizes());
  }

  if (!inputExp_.isSameSize(input)) {
    inputExp_ = CLTensor<FloatType<kWidth>::T>(context, input.sizes());
  }

  // gradInput = gradOutput - sum(gradOutput) * exp(output)
  // exp(output) = exp(input[i]) / sum(exp(input[j]))
  runExp(context, program, queue, input, inputExp_);

  runReduce(context, program, queue,
            inputExp_,
            MathOp::Add,
            getRoundMode(),
            sum_);

  std::cout << "inputExp_\n";
  printPositTensor(context, program, queue,
                   inputExp_);

  std::cout << "inputExp_ sum\n";
  printPositTensor(context, program, queue,
                   sum_);

  // inputExp = exp(output) = exp(input[i]) / sum(exp(input[j]))
  runBinaryMath(context, program, queue,
                MathArg<FloatType<kWidth>::T>(inputExp_),
                MathArg<FloatType<kWidth>::T>(sum_, ScalarOp::Scalar),
                MathOp::Div,
                getRoundMode(),
                inputExp_);

  std::cout << "div\n";
  printPositTensor(context, program, queue,
                   inputExp_);

  // sum_ = sum(gradOutput)
  runReduce(context, program, queue,
            gradOutput,
            MathOp::Add,
            getRoundMode(),
            sum_);

  std::cout << "sum(gradOutput)\n";
  printPositTensor(context, program, queue,
                   sum_);

  std::cout << "gradOutput\n";
  printPositTensor(context, program, queue,
                   gradOutput);

  runMemset(context, program, queue, FloatType<kWidth>::kInf, gradInput_);

  // gradOutput - sum_ * inputExp
  runMulAdd(context, program, queue,
            MathArg<FloatType<kWidth>::T>(gradOutput),
            0,
            MathArg<FloatType<kWidth>::T>(sum_, ScalarOp::Scalar),
            MathArg<FloatType<kWidth>::T>(inputExp_),
            0,
            true, // subtract
            getRoundMode(),
            0,
            gradInput_);

  std::cout << "gradInput_\n";
  printPositTensor(context, program, queue,
                   gradInput_);

  return gradInput_;
}

} }
