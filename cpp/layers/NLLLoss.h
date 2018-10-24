// Copyright (c) Facebook, Inc. and its affiliates. All Rights Reserved.
// All rights reserved.
//
// This source code is licensed under the license found in the
// LICENSE file in the root directory of this source tree.
#pragma once

#include "layers/Layer.h"
#include "ops/RoundOp.h"

namespace facebook { namespace cl {

struct NLLLoss {
  NLLLoss(Context& context,
          Program& program,
          Queue& queue);

  std::string str() const;

  void setWeight(CLTensor<FloatType<kWidth>::T> weight);

  void setSizeAverage(bool b);

  void setRoundMode(RoundOp mode);
  RoundOp getRoundMode() const;

  CLTensor<FloatType<kWidth>::T>& forward(Context& context,
                            Program& program,
                            Queue& queue,
                            const CLTensor<FloatType<kWidth>::T>& input,
                            const CLTensor<unsigned int>& target);

  CLTensor<FloatType<kWidth>::T>& updateGradInput(Context& context,
                                    Program& program,
                                    Queue& queue,
                                    const CLTensor<FloatType<kWidth>::T>& input,
                                    const CLTensor<unsigned int>& target);

  bool sizeAverage_;

  /// The user-defined weight if available
  std::unique_ptr<CLTensor<FloatType<kWidth>::T>> weight_;
  CLTensor<FloatType<kWidth>::T> output_;
  CLTensor<FloatType<kWidth>::T> gradInput_;

  // sum of weights used
  CLTensor<FloatType<kWidth>::T> totalWeight_;

  RoundOp roundMode_;
};

} } // namespace
