// Copyright (c) Facebook, Inc. and its affiliates. All Rights Reserved.
// All rights reserved.
//
// This source code is licensed under the license found in the
// LICENSE file in the root directory of this source tree.
#pragma once

#include <torch/torch.h>

#include "utils/Context.h"
#include "utils/Program.h"
#include "utils/OpenCLUtils.h"

#include "FloatDefs.h"
#include "utils/Tensor.h"
#include "ops/TensorConvert.h"

namespace facebook { namespace cl {

template <typename T>
struct TypeToATenType {};

template <>
struct TypeToATenType<unsigned char> {
  static constexpr at::ScalarType to() { return at::kByte; }
};

template <>
struct TypeToATenType<unsigned short> {
  static constexpr at::ScalarType to() { return at::kShort; }
};

// Convert a at::Tensor to a HostTensor<>
template <typename T, int Dim>
HostTensor<T, Dim>
torchToHostTensor(at::Tensor& t) {
  CL_ASSERT(t.ndimension() == Dim);

  std::array<size_t, Dim> sizes;
  for (int i = 0; i < t.ndimension(); ++i) {
    sizes[i] = t.sizes()[i];
  }

  // FIXME: this is a copy
  HostTensor<T, Dim> ret(sizes);
  memcpy(ret.data(), t.data<T>(), t.numel() * sizeof(T));

  return ret;
}

inline CLTensor<float>
torchToDeviceTensor(Context& context,
                    Queue& queue,
                    at::Tensor& t) {
  std::vector<size_t> sizes(t.ndimension());
  for (int i = 0; i < t.ndimension(); ++i) {
    sizes[i] = (size_t) t.sizes()[i];
  }

  auto ht = CLTensor<float>(context, sizes);
  CL_ASSERT(t.is_contiguous());
  ht.getDeviceMem().copyH2D(queue, t.data<float>(), t.numel(), 0);

  return ht;
}

// Convert a HostTensor<> to a at::Tensor
template <int Dim>
at::Tensor
hostToTorchTensor(HostTensor<float, Dim>& t) {
  std::array<int64_t, Dim> sizes;
  for (int i = 0; i < Dim; ++i) {
    sizes[i] = t.sizes()[i];
  }

  return torch::CPU(at::kFloat).tensorFromBlob(t.data(), sizes).clone();
}

template <int Dim>
at::Tensor
hostToTorchTensor(HostTensor<FloatType<kWidth>::T, Dim>& t) {
  std::array<int64_t, Dim> sizes;
  for (int i = 0; i < Dim; ++i) {
    sizes[i] = t.sizes()[i];
  }

  return torch::CPU(TypeToATenType<FloatType<kWidth>::T>::to()).
    tensorFromBlob(t.data(), sizes).clone();
}

inline at::Tensor
devicePositToTorch(Context& context,
                   Program& program,
                   Queue& queue,
                   const CLTensor<FloatType<kWidth>::T>& t) {
  CL_ASSERT(t.dims() <= 4);

  if (t.dims() == 1) {
    auto ht = fromDevicePosit<1>(context, program, queue, t);
    return hostToTorchTensor<1>(ht);
  } else if (t.dims() == 2) {
    auto ht = fromDevicePosit<2>(context, program, queue, t);
    return hostToTorchTensor<2>(ht);
  } else if (t.dims() == 3) {
    auto ht = fromDevicePosit<3>(context, program, queue, t);
    return hostToTorchTensor<3>(ht);
  } else {
    auto ht = fromDevicePosit<4>(context, program, queue, t);
    return hostToTorchTensor<4>(ht);
  }
}

inline at::Tensor
devicePositToTorchPosit(Context& context,
                        Program& program,
                        Queue& queue,
                        const CLTensor<FloatType<kWidth>::T>& t) {
  CL_ASSERT(t.dims() <= 4);

  if (t.dims() == 1) {
    auto ht = t.toHost<1>(queue);
    return hostToTorchTensor<1>(ht);
  } else if (t.dims() == 2) {
    auto ht = t.toHost<2>(queue);
    return hostToTorchTensor<2>(ht);
  } else if (t.dims() == 3) {
    auto ht = t.toHost<3>(queue);
    return hostToTorchTensor<3>(ht);
  } else {
    auto ht = t.toHost<4>(queue);
    return hostToTorchTensor<4>(ht);
  }
}

inline CLTensor<FloatType<kWidth>::T>
torchToDevicePosit(Context& context,
                   Program& program,
                   Queue& queue,
                   at::Tensor& t) {
  auto ft = torchToDeviceTensor(context, queue, t);
  return toDevicePosit(context, program, queue, ft);
}

} } // namespace
