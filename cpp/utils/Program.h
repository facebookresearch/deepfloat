// Copyright (c) Facebook, Inc. and its affiliates. All Rights Reserved.
// All rights reserved.
//
// This source code is licensed under the license found in the
// LICENSE file in the root directory of this source tree.
#pragma once

#include "CL/opencl.h"
#include "utils/Kernel.h"

namespace facebook { namespace cl {

class Program {
 public:
  inline Program()
      : program_(0) {
  }

  inline Program(cl_program e)
      : program_(e) {
  }

  Program(Program&& e);
  Program& operator=(Program&& e);

  inline operator cl_program() {
    return program_;
  }

  void release();

  inline ~Program() {
    release();
  }

  /// Returns a new kernel instance
  Kernel getKernel(const std::string& name);

 protected:
  cl_program program_;
};

} } // namespace
