// Copyright (c) Facebook, Inc. and its affiliates. All Rights Reserved.
// All rights reserved.
//
// This source code is licensed under the license found in the
// LICENSE file in the root directory of this source tree.
#pragma once

namespace facebook { namespace cl {

template <typename U, typename V>
constexpr auto divUp(U a, V b) -> decltype(a + b) {
  return (a + b - 1) / b;
}

template <typename U, typename V>
constexpr auto roundDown(U a, V b) -> decltype(a + b) {
  return (a / b) * b;
}

template <typename U, typename V>
constexpr auto roundUp(U a, V b) -> decltype(a + b) {
  return divUp(a, b) * b;
}

} } // namespace
