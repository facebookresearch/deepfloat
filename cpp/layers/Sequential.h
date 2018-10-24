// Copyright (c) Facebook, Inc. and its affiliates. All Rights Reserved.
// All rights reserved.
//
// This source code is licensed under the license found in the
// LICENSE file in the root directory of this source tree.
#pragma once

#include <memory>
#include <vector>
#include "layers/Layer.h"

namespace facebook { namespace cl {

enum class LogLevel { Basic, Full };

struct Sequential : public Layer {
  Sequential(const std::string& name = "");

  // Sequential(Sequential&) = delete;
  // Sequential& operator=(Sequential&) = delete;

  void log(bool b);

  std::string str() const;

  size_t numLayers() const;
  Layer& getLayer(int i);

  void setRoundMode(RoundOp mode) override;
  RoundOp getRoundMode() const override;

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

  template <typename LayerT>
  void add(LayerT l) {
    layers_.push_back(std::unique_ptr<Layer>(new LayerT(std::move(l))));
  }

  std::string name_;
  bool log_;
  std::vector<std::unique_ptr<Layer>> layers_;
};

} } // namespace
