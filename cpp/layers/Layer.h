// Copyright (c) Facebook, Inc. and its affiliates. All Rights Reserved.
// All rights reserved.
//
// This source code is licensed under the license found in the
// LICENSE file in the root directory of this source tree.
#pragma once

#include "FloatDefs.h"
#include "utils/Tensor.h"
#include "ops/RoundOp.h"
#include <string>

namespace facebook { namespace cl {

struct ParameterInfo {
  inline ParameterInfo()
      : param(nullptr),
        gradParam(nullptr) {
  }

  CLTensor<FloatType<kWidth>::T>* param;
  CLTensor<FloatType<kWidth>::T>* gradParam;
  std::string name;
};

class Context;
class Program;
class Queue;

struct Layer {
  Layer();

  virtual ~Layer();

  virtual std::string str() const;

  virtual void setRoundMode(RoundOp mode);
  virtual RoundOp getRoundMode() const;

  virtual CLTensor<FloatType<kWidth>::T>& forward(
    Context& context,
    Program& program,
    Queue& queue,
    const CLTensor<FloatType<kWidth>::T>& input);

  virtual CLTensor<FloatType<kWidth>::T>& updateGradInput(
    Context& context,
    Program& program,
    Queue& queue,
    const CLTensor<FloatType<kWidth>::T>& input,
    const CLTensor<FloatType<kWidth>::T>& gradOutput);

  virtual void accGradParameters(
    Context& context,
    Program& program,
    Queue& queue,
    float scale,
    const CLTensor<FloatType<kWidth>::T>& input,
    const CLTensor<FloatType<kWidth>::T>& gradOutput);

  virtual std::vector<ParameterInfo> getParameters();

  virtual void zeroGrad(Context& context,
                        Program& program,
                        Queue& queue);

  CLTensor<FloatType<kWidth>::T>& getInput();
  CLTensor<FloatType<kWidth>::T>& getOutput();

  CLTensor<FloatType<kWidth>::T> input_;
  CLTensor<FloatType<kWidth>::T> output_;
  CLTensor<FloatType<kWidth>::T> gradInput_;
  RoundOp roundMode_;
};

} } // namespace
