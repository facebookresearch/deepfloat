// Copyright (c) Facebook, Inc. and its affiliates. All Rights Reserved.
// All rights reserved.
//
// This source code is licensed under the license found in the
// LICENSE file in the root directory of this source tree.
#include "utils/Kernel.h"

namespace facebook { namespace cl {

Kernel::Kernel(cl_kernel kernel,
               const std::string& name)
    : kernel_(kernel),
      name_(name) {
}

Kernel::Kernel(Kernel&& kernel)
    : kernel_(std::move(kernel.kernel_)) {
  kernel.kernel_ = 0;
}

Kernel::~Kernel() {
  if (kernel_) {
    CHECK_CL(clReleaseKernel(kernel_));
    kernel_ = 0;
  }
}

} } // namespace
