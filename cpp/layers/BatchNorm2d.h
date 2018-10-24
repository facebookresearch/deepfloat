// Copyright (c) Facebook, Inc. and its affiliates. All Rights Reserved.
// All rights reserved.
//
// This source code is licensed under the license found in the
// LICENSE file in the root directory of this source tree.
#pragma once

#include <memory>
#include "layers/Layer.h"

namespace facebook { namespace cl {

struct BatchNorm2d : public Layer {
  BatchNorm2d(Context& context,
              Program& program,
              Queue& queue,
              int planes);

  std::string str() const override;

  void reset(Context& context,
             Program& program,
             Queue& queue);

  void setParameters(Context& context,
                     Program& program,
                     Queue& queue,
                     const HostTensor<float, 1>& runningMean,
                     const HostTensor<float, 1>& runningVar,
                     const HostTensor<float, 1>& weight,
                     const HostTensor<float, 1>& bias);

  CLTensor<FloatType<kWidth>::T>& forward(
    Context& context,
    Program& program,
    Queue& queue,
    const CLTensor<FloatType<kWidth>::T>& in) override;

  CLTensor<FloatType<kWidth>::T> factoredWeight_;
  CLTensor<FloatType<kWidth>::T> runningMean_;
  CLTensor<FloatType<kWidth>::T> bias_;

  int planes_;
};

} } // namespace
