// Copyright (c) Facebook, Inc. and its affiliates. All Rights Reserved.
// All rights reserved.
//
// This source code is licensed under the license found in the
// LICENSE file in the root directory of this source tree.
#include "layers/View.h"

namespace facebook { namespace cl {

View::View(Context& context,
           Program& program,
           Queue& queue,
           const std::vector<std::vector<int>>& newDims)
    : newDims_(newDims) {
}

std::string
View::str() const {
  return "View";
}

CLTensor<FloatType<kWidth>::T>&
View::forward(Context& context,
              Program& program,
              Queue& queue,
              const CLTensor<FloatType<kWidth>::T>& input) {
  std::vector<size_t> newSizes;
  for (auto& ds : newDims_) {
    size_t size = 1;
    for (auto d : ds) {
      size *= input.getSize(d);
    }

    newSizes.push_back(size);
  }

  output_ = input.view(newSizes);
  return output_;
}

} }
