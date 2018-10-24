// Copyright (c) Facebook, Inc. and its affiliates. All Rights Reserved.
// All rights reserved.
//
// This source code is licensed under the license found in the
// LICENSE file in the root directory of this source tree.
#pragma once

#include "layers/Layer.h"

namespace facebook { namespace cl {

struct View : public Layer {
  View(Context& context,
       Program& program,
       Queue& queue,
       const std::vector<std::vector<int>>& newDims);

  std::string str() const override;

  CLTensor<FloatType<kWidth>::T>& forward(
    Context& context,
    Program& program,
    Queue& queue,
    const CLTensor<FloatType<kWidth>::T>& in) override;

  std::vector<std::vector<int>> newDims_;
};

} } // namespace
