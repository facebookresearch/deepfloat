// Copyright (c) Facebook, Inc. and its affiliates. All Rights Reserved.
// All rights reserved.
//
// This source code is licensed under the license found in the
// LICENSE file in the root directory of this source tree.
#pragma once

#include "layers/Layer.h"

namespace facebook { namespace cl {

struct Add : public Layer {
  Add(Context& context,
      Program& program,
      Queue& queue,
      int inputScale,
      int addScale,
      int outputScale);

  std::string str() const override;

  // We will add this tensor upon forward
  void setAdd(CLTensor<FloatType<kWidth>::T>& add);

  void setInputScale(int scale);
  int getInputScale() const;
  void setOutputScale(int scale);
  int getOutputScale() const;
  void setAddScale(int scale);
  int getAddScale() const;

  CLTensor<FloatType<kWidth>::T>& forward(
    Context& context,
    Program& program,
    Queue& queue,
    const CLTensor<FloatType<kWidth>::T>& input) override;

  CLTensor<FloatType<kWidth>::T> add_;
  char inputScale_;
  char addScale_;
  char outputScale_;
};

} } // namespace
