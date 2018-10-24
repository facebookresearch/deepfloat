// Copyright (c) Facebook, Inc. and its affiliates. All Rights Reserved.
// All rights reserved.
//
// This source code is licensed under the license found in the
// LICENSE file in the root directory of this source tree.
#pragma once

#include "FloatDefs.h"
#include "utils/Event.h"
#include "utils/Tensor.h"
#include "ops/PoolOp.h"
#include "ops/RoundOp.h"

/// Collection of convnet routines

namespace facebook { namespace cl {

class Context;
class Program;
class Queue;

template <typename T, typename U>
constexpr T calcKernelOutputSize(T inSize, U padBefore, U padAfter,
                                 U kernel, U stride) {
  return ((inSize + (T) padBefore +
           (T) padAfter - (T) kernel) / (T) stride) + (T) 1;
}

// Input is [batch][channel][height][width]
// Output is [batch][channel x kHW x kHW][output height x output width]
Event
runIm2ColNCHW(Context& context,
              Program& program,
              Queue& queue,
              const CLTensor<FloatType<kWidth>::T>& in,
              unsigned int kHW,
              unsigned int padT,
              unsigned int padL,
              unsigned int strideHW,
              CLTensor<FloatType<kWidth>::T>& out);

// Input is [batch][channel][height][width]
// Output is [batch][channel][output height][output width]
Event
runForwardPool2dNCHW(Context& context,
                     Program& program,
                     Queue& queue,
                     const CLTensor<FloatType<kWidth>::T>& in,
                     PoolOp poolType,
                     int kHW,
                     int padT,
                     int padL,
                     int strideHW,
                     RoundOp rounding,
                     char inScale,
                     char outScale,
                     CLTensor<FloatType<kWidth>::T>& out);

// Performs 2-d forward convolution
// Input is [batch][input channel][height][width]
// Output is [batch][output channel][height][width]
// Weight is [output channel][input channel][kh][kw]
// Bias (optional) is [output channel]
Event
runForwardConv2dNCHW(Context& context,
                     Program& program,
                     Queue& queue,
                     const CLTensor<FloatType<kWidth>::T>& in,
                     CLTensor<FloatType<kWidth>::T>& workspace,
                     const CLTensor<FloatType<kWidth>::T>& ker,
                     const CLTensor<FloatType<kWidth>::T>* bias,
                     int padT,
                     int padL,
                     int strideHW,
                     RoundOp rounding,
                     char inScale,
                     char outScale,
                     CLTensor<FloatType<kWidth>::T>& out);

} }
