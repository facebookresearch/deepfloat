// Copyright (c) Facebook, Inc. and its affiliates. All Rights Reserved.
// All rights reserved.
//
// This source code is licensed under the license found in the
// LICENSE file in the root directory of this source tree.
#pragma once

#include <limits>
#include <vector>
#include "CL/opencl.h"
#include "utils/CopyUtils.h"
#include "utils/OpenCLUtils.h"

namespace facebook { namespace cl {

template <typename T>
class DeviceMem {
 public:
  DeviceMem()
      : context_(0),
        mem_(0),
        size_(0) {
  }

  DeviceMem(cl_context context,
            cl_mem mem,
            size_t size)
      : context_(context),
        mem_(mem),
        size_(size) {
  }

  DeviceMem(const DeviceMem& m) = delete;

  // move constructor
  DeviceMem(DeviceMem&& m)
      : context_(std::move(m.context_)),
        mem_(std::move(m.mem_)),
        size_(std::move(m.size_)) {
    m.context_ = 0;
    m.mem_ = 0;
    m.size_ = 0;
  }

  DeviceMem& operator=(DeviceMem& m) = delete;

  DeviceMem& operator=(DeviceMem&& m) {
    context_ = std::move(m.context_);
    m.context_ = 0;

    mem_ = std::move(m.mem_);
    m.mem_ = 0;

    size_ = std::move(m.size_);
    m.size_ = 0;

    return *this;
  }

  ~DeviceMem() {
    if (mem_) {
      CHECK_CL(clReleaseMemObject(mem_));
      mem_ = 0;
    }
  }

  DeviceMem<T> copy(facebook::cl::Queue& queue) {
    cl_int status = 0;
    cl_mem mem = clCreateBuffer(context_,
                                CL_MEM_READ_WRITE,
                                size_ * sizeof(T),
                                nullptr,
                                &status);
    CHECK_CL(status);
    utils::copyD2D<T>(queue, mem_, mem, 0, 0, size_);

    return DeviceMem<T>(context_, mem, size_);
  }

 public:
  template <typename U>
  bool isSame(const DeviceMem<U>& m) const {
    return (context_ == m.context_ &&
            mem_ == m.mem_ &&
            size_ == m.size_);
  }

  template <typename U>
  DeviceMem<U> cast() {
    CL_ASSERT(sizeof(U) == sizeof(T) ||
              (sizeof(U) < sizeof(T) && (sizeof(T) % sizeof(U) == 0)) ||
              (sizeof(U) > sizeof(T) && (sizeof(U) % sizeof(T) == 0)));

    CHECK_CL(clRetainMemObject(mem_));
    return DeviceMem<U>(context_, mem_, (size_ * sizeof(T)) / sizeof(U));
  }

  cl_context getContext() {
    return context_;
  }

  cl_mem get() const {
    return mem_;
  }

  size_t size() const {
    return size_;
  }

  /// Creates a sub-region of the buffer beginning at offset containing `size`
  /// elements. If `size` is not provided, the region will contain the remainder
  /// of the allocation.
  DeviceMem<T> at(size_t offset,
                  size_t size = std::numeric_limits<size_t>::max()) const {
    // FIXME: assert region sizes
    size = size == std::numeric_limits<size_t>::max() ?
      (size_ - offset) : size;

    cl_buffer_region region;
    region.origin = offset;
    region.size = size * sizeof(T); // size in bytes

    cl_int err = 0;
    cl_mem newMem = clCreateSubBuffer(mem_,
                                      CL_MEM_READ_WRITE,
                                      CL_BUFFER_CREATE_TYPE_REGION,
                                      &region,
                                      &err);
    CHECK_CL(err);

    return DeviceMem<T>(context_, newMem, size);
  }

  Event copyD2H(facebook::cl::Queue& queue,
                T* dst,
                size_t num = std::numeric_limits<size_t>::max(),
                size_t offsetSrc = 0) {
    num = (num == std::numeric_limits<size_t>::max()) ? size_ : num;
    return utils::copyD2H(queue, mem_, dst, num, offsetSrc);
  }

  Event copyH2D(facebook::cl::Queue& queue,
                const T* src,
                size_t num = std::numeric_limits<size_t>::max(),
                size_t offsetDst = 0) {
    num = (num == std::numeric_limits<size_t>::max()) ? size_ : num;
    return utils::copyH2D<T>(queue, mem_, src, num, offsetDst);
  }

  Event copyD2DFrom(facebook::cl::Queue& queue,
                    const DeviceMem<T>& src,
                    size_t offsetSrc,
                    size_t offsetDst,
                    size_t size) {
    return utils::copyD2D<T>(queue, src.mem_, mem_, offsetSrc, offsetDst, size);
  }

  Event copyD2DTo(facebook::cl::Queue& queue,
                  DeviceMem<T>& dst,
                  size_t offsetSrc,
                  size_t offsetDst,
                  size_t size) {
    return utils::copyD2D<T>(queue, mem_, dst.mem_, offsetSrc, offsetDst, size);
  }

 protected:
  // We don't own the context
  cl_context context_;

  // We own the memory
  cl_mem mem_;

  // The memory references a region of size_ * sizeof(T) bytes
  size_t size_;
};

} } // namespace
