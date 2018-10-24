// Copyright (c) Facebook, Inc. and its affiliates. All Rights Reserved.
// All rights reserved.
//
// This source code is licensed under the license found in the
// LICENSE file in the root directory of this source tree.
#include "layers/Add.h"

#include "ops/TensorMath.h"
#include <cmath>

namespace facebook { namespace cl {

Add::Add(Context& context,
         Program& program,
         Queue& queue,
         int inputScale,
         int addScale,
         int outputScale)
    : inputScale_(inputScale),
      addScale_(addScale),
      outputScale_(outputScale) {
}

std::string
Add::str() const {
  return "Add";
}

void
Add::setInputScale(int scale) {
  inputScale_ = scale;
}

int
Add::getInputScale() const {
  return inputScale_;
}

void
Add::setOutputScale(int scale) {
  outputScale_ = scale;
}

int
Add::getOutputScale() const {
  return outputScale_;
}

void
Add::setAddScale(int scale) {
  addScale_ = scale;
}

int
Add::getAddScale() const {
  return addScale_;
}

void
Add::setAdd(CLTensor<FloatType<kWidth>::T>& add) {
  add_ = add;
}

CLTensor<FloatType<kWidth>::T>&
Add::forward(Context& context,
             Program& program,
             Queue& queue,
             const CLTensor<FloatType<kWidth>::T>& input) {
  if (!output_.isSameSize(input)) {
    output_ = CLTensor<FloatType<kWidth>::T>(context, input.sizes());
  }

  // Must have set this before getting here
  CL_ASSERT(add_.isSameSize(input));

  input_ = input;

  runMulAdd(context, program, queue,
            MathArg<FloatType<kWidth>::T>(input),
            inputScale_,
            MathArg<FloatType<kWidth>::T>(FloatType<kWidth>::kOne),
            MathArg<FloatType<kWidth>::T>(add_),
            addScale_,
            false, // subtract
            getRoundMode(),
            outputScale_,
            output_);

  return output_;
}

} }
