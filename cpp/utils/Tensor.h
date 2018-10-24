// Copyright (c) Facebook, Inc. and its affiliates. All Rights Reserved.
// All rights reserved.
//
// This source code is licensed under the license found in the
// LICENSE file in the root directory of this source tree.
#pragma once

#include "utils/OpenCLUtils.h"
#include <array>
#include <vector>

namespace facebook { namespace cl {

/// Our tensor type
template <typename T, int Dim, bool InnerContig> class CLDimTensor;

/// Type of a subspace of a tensor
namespace detail {
template <typename TensorType, int SubDim> class SubCLDimTensor;
}

/// Our tensor type
template <typename T, int Dim, bool InnerContig> class HostTensor;

/// Type of a subspace of a tensor
namespace detail {
template <typename TensorType, int SubDim> class SubHostTensor;
}

/// Non-statically dimensioned tensor
template <typename T> class CLTensor;

namespace {

inline std::vector<size_t>
calcStrideVecFromSizeVec(const std::vector<size_t>& size) {
  std::vector<size_t> stride(size.size());

  stride[size.size() - 1] = 1;
  for (int i = size.size() - 2; i >= 0; --i) {
    stride[i] = stride[i + 1] * size[i + 1];
  }

  return stride;
}

template <int Dim>
std::vector<size_t>
calcStrideVecFromSizeArray(const std::array<size_t, Dim>& size) {
  std::vector<size_t> stride(size.size());

  stride[Dim - 1] = 1;
  for (int i = Dim - 2; i >= 0; --i) {
    stride[i] = stride[i + 1] * size[i + 1];
  }

  return stride;
}

template <int Dim>
std::array<size_t, Dim>
calcStrideArrayFromSizeArray(const std::array<size_t, Dim>& size) {
  std::array<size_t, Dim> stride;

  stride[Dim - 1] = 1;
  for (int i = Dim - 2; i >= 0; --i) {
    stride[i] = stride[i + 1] * size[i + 1];
  }

  return stride;
}

template <int Dim>
std::array<size_t, Dim>
calcStrideArrayFromSizeVec(const std::vector<size_t>& size) {
  std::array<size_t, Dim> stride;

  CL_ASSERT(size.size() == Dim);

  stride[Dim - 1] = 1;
  for (int i = Dim - 2; i >= 0; --i) {
    stride[i] = stride[i + 1] * size[i + 1];
  }

  return stride;
}

template <typename IndexT>
std::vector<size_t>
vecFromInitList(std::initializer_list<IndexT> list) {
  std::vector<size_t> out(list.size());

  int i = 0;
  for (auto s : list) {
    out[i++] = (size_t) s;
  }

  return out;
}

template <typename T, int Dim>
std::array<T, Dim> toArray(const std::vector<T>& v) {
  CL_ASSERT(v.size() == Dim);

  std::array<T, Dim> out;
  for (int i = 0; i < v.size(); ++i) {
    out[i] = v[i];
  }

  return out;
}

} // namespace

} } // namespace

#include "utils/CLDimTensor.h"
#include "utils/HostTensor.h"
#include "utils/CLTensor.h"
