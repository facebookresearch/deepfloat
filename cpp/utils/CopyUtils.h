// Copyright (c) Facebook, Inc. and its affiliates. All Rights Reserved.
// All rights reserved.
//
// This source code is licensed under the license found in the
// LICENSE file in the root directory of this source tree.
#pragma once

#include <vector>
#include "CL/opencl.h"
#include "utils/Event.h"
#include "utils/OpenCLUtils.h"
#include "utils/Queue.h"

namespace facebook { namespace cl { namespace utils {

// blocking copy
template <typename T>
Event copyH2D(facebook::cl::Queue& queue,
              cl_mem dst,
              const T* src,
              size_t num,
              size_t offsetDst) {
  cl_event evt = 0;
  CHECK_CL(clEnqueueWriteBuffer(queue, dst, CL_TRUE,
                                offsetDst * sizeof(T),
                                num * sizeof(T),
                                src,
                                0, nullptr, &evt));

  return Event(evt);
}

// blocking copy
template <typename T>
Event copyD2H(facebook::cl::Queue& queue,
              cl_mem src,
              T* dst,
              size_t num,
              size_t offsetSrc) {
  cl_event evt = 0;
  CHECK_CL(clEnqueueReadBuffer(queue, src, CL_TRUE,
                               offsetSrc * sizeof(T),
                               num * sizeof(T),
                               dst,
                               0, nullptr, &evt));

  return Event(evt);
}

template <typename T>
Event copyD2D(facebook::cl::Queue& queue,
              cl_mem src,
              cl_mem dst,
              size_t offsetSrc,
              size_t offsetDst,
              size_t size) {
  cl_event evt = 0;
  CHECK_CL(clEnqueueCopyBuffer(queue,
                               src, dst,
                               offsetSrc * sizeof(T), offsetDst * sizeof(T),
                               size * sizeof(T),
                               0, nullptr, &evt));

  return Event(evt);
}

} } } // namespace
