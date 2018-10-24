// Copyright (c) Facebook, Inc. and its affiliates. All Rights Reserved.
// All rights reserved.
//
// This source code is licensed under the license found in the
// LICENSE file in the root directory of this source tree.
#pragma once

#include "layers/Layer.h"

namespace facebook { namespace cl {

struct Sigmoid : public Layer {
  Sigmoid(Context& context,
          Program& program,
          Queue& queue);

  std::string str() const;

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
};

} } // namespace
