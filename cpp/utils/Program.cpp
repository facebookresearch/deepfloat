// Copyright (c) Facebook, Inc. and its affiliates. All Rights Reserved.
// All rights reserved.
//
// This source code is licensed under the license found in the
// LICENSE file in the root directory of this source tree.
#include "utils/Program.h"
#include "utils/OpenCLUtils.h"

namespace facebook { namespace cl {

Program::Program(Program&& e)
    : program_(std::move(e.program_)) {
  e.program_ = 0;
}

Program&
Program::operator=(Program&& e) {
  release();
  program_ = std::move(e.program_);
  e.program_ = 0;

  return *this;
}

void
Program::release() {
  if (program_) {
    CHECK_CL(clReleaseProgram(program_));
    program_ = 0;
  }
}

Kernel
Program::getKernel(const std::string& name) {
  cl_int err = 0;
  cl_kernel kernel = clCreateKernel(program_, name.c_str(), &err);
  CHECK_CL_MSG(err, name.c_str());

  return Kernel(kernel, name);
}

} } // namespace
