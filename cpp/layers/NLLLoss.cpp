// Copyright (c) Facebook, Inc. and its affiliates. All Rights Reserved.
// All rights reserved.
//
// This source code is licensed under the license found in the
// LICENSE file in the root directory of this source tree.
#include "layers/NLLLoss.h"

#include "ops/TensorMath.h"
#include "ops/TensorMemory.h"
#include "ops/TensorPrint.h"
#include <cmath>

namespace facebook { namespace cl {

NLLLoss::NLLLoss(Context& context,
                 Program& program,
                 Queue& queue)
    : sizeAverage_(true),
      roundMode_(RoundOp::R2NE) {
}

std::string
NLLLoss::str() const {
  return "NLLLoss";
}

void
NLLLoss::setWeight(CLTensor<FloatType<kWidth>::T> weight) {
  weight_.reset(new CLTensor<FloatType<kWidth>::T>(std::move(weight)));
}

void
NLLLoss::setSizeAverage(bool b) {
  sizeAverage_ = b;
}

void
NLLLoss::setRoundMode(RoundOp mode) {
  roundMode_ = mode;
}

RoundOp
NLLLoss::getRoundMode() const {
  return roundMode_;
}


CLTensor<FloatType<kWidth>::T>&
NLLLoss::forward(Context& context,
                 Program& program,
                 Queue& queue,
                 const CLTensor<FloatType<kWidth>::T>& input,
                 const CLTensor<unsigned int>& target) {
  CL_ASSERT(input.dims() <= 2);
  CL_ASSERT(target.dims() == 1);
  auto batchSize = input.dims() == 1 ? (size_t) 1 : input.getSize(0);
  auto classSize = input.dims() == 1 ? input.getSize(0) : input.getSize(1);
  CL_ASSERT(target.getSize(0) == batchSize);

  if ((bool) weight_) {
    CL_ASSERT(weight_->getSize(0) == classSize);
  }

  if (output_.dims() != 1 || output_.getSize(0) != batchSize) {
    output_ = CLTensor<FloatType<kWidth>::T>(context, {batchSize});
  }

  // Place input[target[i]] in output_
  runGather(context, program, queue,
            input,
            target,
            FloatType<kWidth>::kMax,
            output_);

  // If we have weights, place weight[target[i]] in weightGather
  auto weightGather = CLTensor<FloatType<kWidth>::T>(context, {batchSize});
  if ((bool) weight_) {
    runGather(context, program, queue,
              *weight_, target, FloatType<kWidth>::kZero, weightGather);

    // output_ = input[target[i]] * weight[target[i]]
    runBinaryMath(context, program, queue,
                  MathArg<FloatType<kWidth>::T>(output_),
                  MathArg<FloatType<kWidth>::T>(weightGather),
                  MathOp::Mul,
                  getRoundMode(),
                  output_);
  }

  if (sizeAverage_) {
    if (totalWeight_.dims() == 0) {
      totalWeight_ = CLTensor<FloatType<kWidth>::T>(context, {1});
    }

    if ((bool) weight_) {
      // Sum all gathered weights
      runReduce(context, program, queue,
                weightGather,
                MathOp::Add,
                getRoundMode(),
                totalWeight_);
    } else {
      // sum_j weight[target[i]]
      auto weightSumFloatHost = HostTensor<float, 1>({1});
      weightSumFloatHost[0] = (float) batchSize;

      auto weightSumFloatDevice = CLTensor<float>(context, {1});
      weightSumFloatDevice.copyFrom(queue, weightSumFloatHost);

      runToPosit8(context, program, queue,
                  weightSumFloatDevice, totalWeight_);
    }

    // div by totalWeight_ scalar

    // weight_:  input[target[i]] * weight[target[i]] / sum_j weight[target[i]]
    // !weight_: input[target[i]] / batchSize
    runBinaryMath(context, program, queue,
                  MathArg<FloatType<kWidth>::T>(output_),
                  MathArg<FloatType<kWidth>::T>(totalWeight_, ScalarOp::Scalar),
                  MathOp::Div,
                  getRoundMode(),
                  output_);
  }

  // negate
  runBinaryMath(context, program, queue,
                MathArg<FloatType<kWidth>::T>(output_),
                MathArg<FloatType<kWidth>::T>(FloatType<kWidth>::neg(FloatType<kWidth>::kOne)),
                MathOp::Mul,
                getRoundMode(),
                output_);

  return output_;
}

CLTensor<FloatType<kWidth>::T>&
NLLLoss::updateGradInput(Context& context,
                         Program& program,
                         Queue& queue,
                         const CLTensor<FloatType<kWidth>::T>& input,
                         const CLTensor<unsigned int>& target) {
  if (!gradInput_.isSameSize(input)) {
    gradInput_ = CLTensor<FloatType<kWidth>::T>(context, input.sizes());
  }

  auto batchSize = input.dims() == 1 ? (size_t) 1 : input.getSize(0);
  CL_ASSERT(batchSize == target.getSize(0));

  // zero out gradInput_
  runMemset(context, program, queue, FloatType<kWidth>::kZero, gradInput_);

  // FIXME: if total weight <= 0 do nothing

  // !sizeAverage:
  // gradInput[batch][target[i]] = -weight[target[i]] * gradOutput
  // sizeAverage 1d:
  // gradInput[target[i]] = -1 * gradOutput
  // sizeAverage 2d:
  // gradInput[batch][target[i]] = (-weight[target[i]] * gradOutput) / totalWeight

  // Gather all weights used
  // gradOutput is implicit 1s
  auto gradOutput = CLTensor<FloatType<kWidth>::T>(context, {batchSize});
  if ((bool) weight_) {
    runGather(context, program, queue,
              *weight_, target, FloatType<kWidth>::kZero, gradOutput);

    // -weight[target[i]] * gradOutput
    runBinaryMath(context, program, queue,
                  MathArg<FloatType<kWidth>::T>(gradOutput),
                  MathArg<FloatType<kWidth>::T>(FloatType<kWidth>::neg(FloatType<kWidth>::kOne)),
                  MathOp::Mul,
                  getRoundMode(),
                  gradOutput);
  } else {
    // fill with -1s
    runMemset(context, program, queue,
              FloatType<kWidth>::neg(FloatType<kWidth>::kOne), gradOutput);
  }

  if (sizeAverage_) {
    runBinaryMath(context, program, queue,
                  MathArg<FloatType<kWidth>::T>(gradOutput),
                  MathArg<FloatType<kWidth>::T>(totalWeight_, ScalarOp::Scalar),
                  MathOp::Div,
                  getRoundMode(),
                  gradOutput);
  }

  // Scatter gradOutput into gradInput based on targets
  runScatter(context, program, queue,
             gradOutput, target, FloatType<kWidth>::kInf, gradInput_);

  return gradInput_;
}

} }
