// Copyright (c) Facebook, Inc. and its affiliates. All Rights Reserved.
// All rights reserved.
//
// This source code is licensed under the license found in the
// LICENSE file in the root directory of this source tree.
#pragma once

#include "utils/Tensor.h"
#include "ops/TensorMath.h"
#include <iomanip>
#include <iostream>

template <typename T>
std::ostream& operator <<(std::ostream& str,
                          const std::vector<T>& vec) {
  str << "{";
  bool first = true;
  for (auto v : vec) {
    if (!first) {
      str << " ";
    }
    first = false;
    str << v;
  }

  str << "}";
  return str;
}

namespace facebook { namespace cl {

template <typename T>
void printTensor(const HostTensor<T, 1>& t,
                 size_t limit = std::numeric_limits<size_t>::max()) {
  for (int i = 0; i < std::min(t.getSize(0), limit); ++i) {
    std::cout << std::setw(10) << std::setprecision(4) << +t[i] << " ";
  }

  std::cout << "\n";
}

template <typename T>
void printTensor(const HostTensor<T, 2>& t,
                 size_t limit = std::numeric_limits<size_t>::max()) {
  for (int i = 0; i < std::min(t.getSize(0), limit); ++i) {
    for (int j = 0; j < std::min(t.getSize(1), limit); ++j) {
      std::cout << std::setw(10) << std::setprecision(4)
                << +t[i][j] << " ";
    }

    std::cout << "\n";
  }
}

template <typename T>
void printTensor(const HostTensor<T, 3>& t,
                 size_t limit = std::numeric_limits<size_t>::max()) {
  for (int i = 0; i < std::min(t.getSize(0), limit); ++i) {
    for (int j = 0; j < std::min(t.getSize(1), limit); ++j) {
      for (int k = 0; k < std::min(t.getSize(2), limit); ++k) {
        std::cout << std::setw(10) << std::setprecision(4)
                  << +t[i][j][k] << " ";
      }

      std::cout << "\n";
    }

    std::cout << "\n";
  }
}

template <typename T>
void printTensor(const HostTensor<T, 4>& t,
                 size_t limit = std::numeric_limits<size_t>::max()) {
  for (int i = 0; i < std::min(t.getSize(0), limit); ++i) {
    for (int j = 0; j < std::min(t.getSize(1), limit); ++j) {
      for (int k = 0; k < std::min(t.getSize(2), limit); ++k) {
        for (int l = 0; l < std::min(t.getSize(3), limit); ++l) {
          std::cout << std::setw(10) << std::setprecision(4)
                    << +t[i][j][k][l] << " ";
        }

        std::cout << "\n";
      }

      std::cout << "\n";
    }

    std::cout << "\n";
  }
}


template <typename T>
void printTensor(Context& context,
                 Program& program,
                 Queue& queue,
                 const CLTensor<T>& t,
                 size_t limit = std::numeric_limits<size_t>::max()) {
  if (t.dims() == 1) {
    printTensor(t.template toHost<1>(queue), limit);
  } else if (t.dims() == 2) {
    printTensor(t.template toHost<2>(queue), limit);
  } else if (t.dims() == 3) {
    printTensor(t.template toHost<3>(queue), limit);
  } else if (t.dims() == 4) {
    printTensor(t.template toHost<4>(queue), limit);
  } else {
    CL_ASSERT_MSG(false, "NYI");
  }
}

inline void printPositTensor(Context& context,
                             Program& program,
                             Queue& queue,
                             const CLTensor<FloatType<kWidth>::T>& t,
                             size_t limit = std::numeric_limits<size_t>::max()) {
  CLTensor<float> f(context, t.sizes());
  runToFloat(context, program, queue, t, f);

  printTensor<float>(context, program, queue, f, limit);
}

} } // namespace
