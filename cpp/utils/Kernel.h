// Copyright (c) Facebook, Inc. and its affiliates. All Rights Reserved.
// All rights reserved.
//
// This source code is licensed under the license found in the
// LICENSE file in the root directory of this source tree.
#pragma once

#include "utils/DeviceMem.h"
#include "utils/Event.h"
#include "CL/opencl.h"
#include "utils/OpenCLUtils.h"
#include <iostream>
#include <string>
#include <vector>

namespace facebook { namespace cl {

struct Array3 {
  inline Array3(size_t xv, size_t yv = 1, size_t zv = 1)
      : x(xv), y(yv), z(zv) {
  }

  inline unsigned int num() const {
    if (z > 1) {
      return 3;
    } else if (y > 1) {
      return 2;
    }

    return 1;
  }

  inline void init(size_t v[3]) const {
    v[0] = x;
    v[1] = y;
    v[2] = z;
  }

  size_t x;
  size_t y;
  size_t z;
};

class Kernel {
 public:
  explicit Kernel(cl_kernel kernel, const std::string& name);

  Kernel(Kernel&& kernel);

  ~Kernel();

  inline operator cl_kernel() {
    return kernel_;
  }

  inline const std::string& getName() const {
    return name_;
  }

 public:
  /// Launch a NDRange kernel
  template <typename... Args>
  Event call(facebook::cl::Queue& queue,
             Array3 global,
             Array3 local,
             const Args&... args) {
    passKernelArgs(*this, args...);

    size_t gDim[3];
    global.init(gDim);
    size_t lDim[3];
    local.init(lDim);

    cl_event cle;
    CHECK_CL(clEnqueueNDRangeKernel(queue,
                                    kernel_,
                                    global.num(),
                                    nullptr,
                                    gDim,
                                    lDim,
                                    0,
                                    nullptr,
                                    &cle));
    auto evt = Event(cle);
    // std::cout << "Ker " << getName() << " took "
    //           << evt.getDurationInMs()
    //           << " ms\n";

    return evt;
  }

  /// Launch a task
  template <typename... Args>
  Event callTask(facebook::cl::Queue& queue,
                 const Args&... args) {
    passKernelArgs(*this, args...);

    cl_event cle;
    CHECK_CL(clEnqueueTask(queue,
                           kernel_,
                           0,
                           nullptr,
                           &cle));

    auto evt = Event(cle);
    // std::cout << "Ker " << getName() << " took "
    //           << evt.getDurationInMs()
    //           << " ms\n";

    return evt;
  }

 protected:
  cl_kernel kernel_;
  std::string name_;
};

template <typename T>
struct PassArg {
  static void pass(facebook::cl::Kernel& kernel,
                   unsigned int num,
                   const T& arg) {
    CHECK_CL(clSetKernelArg(kernel, num, sizeof(T), &arg));
  }
};

template <typename T>
struct PassArg<DeviceMem<T>> {
  static void pass(facebook::cl::Kernel& kernel,
                   unsigned int num,
                   const DeviceMem<T>& arg) {
    cl_mem m = arg.get();
    CHECK_CL(clSetKernelArg(kernel, num, sizeof(cl_mem), &m));
  }
};

template <typename T>
void passKernelArgsImpl(facebook::cl::Kernel& kernel,
                        unsigned int& num,
                        const T& arg) {
  PassArg<T>::pass(kernel, num++, arg);
}

template <typename T, typename... Args>
void passKernelArgsImpl(facebook::cl::Kernel& kernel,
                        unsigned int& num,
                        const T& arg,
                        Args&... args) {
  PassArg<T>::pass(kernel, num++, arg);
  passKernelArgsImpl(kernel, num, args...);
}

template <typename... Args>
void passKernelArgs(facebook::cl::Kernel& kernel,
                    const Args&... args) {
  unsigned int num = 0;
  passKernelArgsImpl(kernel, num, args...);
}

} } // namespace
