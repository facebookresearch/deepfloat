// Copyright (c) Facebook, Inc. and its affiliates. All Rights Reserved.
// All rights reserved.
//
// This source code is licensed under the license found in the
// LICENSE file in the root directory of this source tree.
#pragma once

#include <array>
#include <initializer_list>
#include <memory>
#include "utils/Context.h"
#include "utils/CopyUtils.h"
#include "utils/DeviceMem.h"
#include "utils/Event.h"

namespace facebook { namespace cl {

template <typename T>
struct HostTensorData {
  HostTensorData() {
  }

  HostTensorData(size_t size)
      : data_(std::make_shared<std::vector<char>>(size * sizeof(T))) {
  }

  HostTensorData(std::shared_ptr<std::vector<char>>& data)
      : data_(data) {
  }

  HostTensorData(std::shared_ptr<std::vector<char>>&& data)
      : data_(std::move(data)) {
  }

  HostTensorData<T> copy() const {
    return HostTensorData<T>(std::make_shared<std::vector<char>>(*data_));
  }

  template <typename U>
  HostTensorData<U> cast() {
    return HostTensorData<U>(data_);
  }

  size_t size() {
    return data_->size() / sizeof(T);
  }

  T* data() {
    return (T*) data_->data();
  }

  const T* data() const {
    return (const T*) data_->data();
  }

  std::shared_ptr<std::vector<char>> data_;
};

/**
   Templated multi-dimensional array that supports strided access of
   elements. Main access is through `operator[]`; e.g.,
   `tensor[x][y][z]`.

   - `T` is the contained type (e.g., `float`)
   - `Dim` is the tensor rank
   - If `InnerContig` is true, then the tensor is assumed to be innermost
   - contiguous, and only operations that make sense on contiguous
   - arrays are allowed (e.g., no transpose). Strides are still
   - calculated, but innermost stride is assumed to be 1.
*/
template <typename T,
          int Dim,
          bool InnerContig = true>
class HostTensor {
 public:
  enum { NumDim = Dim };
  typedef T DataType;
  enum { IsInnerContig = InnerContig };
  typedef HostTensor<T, Dim, InnerContig> TensorType;

  /// Default constructor
  HostTensor();

  /*
  /// Addrefs the tensor; does not copy
  HostTensor(HostTensor<T, Dim, InnerContig>& t);

  /// Addrefs the tensor; does not copy
  HostTensor<T, Dim, InnerContig>&
  operator=(HostTensor<T, Dim, InnerContig>& t);

  /// Move constructor
  HostTensor(HostTensor<T, Dim, InnerContig>&& t);

  /// Move assignment
  HostTensor<T, Dim, InnerContig>&
  operator=(HostTensor<T, Dim, InnerContig>&& t);
  */

  /// Constructor that calculates strides with no padding
  HostTensor(const std::array<size_t, Dim>& sizes);
  HostTensor(const std::vector<size_t>& sizes);
  HostTensor(std::initializer_list<size_t> sizes);

  /// Constructor that takes arbitrary size/stride arrays.
  /// Errors if you attempt to pass non-contiguous strides to a
  /// contiguous tensor.
  HostTensor(const std::array<size_t, Dim>& sizes,
             const std::array<size_t, Dim>& strides);

 protected:
  HostTensor(HostTensorData<T> data,
             T* ptr,
             const std::array<size_t, Dim>& sizes,
             const std::array<size_t, Dim>& strides);

 public:
  /// Copies a tensor into ourselves; sizes must match
  void copyFrom(HostTensor<T, Dim, InnerContig>& t);

  /// Copies ourselves into a tensor; sizes must match
  void copyTo(HostTensor<T, Dim, InnerContig>& t);

  /// Returns true if the two tensors are of the same dimensionality,
  /// size and stride.
  template <typename OtherT, int OtherDim>
  bool isSame(const HostTensor<OtherT, OtherDim, InnerContig>& rhs) const;

  /// Returns true if we have the same size
  template <typename IndexType>
  bool isSize(std::initializer_list<IndexType> size) const;

  /// Returns true if the two tensors are of the same dimensionality and size
  template <typename OtherT, int OtherDim>
  bool isSameSize(const HostTensor<OtherT, OtherDim, InnerContig>& rhs) const;

  /// Cast to a tensor of a different type of the same size and
  /// stride. U and our type T must be of the same size
  template <typename U>
  HostTensor<U, Dim, InnerContig> cast();

  /// Const version of `cast`
  template <typename U>
  const HostTensor<U, Dim, InnerContig> cast() const;

  /// Cast to a tensor of a different type which is potentially a
  /// different size than our type T. Tensor must be aligned and the
  /// innermost dimension must be a size that is a multiple of
  /// sizeof(U) / sizeof(T), and the stride of the innermost dimension
  /// must be contiguous. The stride of all outer dimensions must be a
  /// multiple of sizeof(U) / sizeof(T) as well.
  template <typename U>
  HostTensor<U, Dim, InnerContig> castResize();

  /// Const version of `castResize`
  template <typename U>
  const HostTensor<U, Dim, InnerContig>
  castResize() const;

  /// Returns true if we can castResize() this tensor to the new type
  template <typename U>
  bool canCastResize() const;

  /// Returns our current data
  T* data() {
    return ptr_;
  }

  /// Returns a raw pointer to the start of our data (const).
  inline const T* data() const {
    return ptr_;
  }

/*

  /// Returns a raw pointer to the end of our data, assuming
  /// continuity
  inline T* end() {
    CL_ASSERT(hostData_);
    return data() + numElements();
  }

  inline const T* data(size_t ofs) const {
    CL_ASSERT(hostData_);
    return hostData_->data<T>(ofs);
  }

  /// Returns a raw pointer to the end of our data, assuming
  /// continuity (const)
  inline const T* end() const {
    CL_ASSERT(hostData_);
    return data() + numElements();
  }

  /// Cast to a different datatype
  template <typename U>
  inline U* dataAs() {
    CL_ASSERT(hostData_);
    return (U*)(hostData_->data<T>(offset_));
  }

  /// Cast to a different datatype
  template <typename U>
  inline const U* dataAs() const {
    CL_ASSERT(hostData_);
    return (const U*)(hostData_->data<T>(offset_));
  }

*/

  /// Returns a read/write view of a portion of our tensor.
  inline detail::SubHostTensor<TensorType, Dim - 1>
  operator[](size_t);

  /// Returns a read/write view of a portion of our tensor (const).
  inline const detail::SubHostTensor<TensorType, Dim - 1>
  operator[](size_t) const;

  /// Returns the size of a given dimension, `[0, Dim - 1]`. No bounds
  /// checking.
  inline size_t getSize(int i) const {
    return size_[i];
  }

  /// Returns the stride of a given dimension, `[0, Dim - 1]`. No bounds
  /// checking.
  inline size_t getStride(int i) const {
    return stride_[i];
  }

  /// Returns the total number of elements contained within our data
  /// (product of `getSize(i)`)
  size_t numElements() const;

  /// If we are contiguous, returns the total size in bytes of our
  /// data
  size_t getSizeInBytes() const {
    return numElements() * sizeof(T);
  }

  /// Returns the size array.
  const std::array<size_t, Dim>& sizes() const {
    return size_;
  }

  /// Returns the stride array.
  const std::array<size_t, Dim>& strides() const {
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
  HostTensor<T, Dim, InnerContig>
  transpose(int dim1, int dim2) const;

  /// Upcast a tensor of dimension `D` to some tensor of dimension
  /// D' > D by padding the leading dimensions by 1
  /// e.g., upcasting a 2-d tensor `[2][3]` to a 4-d tensor `[1][1][2][3]`
  template <int NewDim>
  HostTensor<T, NewDim, InnerContig> upcastOuter();

  /// Upcast a tensor of dimension `D` to some tensor of dimension
  /// D' > D by padding the lowest/most varying dimensions by 1
  /// e.g., upcasting a 2-d tensor `[2][3]` to a 4-d tensor `[2][3][1][1]`
  template <int NewDim>
  HostTensor<T, NewDim, InnerContig> upcastInner();

  /// Downcast a tensor of dimension `D` to some tensor of dimension
  /// D' < D by collapsing the leading dimensions. asserts if there is
  /// padding on the leading dimensions.
  template <int NewDim>
  HostTensor<T, NewDim, InnerContig> downcastOuter();

  /// Downcast a tensor of dimension `D` to some tensor of dimension
  /// D' < D by collapsing the leading dimensions. asserts if there is
  /// padding on the leading dimensions.
  template <int NewDim>
  HostTensor<T, NewDim, InnerContig> downcastInner();

  /// Returns a tensor that is a view of the `SubDim`-dimensional slice
  /// of this tensor, starting where our data begins
  template <int SubDim>
  HostTensor<T, SubDim, InnerContig> view();

  /// View beginning at a particular offset
  template <int SubDim>
  HostTensor<T, SubDim, InnerContig> view(T* ptr);

  /// Returns a tensor of the same dimension that is a view of the
  /// original tensor with the specified dimension restricted to the
  /// elements in the range [start, start + size)
  HostTensor<T, Dim, InnerContig>
  narrowOutermost(size_t start, size_t size);

  /// Returns a tensor of the same dimension that is a view of the
  /// original tensor with the specified dimension restricted to the
  /// elements in the range [start, start + size).
  /// Can occur in an arbitrary dimension
  HostTensor<T, Dim, InnerContig>
  narrow(int dim, size_t start, size_t size);

  /// Returns a view of the given tensor expressed as a tensor of a
  /// different number of dimensions.
  /// Only works if we are contiguous.
  template <int NewDim>
  HostTensor<T, NewDim, InnerContig>
  view(std::initializer_list<size_t> sizes);

 protected:
  friend class CLTensor<T>;

  /// Pointer to the start of our data
  T* ptr_;

  /// Size per each dimension
  std::array<size_t, Dim> size_;

  /// Array of strides (in sizeof(T) terms) per each dimension
  std::array<size_t, Dim> stride_;

  /// Our underlying ref-counted data holder
  HostTensorData<T> data_;
};

namespace detail {

/// Specialization for a view of a single value (0-dimensional)
template <typename TensorType>
class SubHostTensor<TensorType, 0> {
 public:
  // Assign a value from the host
  SubHostTensor<TensorType, 0>& operator=(typename TensorType::DataType v);

  // Return a value
  operator const typename TensorType::DataType() const;

/*
  // operator T&
  operator typename TensorType::DataType&() {
    return *data_;
  }

  // const operator T& returning const T&
  operator const typename TensorType::DataType&() const {
    return *data_;
  }

  // operator& returning T*
  typename TensorType::DataType* operator&() {
    return data_;
  }

  // const operator& returning const T*
  const typename TensorType::DataType* operator&() const {
    return data_;
  }

  /// Returns a raw accessor to our slice.
  inline typename TensorType::DataPtrType data() {
    return data_;
  }

  /// Returns a raw accessor to our slice (const).
  inline
  const typename TensorType::DataPtrType data() const {
    return data_;
  }

  /// Cast to a different datatype.
  template <typename T>
  T& as() {
    return *dataAs<T>();
  }

  /// Cast to a different datatype (const).
  template <typename T>
  const T& as() const {
    return *dataAs<T>();
  }

  /// Cast to a different datatype
  template <typename T>
  inline T* dataAs() {
    return reinterpret_cast<T*>(data_);
  }

  /// Cast to a different datatype (const)
  template <typename T>
  inline const T* dataAs() const {
    return reinterpret_cast<const T*>(data_);
  }
*/

 protected:
  /// One dimension greater can create us
  friend class SubHostTensor<TensorType, 1>;

  /// Our parent tensor can create us
  friend class HostTensor<typename TensorType::DataType,
                          1,
                          TensorType::IsInnerContig>;

  inline SubHostTensor(TensorType& t,
                       typename TensorType::DataType* ptr)
      : tensor_(t),
        ptr_(ptr) {
  }

  /// The tensor we're referencing
  TensorType& tensor_;

  /// Our current data pointer
  typename TensorType::DataType* ptr_;
};

/// A `SubDim`-rank slice of a parent Tensor
template <typename TensorType, int SubDim>
class SubHostTensor {
 public:
  /// Returns a view of the data located at our offset (the dimension
  /// `SubDim` - 1 tensor).
  inline SubHostTensor<TensorType, SubDim - 1>
  operator[](size_t index) {
    if (TensorType::IsInnerContig && SubDim == 1) {
      // Innermost dimension is stride 1 for contiguous arrays
      return SubHostTensor<TensorType, SubDim - 1>(
        tensor_,
        ptr_ + index);
    } else {
      return SubHostTensor<TensorType, SubDim - 1>(
        tensor_,
        ptr_ + index * tensor_.getStride(TensorType::NumDim - SubDim));
    }
  }

  /// Returns a view of the data located at our offset (the dimension
  /// `SubDim` - 1 tensor) (const).
  inline const SubHostTensor<TensorType, SubDim - 1>
  operator[](size_t index) const {
    if (TensorType::IsInnerContig && SubDim == 1) {
      // Innermost dimension is stride 1 for contiguous arrays
      return SubHostTensor<TensorType, SubDim - 1>(
        tensor_,
        ptr_ + index);
    } else {
      return SubHostTensor<TensorType, SubDim - 1>(
        tensor_,
        ptr_ + index * tensor_.getStride(TensorType::NumDim - SubDim));
    }
  }

/*

  // operator& returning T*
  typename TensorType::DataType* operator&() {
    return data_;
  }

  // const operator& returning const T*
  const typename TensorType::DataType* operator&() const {
    return data_;
  }

  /// Returns a raw accessor to our slice.
  inline typename TensorType::DataPtrType data() {
    return data_;
  }

  /// Returns a raw accessor to our slice (const).
  inline
  const typename TensorType::DataPtrType data() const {
    return data_;
  }

  /// Cast to a different datatype.
  template <typename T>
  T& as() {
    return *dataAs<T>();
  }

  /// Cast to a different datatype (const).
  template <typename T>
  const T& as() const {
    return *dataAs<T>();
  }

  /// Cast to a different datatype
  template <typename T>
  inline
  T* dataAs() {
    return reinterpret_cast<T*>(data_);
  }

  /// Cast to a different datatype (const)
  template <typename T>
  inline
  const T* dataAs() const {
    return reinterpret_cast<const T*>(data_);
  }

*/

  /// Returns a tensor that is a view of the SubDim-dimensional slice
  /// of this tensor, starting where our data begins
  HostTensor<typename TensorType::DataType,
             SubDim,
             TensorType::IsInnerContig> view() {
    return tensor_.template view<SubDim>(ptr_);
  }

 protected:
  /// One dimension greater can create us
  friend class SubHostTensor<TensorType, SubDim + 1>;

  /// Our parent tensor can create us
  friend class
  HostTensor<typename TensorType::DataType,
             TensorType::NumDim,
             TensorType::IsInnerContig>;

  inline SubHostTensor(TensorType& t, typename TensorType::DataType* ptr)
      : tensor_(t),
        ptr_(ptr) {
  }

  /// The tensor we're referencing
  TensorType& tensor_;

  /// The start of our sub-region
  typename TensorType::DataType* ptr_;
};

} // namespace detail

template <typename T, int Dim, bool InnerContig>
inline
detail::SubHostTensor<HostTensor<T, Dim, InnerContig>, Dim - 1>
HostTensor<T, Dim, InnerContig>::operator[](size_t index) {
  return detail::SubHostTensor<TensorType, Dim - 1>(
    detail::SubHostTensor<TensorType, Dim>(*this, ptr_)[index]);
}

template <typename T, int Dim, bool InnerContig>
inline
const detail::SubHostTensor<HostTensor<T, Dim, InnerContig>, Dim - 1>
HostTensor<T, Dim, InnerContig>::operator[](size_t index) const {
  return detail::SubHostTensor<TensorType, Dim - 1>(
    detail::SubHostTensor<TensorType, Dim>(
      const_cast<TensorType&>(*this), ptr_)[index]);
}

} } // namespace

#include "utils/HostTensor-inl.h"
