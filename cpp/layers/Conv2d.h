// Copyright (c) Facebook, Inc. and its affiliates. All Rights Reserved.
// All rights reserved.
//
// This source code is licensed under the license found in the
// LICENSE file in the root directory of this source tree.
#pragma once

#include <memory>
#include "layers/Layer.h"

namespace facebook { namespace cl {

struct Conv2d : public Layer {
  Conv2d(Context& context,
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
         int outputScale);

  std::string str() const override;

  void setInputScale(int scale);
  int getInputScale() const;
  void setOutputScale(int scale);
  int getOutputScale() const;

  void reset(Context& context,
             Program& program,
             Queue& queue);

  void setWeightHost(Context& context,
                     Program& program,
                     Queue& queue,
                     const HostTensor<float, 4>& weight);

  void setWeight(Context& context,
                 Program& program,
                 Queue& queue,
                 const CLTensor<FloatType<kWidth>::T>& weight);

  const CLTensor<FloatType<kWidth>::T>& getWeight() const;

  void setBiasHost(Context& context,
                   Program& program,
                   Queue& queue,
                   const HostTensor<float, 1>& bias);

  void setBias(Context& context,
               Program& program,
               Queue& queue,
               const CLTensor<FloatType<kWidth>::T>& bias);

  const CLTensor<FloatType<kWidth>::T>* getBias() const;

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

  void accGradParameters(
    Context& context,
    Program& program,
    Queue& queue,
    float scale,
    const CLTensor<FloatType<kWidth>::T>& input,
    const CLTensor<FloatType<kWidth>::T>& gradOutput) override;

  std::vector<ParameterInfo> getParameters() override;

  void zeroGrad(Context& context,
                Program& program,
                Queue& queue) override;

  CLTensor<FloatType<kWidth>::T> weight_;
  std::unique_ptr<CLTensor<FloatType<kWidth>::T>> bias_;
  CLTensor<FloatType<kWidth>::T> workspace_;

  int inPlane_;
  int outPlane_;
  int kernelHW_;
  int strideHW_;
  int padT_;
  int padL_;
  char inputScale_;
  char outputScale_;
};

} } // namespace
