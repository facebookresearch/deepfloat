// Copyright (c) Facebook, Inc. and its affiliates. All Rights Reserved.
// All rights reserved.
//
// This source code is licensed under the license found in the
// LICENSE file in the root directory of this source tree.
#pragma once

#include "utils/CLTensor.h"
#include "utils/HostTensor.h"
#include "ops/TensorMath.h"

namespace facebook { namespace cl {

template <int Dim>
CLTensor<FloatType<kWidth>::T> toDevicePosit(Context& context,
                               Program& program,
                               Queue& queue,
                               const HostTensor<float, Dim>& t) {
  CLTensor<float> outF(context, queue, t);
  CLTensor<FloatType<kWidth>::T> outP(context, outF.sizes());

  runToPosit8(context, program, queue, outF, outP);

  return outP;
}

inline CLTensor<FloatType<kWidth>::T>
toDevicePosit(Context& context,
              Program& program,
              Queue& queue,
              const CLTensor<float>& t) {
  CLTensor<FloatType<kWidth>::T> p(context, t.sizes());

  runToPosit8(context, program, queue, t, p);

  return p;
}

template <int Dim>
HostTensor<float, Dim> fromDevicePosit(Context& context,
                                       Program& program,
                                       Queue& queue,
                                       const CLTensor<FloatType<kWidth>::T>& t) {
  CL_ASSERT(t.dims() == Dim);
  CLTensor<float> outF(context, t.sizes());

  runToFloat(context, program, queue, t, outF);
  return outF.toHost<Dim>(queue);
}

} }
