// Copyright (c) Facebook, Inc. and its affiliates. All Rights Reserved.
// All rights reserved.
//
// This source code is licensed under the license found in the
// LICENSE file in the root directory of this source tree.
#pragma once

#include <memory>
#include "layers/Layer.h"

namespace facebook { namespace cl {

struct Linear : public Layer {
  Linear(Context& context,
         Program& program,
         Queue& queue,
         int inFeatures,
         int outFeatures,
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
                     const HostTensor<float, 2>& weight);

  void setWeight(Context& context,
                 Program& program,
                 Queue& queue,
                 const CLTensor<FloatType<kWidth>::T>& weight);

  void setBiasHost(Context& context,
               Program& program,
               Queue& queue,
               const HostTensor<float, 1>& bias);

  void setBias(Context& context,
               Program& program,
               Queue& queue,
               const CLTensor<FloatType<kWidth>::T>& bias);

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
  // FIXME: implement transposed MM
  CLTensor<FloatType<kWidth>::T> weightTranspose_;
  std::unique_ptr<CLTensor<FloatType<kWidth>::T>> bias_;

  CLTensor<FloatType<kWidth>::T> gradWeight_;
  std::unique_ptr<CLTensor<FloatType<kWidth>::T>> gradBias_;

  int inFeatures_;
  int outFeatures_;
  char inputScale_;
  char outputScale_;
};

} } // namespace
