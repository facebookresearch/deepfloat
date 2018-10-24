// Copyright (c) Facebook, Inc. and its affiliates. All Rights Reserved.
// All rights reserved.
//
// This source code is licensed under the license found in the
// LICENSE file in the root directory of this source tree.
#include "layers/BatchNorm2d.h"

#include <cmath>
#include <sstream>
#include "FloatDefs.h"
#include "ops/TensorConvert.h"
#include "ops/TensorMath.h"
#include "ops/TensorMemory.h"
#include "ops/TensorPrint.h"

namespace facebook { namespace cl {

BatchNorm2d::BatchNorm2d(Context& context,
                         Program& program,
                         Queue& queue,
                         int planes)
    : factoredWeight_(context, {planes}),
      runningMean_(context, {planes}),
      bias_(context, {planes}),
      planes_(planes) {
  reset(context, program, queue);
}

std::string
BatchNorm2d::str() const {
  std::stringstream ss;
  ss << "BatchNorm2d (" << planes_ << ")";

  return ss.str();
}

void
BatchNorm2d::reset(Context& context,
                   Program& program,
                   Queue& queue) {
  runMemset(context, program, queue, FloatType<kWidth>::kOne, factoredWeight_);
  runMemset(context, program, queue, FloatType<kWidth>::kZero, runningMean_);
  runMemset(context, program, queue, FloatType<kWidth>::kZero, bias_);
}

void
BatchNorm2d::setParameters(Context& context,
                           Program& program,
                           Queue& queue,
                           const HostTensor<float, 1>& runningMean,
                           const HostTensor<float, 1>& runningVar,
                           const HostTensor<float, 1>& weight,
                           const HostTensor<float, 1>& bias) {
  CL_ASSERT(planes_ == runningMean.getSize(0));
  CL_ASSERT(planes_ == runningVar.getSize(0));
  CL_ASSERT(planes_ == weight.getSize(0));
  CL_ASSERT(planes_ == bias.getSize(0));

  // We calculate:
  // out = (in - mean) * (1 / sqrt(runningVar)) * w + b
  // which we refactor as :
  // out = (in - mean) * v + b
  // so v = (1 / sqrt(runningVar)) * w

  HostTensor<float, 1> v({(size_t) planes_});
  for (int i = 0; i < v.getSize(0); ++i) {
    auto rv = runningVar[i];
    auto w = weight[i];

    rv = rv > 0.0f ? 1.0f / std::sqrt(rv) : 1e10f;
    v[i] = rv * w;
  }

  factoredWeight_ = toDevicePosit<1>(context, program, queue, v);
  runningMean_ = toDevicePosit<1>(context, program, queue, runningMean);
  bias_ = toDevicePosit<1>(context, program, queue, bias);
}

CLTensor<FloatType<kWidth>::T>&
BatchNorm2d::forward(Context& context,
                     Program& program,
                     Queue& queue,
                     const CLTensor<FloatType<kWidth>::T>& input) {
  CL_ASSERT(input.getSize(1) == planes_);

  if (!output_.isSameSize(input)) {
    output_ = CLTensor<FloatType<kWidth>::T>(context, input.sizes());
  }

  input_ = input;

  // FIXME: all of this work is planewise

// For each plane, subtract

  // in - mean
  runBinaryMath(context, program, queue,
                MathArg<FloatType<kWidth>::T>(input),
                MathArg<FloatType<kWidth>::T>(runningMean_),
                MathOp::Sub,
                getRoundMode(),
                output_);

  // (in - mean) * (1 / sqrt(running_var) * w
  runBinaryMath(context, program, queue,
                MathArg<FloatType<kWidth>::T>(output_),
                MathArg<FloatType<kWidth>::T>(factoredWeight_),
                MathOp::Mul,
                getRoundMode(),
                output_);

  // (in - mean) * (1 / sqrt(running_var) * w + b
  runBinaryMath(context, program, queue,
                MathArg<FloatType<kWidth>::T>(output_),
                MathArg<FloatType<kWidth>::T>(bias_),
                MathOp::Sub,
                getRoundMode(),
                output_);

  return output_;
}

} }
