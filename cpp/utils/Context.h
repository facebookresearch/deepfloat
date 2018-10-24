// Copyright (c) Facebook, Inc. and its affiliates. All Rights Reserved.
// All rights reserved.
//
// This source code is licensed under the license found in the
// LICENSE file in the root directory of this source tree.
#pragma once

#include <string>

#include "CL/opencl.h"
#include "utils/DeviceMem.h"
#include "utils/Program.h"
#include "utils/Queue.h"

namespace facebook { namespace cl {

typedef void (*ContextCallback)(const char* errInfo,
                                const void* privateInfo,
                                size_t cbSize,
                                void* userData);

class Context {
 public:
  Context();

  /// Create a context for a given device
  Context(cl_device_id device,
          ContextCallback callback = nullptr,
          void* userData = nullptr);

  Context(Context&& e);

  ~Context();

  Context& operator=(Context&& e);

  Queue makeQueue(cl_command_queue_properties properties =
                  CL_QUEUE_PROFILING_ENABLE);

  /// Returns a default queue created for this context
  Queue& getDefaultQueue();

  Program makeBinaryProgram(const std::string& binaryFile);

  template <typename T>
  DeviceMem<T> alloc(size_t num) {
    cl_int err = 0;
    cl_mem mem = clCreateBuffer(context_,
                                CL_MEM_READ_WRITE,
                                num * sizeof(T),
                                nullptr,
                                &err);
    CHECK_CL(err);

    return DeviceMem<T>(context_, mem, num);
  }

  void release();

  inline operator cl_context() {
    return context_;
  }

  inline bool supportsSVM() const {
    return svm_;
  }

  inline cl_uint getMemAlignment() const {
    return align_;
  }

 protected:
  cl_device_id device_;
  cl_context context_;

  Queue defaultQueue_;

  /// Do we support CL 2.0 SVM?
  bool svm_;

  /// Alignment size in bytes of an allocation
  cl_uint align_;
};

} } // namespace
