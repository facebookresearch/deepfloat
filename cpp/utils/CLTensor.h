// Copyright (c) Facebook, Inc. and its affiliates. All Rights Reserved.
// All rights reserved.
//
// This source code is licensed under the license found in the
// LICENSE file in the root directory of this source tree.
#pragma once

#include "utils/CLDimTensor.h"
#include "utils/HostTensor.h"

namespace facebook { namespace cl {

template <typename T>
class CLTensor {
 public:
  CLTensor();

  /*
  /// Addrefs the tensor; does not copy
  CLTensor(CLTensor<T>& t);

  /// Addrefs the tensor; does not copy
  CLTensor<T>& operator=(CLTensor<T>& t);

  /// Move constructor
  CLTensor(CLTensor<T>&& t);

  /// Move assignment
  CLTensor<T>& operator=(CLTensor<T>&& t);
  */

  CLTensor(facebook::cl::Context& context,
           const std::vector<size_t>& sizes);

  CLTensor(facebook::cl::Context& context,
           const std::vector<size_t>& sizes,
           const std::vector<size_t>& strides);

  template <typename IndexT>
  CLTensor(facebook::cl::Context& context,
           std::initializer_list<IndexT> sizes);

  // Initialize (copy) from a host tensor
  template <int Dim>
  CLTensor(facebook::cl::Context& context,
           facebook::cl::Queue& queue,
           const HostTensor<T, Dim>& t);

  // Initialize (copy) from a device tensor
  template <int Dim>
  CLTensor(facebook::cl::Context& context,
           facebook::cl::Queue& queue,
           const CLDimTensor<T, Dim>& t);

 protected:
  CLTensor(std::shared_ptr<facebook::cl::DeviceMem<T>> data,
           const std::vector<size_t>& sizes,
           const std::vector<size_t>& strides);

 public:
  /// Copies a tensor into ourselves; sizes must match
  facebook::cl::Event copyFrom(facebook::cl::Queue& queue,
                               const CLTensor<T>& t);

  template <int Dim, bool InnerContig = true>
  facebook::cl::Event copyFrom(facebook::cl::Queue& queue,
                               const HostTensor<T, Dim, InnerContig>& t);

  facebook::cl::Event copyTo(facebook::cl::Queue& queue,
                             CLTensor<T>& t) const;

  template <int Dim, bool InnerContig = true>
  facebook::cl::Event copyTo(facebook::cl::Queue& queue,
                             HostTensor<T, Dim, InnerContig>& t) const;

  /// Convert to a statically-dimensioned tensor
  template <int Dim, bool InnerContig = true>
  CLDimTensor<T, Dim, InnerContig> toDimTensor();

  /// Copy to the host
  template <int Dim, bool InnerContig = true>
  HostTensor<T, Dim, InnerContig> toHost(facebook::cl::Queue& queue) const;

  /// Read a value from the device
  template <typename IndexT>
  T get(facebook::cl::Queue& queue,
        std::initializer_list<IndexT> at);

  /// Write a value to the device
  template <typename IndexT>
  void set(T v,
           facebook::cl::Queue& queue,
           std::initializer_list<IndexT> at);

 public:
  /// Returns true if the two tensors are of the same dimensionality,
  /// size and stride.
  template <typename U>
  bool isSame(const CLTensor<U>& rhs) const;

  /// Returns true if the two tensors are of the same dimensionality and size
  template <typename U>
  bool isSameSize(const CLTensor<U>& rhs) const;

  /// Returns true if we have the same size
  template <typename IndexType>
  bool isSize(std::initializer_list<IndexType> size) const;

  /// Returns true if the two tensors are the same exact instance
  template <typename U>
  bool isSameInstance(const CLTensor<U>& rhs) const;

  /// Cast to a tensor of a different type of the same size and
  /// stride. U and our type T must be of the same size
  template <typename U>
  CLTensor<U> cast();

  /// Cast to a tensor of a different type which is potentially a
  /// different size than our type T. Tensor must be aligned and the
  /// innermost dimension must be a size that is a multiple of
  /// sizeof(U) / sizeof(T), and the stride of the innermost dimension
  /// must be contiguous. The stride of all outer dimensions must be a
  /// multiple of sizeof(U) / sizeof(T) as well.
  template <typename U>
  CLTensor<U> castResize();

  /// Const version of `castResize`
  template <typename U>
  const CLTensor<U> castResize() const;

  /// Returns true if we can castResize() this tensor to the new type
  template <typename U>
  bool canCastResize() const;

  /// Returns our memory object
  facebook::cl::DeviceMem<T>& getDeviceMem() {
    CL_ASSERT(data_);
    return *data_;
  }

  const facebook::cl::DeviceMem<T>& getDeviceMem() const {
    CL_ASSERT(data_);
    return *data_;
  }

  /// Returns the offset (based on stride) of a particular address
  template <typename IndexT>
  size_t offset(std::initializer_list<IndexT> at) const;

  /// Returns number of elements contained within this tensor
  size_t numElements() const;

  /// If we are contiguous, returns the total size in bytes of our
  /// data
  size_t getSizeInBytes() const {
    return numElements() * sizeof(T);
  }

  size_t getSize(int i) const {
    CL_ASSERT(i < size_.size());
    return size_[i];
  }

  size_t getStride(int i) const {
    CL_ASSERT(i < stride_.size());
    return stride_[i];
  }

  /// Returns the number of dimensions
  int dims() const {
    // FIXME
    CL_ASSERT(size_.size() == dim_);
    return dim_;
  }

  /// Returns the size array.
  const std::vector<size_t>& sizes() const {
    return size_;
  }

  /// Returns the stride array.
  const std::vector<size_t>& strides() const {
    return stride_;
  }

  /// Returns true if there is no padding within the tensor and no
  /// re-ordering of the dimensions.
  /// ~~~
  /// (stride(i) == size(i + 1) * stride(i + 1)) && stride(dim - 1) == 0
  /// ~~~
  bool isContiguous() const;

  /// Returns whether a given dimension has only increasing stride
  /// from the previous dimension. A tensor that was permuted by
  /// exchanging size and stride only will fail this check.
  /// If `i == 0` just check `size > 0`. Returns `false` if `stride` is `<= 0`.
  bool isConsistentlySized(int i) const;

  // Returns whether at each dimension `stride <= size`.
  // If this is not the case then iterating once over the size space will
  // touch the same memory locations multiple times.
  bool isConsistentlySized() const;

  /// Returns true if the given dimension index has no padding
  bool isContiguousDim(int i) const;

  /// Returns a tensor of the same dimension after transposing the two
  /// dimensions given. Does not actually move elements; transposition
  /// is made by permuting the size/stride arrays.
  /// If the dimensions are not valid, asserts.
  CLTensor<T> transpose(int dim1, int dim2) const;

  /// Upcast a tensor of dimension `D` to some tensor of dimension
  /// D' > D by padding the leading dimensions by 1
  /// e.g., upcasting a 2-d tensor `[2][3]` to a 4-d tensor `[1][1][2][3]`
  CLTensor<T> upcastOuter(int newDim) const;

  /// Upcast a tensor of dimension `D` to some tensor of dimension
  /// D' > D by padding the lowest/most varying dimensions by 1
  /// e.g., upcasting a 2-d tensor `[2][3]` to a 4-d tensor `[2][3][1][1]`
  CLTensor<T> upcastInner(int newDim) const;

  /// Downcast a tensor of dimension `D` to some tensor of dimension
  /// D' < D by collapsing the leading dimensions. asserts if there is
  /// padding on the leading dimensions.
  CLTensor<T> downcastOuter(int newDim) const;

  /// Downcast a tensor of dimension `D` to some tensor of dimension
  /// D' < D by collapsing the leading dimensions. asserts if there is
  /// padding on the leading dimensions.
  CLTensor<T> downcastInner(int newDim) const;

  /// Returns a tensor that is a view of the `SubDim`-dimensional slice
  /// of this tensor, starting where our data begins
  CLTensor<T> view(int subDim) const;

  /// View beginning at a particular offset
  CLTensor<T> view(int subDim, size_t offset) const;

  /// Returns a tensor of the same dimension that is a view of the
  /// original tensor with the specified dimension restricted to the
  /// elements in the range [start, start + size)
  CLTensor<T> narrowOutermost(size_t start, size_t size) const;

  /// Returns a tensor of the same dimension that is a view of the
  /// original tensor with the specified dimension restricted to the
  /// elements in the range [start, start + size).
  /// Can occur in an arbitrary dimension
  CLTensor<T> narrow(int dim, size_t start, size_t size) const;

  /// Returns a view of the given tensor expressed as a tensor of a
  /// different number of dimensions.
  /// Only works if we are contiguous.
  CLTensor<T> view(std::initializer_list<size_t> sizes) const;
  CLTensor<T> view(const std::vector<size_t>& sizes) const;

 private:
  // FIXME: remove dim_, should be implicit based on size_.size()
  int dim_;
  std::vector<size_t> size_;
  std::vector<size_t> stride_;

  std::shared_ptr<facebook::cl::DeviceMem<T>> data_;
};

/// For passing a CLTensor to a kernel
template <typename T>
struct PassArg<CLTensor<T>> {
  static void pass(facebook::cl::Kernel& kernel,
                   unsigned int num,
                   const CLTensor<T>& arg) {
    CL_ASSERT(arg.isContiguous());
    cl_mem m = arg.getDeviceMem().get();

    CHECK_CL(clSetKernelArg(kernel, num, sizeof(cl_mem), &m));
  }
};

} } // namespace

#include "utils/CLTensor-inl.h"
