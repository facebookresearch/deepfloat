// Copyright (c) Facebook, Inc. and its affiliates. All Rights Reserved.
// All rights reserved.
//
// This source code is licensed under the license found in the
// LICENSE file in the root directory of this source tree.
#pragma once

#include <memory>
#include "layers/Layer.h"
#include "ops/PoolOp.h"

namespace facebook { namespace cl {

struct Pool2d : public Layer {
  Pool2d(Context& context,
         Program& program,
         Queue& queue,
         int kernelHW,
         int strideHW,
         int padT,
         int padL,
         PoolOp poolType,
         int inScale,
         int outScale);

  void setInputScale(int scale);
  int getInputScale() const;
  void setOutputScale(int scale);
  int getOutputScale() const;

  std::string str() const override;

  CLTensor<FloatType<kWidth>::T>& forward(
    Context& context,
    Program& program,
    Queue& queue,
    const CLTensor<FloatType<kWidth>::T>& in) override;

  CLTensor<FloatType<kWidth>::T>& updateGradInput(
    Context& context,
    Program& program,
    Queue& queue,
    const CLTensor<FloatType<kWidth>::T>& input,
    const CLTensor<FloatType<kWidth>::T>& gradOutput) override;

  int kernelHW_;
  int strideHW_;
  int padT_;
  int padL_;
  PoolOp poolType_;
  int inputScale_;
  int outputScale_;
};

} } // namespace
