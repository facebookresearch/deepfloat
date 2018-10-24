// Copyright (c) Facebook, Inc. and its affiliates. All Rights Reserved.
// All rights reserved.
//
// This source code is licensed under the license found in the
// LICENSE file in the root directory of this source tree.
#include "layers/Pool2d.h"

#include <cmath>
#include <sstream>
#include "ops/TensorConv.h"
#include "ops/TensorPrint.h"

namespace facebook { namespace cl {

Pool2d::Pool2d(Context& context,
               Program& program,
               Queue& queue,
               int kernelHW,
               int strideHW,
               int padT,
               int padL,
               PoolOp poolType,
               int inScale,
               int outScale)
    : kernelHW_(kernelHW),
      strideHW_(strideHW),
      padT_(padT),
      padL_(padL),
      poolType_(poolType),
      inputScale_(inScale),
      outputScale_(outScale) {
}

void
Pool2d::setInputScale(int scale) {
  inputScale_ = scale;
}

int
Pool2d::getInputScale() const {
  return inputScale_;
}

void
Pool2d::setOutputScale(int scale) {
  outputScale_ = scale;
}

int
Pool2d::getOutputScale() const {
  return outputScale_;
}

std::string
Pool2d::str() const {
  std::stringstream ss;
  ss << "Pool2d ("
     << (poolType_ == PoolOp::Avg ? "avg" : "max")
     << " size (" << kernelHW_
     << ", " << kernelHW_
     << ") st " << strideHW_
     << ", " << strideHW_
     << ") pad (" << padT_
     << ", " << padL_
     << "))";

  return ss.str();
}

CLTensor<FloatType<kWidth>::T>&
Pool2d::forward(Context& context,
                Program& program,
                Queue& queue,
                const CLTensor<FloatType<kWidth>::T>& input) {
  size_t outputH =
    calcKernelOutputSize(input.getSize(2), padT_, padT_, kernelHW_, strideHW_);
  size_t outputW =
    calcKernelOutputSize(input.getSize(3), padL_, padL_, kernelHW_, strideHW_);

  CL_ASSERT(input.dims() == 4);

  if (output_.dims() != 4 ||
      output_.getSize(0) != input.getSize(0) ||
      output_.getSize(1) != input.getSize(1) ||
      output_.getSize(2) != outputH ||
      output_.getSize(3) != outputW) {
    output_ = CLTensor<FloatType<kWidth>::T>(context,
                               {input.getSize(0),
                                   input.getSize(1),
                                   outputH,
                                   outputW});
  }

  runForwardPool2dNCHW(context, program, queue,
                       input,
                       poolType_,
                       kernelHW_,
                       padT_,
                       padL_,
                       strideHW_,
                       getRoundMode(),
                       inputScale_,
                       outputScale_,
                       output_);

  return output_;
}

CLTensor<FloatType<kWidth>::T>&
Pool2d::updateGradInput(Context& context,
                        Program& program,
                        Queue& queue,
                        const CLTensor<FloatType<kWidth>::T>& input,
                        const CLTensor<FloatType<kWidth>::T>& gradOutput) {
  return gradInput_;
}

} }
