// Copyright (c) Facebook, Inc. and its affiliates. All Rights Reserved.
// All rights reserved.
//
// This source code is licensed under the license found in the
// LICENSE file in the root directory of this source tree.
#include "layers/Conv2d.h"

#include <cmath>
#include <sstream>
#include "ops/TensorConv.h"
#include "ops/TensorMath.h"
#include "ops/TensorMemory.h"
#include "ops/TensorPrint.h"

namespace facebook { namespace cl {

Conv2d::Conv2d(Context& context,
               Program& program,
               Queue& queue,
               int inPlane,
               int outPlane,
               int kernelHW,
               int strideHW,
               int padT,
               int padL,
               bool bias,
               int inputScale,
               int outputScale)
    : weight_(context, {outPlane, inPlane, kernelHW, kernelHW}),
      bias_(bias ? new CLTensor<FloatType<kWidth>::T>(context, {outPlane}) : nullptr),
      inPlane_(inPlane),
      outPlane_(outPlane),
      kernelHW_(kernelHW),
      strideHW_(strideHW),
      padT_(padT),
      padL_(padL),
      inputScale_(inputScale),
      outputScale_(outputScale) {
  reset(context, program, queue);
}

std::string
Conv2d::str() const {
  std::stringstream ss;
  ss << "Conv2d (in " << inPlane_
     << " out " << outPlane_
     << " ker (" << kernelHW_
     << ", " << kernelHW_
     << ") st (" << strideHW_
     << ", " << strideHW_
     << ") pad (" << padT_
     << ", " << padL_
     << "))";

  return ss.str();
}

void
Conv2d::setInputScale(int scale) {
  inputScale_ = scale;
}

int
Conv2d::getInputScale() const {
  return inputScale_;
}

void
Conv2d::setOutputScale(int scale) {
  outputScale_ = scale;
}

int
Conv2d::getOutputScale() const {
  return outputScale_;
}

void
Conv2d::reset(Context& context,
              Program& program,
              Queue& queue) {
  float stdv = 1.0f / std::sqrt((float) kernelHW_ * inPlane_);
  runUniform(context, program, queue, -stdv, stdv, weight_);

  if (bias_) {
    runUniform(context, program, queue, -stdv, stdv, *bias_);
  }
}

void
Conv2d::setWeightHost(Context& context,
                      Program& program,
                      Queue& queue,
                      const HostTensor<float, 4>& weight) {
  CL_ASSERT(weight.isSize({outPlane_, inPlane_, kernelHW_, kernelHW_}));

  CLTensor<float> tmp(context, queue, weight);
  runToPosit8(context, program, queue, tmp, weight_);
}

void
Conv2d::setWeight(Context& context,
                  Program& program,
                  Queue& queue,
                  const CLTensor<FloatType<kWidth>::T>& weight) {
  CL_ASSERT(weight.isSize({outPlane_, inPlane_, kernelHW_, kernelHW_}));

  weight_ = weight;
}

const CLTensor<FloatType<kWidth>::T>&
Conv2d::getWeight() const {
  return weight_;
}

void
Conv2d::setBiasHost(Context& context,
                    Program& program,
                    Queue& queue,
                    const HostTensor<float, 1>& bias) {
  CL_ASSERT(bias.isSize({outPlane_}));

  CLTensor<float> tmp(context, queue, bias);
  if (!bias_) {
    bias_.reset(new CLTensor<FloatType<kWidth>::T>(context, {outPlane_}));
  }

  runToPosit8(context, program, queue, tmp, *bias_);
}

void
Conv2d::setBias(Context& context,
                Program& program,
                Queue& queue,
                const CLTensor<FloatType<kWidth>::T>& bias) {
  CL_ASSERT(bias.isSize({outPlane_}));

  if (!bias_) {
    bias_.reset(new CLTensor<FloatType<kWidth>::T>(context, {outPlane_}));
  }

  *bias_ = bias;
}

const CLTensor<FloatType<kWidth>::T>*
Conv2d::getBias() const {
  return bias_.get();
}

CLTensor<FloatType<kWidth>::T>&
Conv2d::forward(Context& context,
                Program& program,
                Queue& queue,
                const CLTensor<FloatType<kWidth>::T>& input) {
  size_t outputH =
    calcKernelOutputSize(input.getSize(2), padT_, padT_, kernelHW_, strideHW_);
  size_t outputW =
    calcKernelOutputSize(input.getSize(3), padL_, padL_, kernelHW_, strideHW_);

  CL_ASSERT(input.dims() == 4);
  CL_ASSERT(input.getSize(1) == inPlane_);

  if (output_.dims() != 4 ||
      output_.getSize(0) != input.getSize(0) ||
      output_.getSize(1) != outPlane_ ||
      output_.getSize(2) != outputH ||
      output_.getSize(3) != outputW) {
    output_ = CLTensor<FloatType<kWidth>::T>(context,
                               {input.getSize(0),
                                   (size_t) outPlane_,
                                   outputH,
                                   outputW});
  }

  runForwardConv2dNCHW(context, program, queue,
                       input,
                       workspace_,
                       weight_,
                       bias_.get(),
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
Conv2d::updateGradInput(Context& context,
                        Program& program,
                        Queue& queue,
                        const CLTensor<FloatType<kWidth>::T>& input,
                        const CLTensor<FloatType<kWidth>::T>& gradOutput) {
  return gradInput_;
}

void
Conv2d::accGradParameters(Context& context,
                          Program& program,
                          Queue& queue,
                          float scale,
                          const CLTensor<FloatType<kWidth>::T>& input,
                          const CLTensor<FloatType<kWidth>::T>& gradOutput) {
  CL_ASSERT(false);
}

std::vector<ParameterInfo>
Conv2d::getParameters() {
  std::vector<ParameterInfo> params;

  ParameterInfo info;
  info.param = &weight_;
  info.gradParam = nullptr; // FIXME
  info.name = str() + " W";
  params.emplace_back(std::move(info));

  if (bias_) {
    ParameterInfo info;
    info.param = bias_.get();
    info.gradParam = nullptr; // FIXME
    info.name = str() + " bias";
    params.emplace_back(std::move(info));
  }

  return params;
}

void
Conv2d::zeroGrad(Context& context,
                 Program& program,
                 Queue& queue) {
}

} }
