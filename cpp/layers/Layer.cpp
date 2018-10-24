// Copyright (c) Facebook, Inc. and its affiliates. All Rights Reserved.
// All rights reserved.
//
// This source code is licensed under the license found in the
// LICENSE file in the root directory of this source tree.
#include "layers/Layer.h"

namespace facebook { namespace cl {

Layer::Layer()
    : roundMode_(RoundOp::R2NE) {
}

Layer::~Layer() {
}

std::string
Layer::str() const {
  CL_ASSERT_MSG(false, "NYI");
  return "Layer";
}

void
Layer::setRoundMode(RoundOp mode) {
  roundMode_ = mode;
}

RoundOp
Layer::getRoundMode() const {
  return roundMode_;
}

CLTensor<FloatType<kWidth>::T>&
Layer::forward(
  Context& context,
  Program& program,
  Queue& queue,
  const CLTensor<FloatType<kWidth>::T>& input) {
  CL_ASSERT_MSG(false, "unimplemented");
  return output_;
}

CLTensor<FloatType<kWidth>::T>&
Layer::updateGradInput(
  Context& context,
  Program& program,
  Queue& queue,
  const CLTensor<FloatType<kWidth>::T>& input,
  const CLTensor<FloatType<kWidth>::T>& gradOutput) {
  CL_ASSERT_MSG(false, "unimplemented");
  return gradInput_;
}

void
Layer::accGradParameters(
  Context& context,
  Program& program,
  Queue& queue,
  float scale,
  const CLTensor<FloatType<kWidth>::T>& input,
  const CLTensor<FloatType<kWidth>::T>& gradOutput) {
}

std::vector<ParameterInfo>
Layer::getParameters() {
  return std::vector<ParameterInfo>();
}

void
Layer::zeroGrad(Context& context,
                Program& program,
                Queue& queue) {
}

CLTensor<FloatType<kWidth>::T>&
Layer::getInput() {
  return input_;
}

CLTensor<FloatType<kWidth>::T>&
Layer::getOutput() {
  return output_;
}

} }
