// Copyright (c) Facebook, Inc. and its affiliates. All Rights Reserved.
// All rights reserved.
//
// This source code is licensed under the license found in the
// LICENSE file in the root directory of this source tree.
#pragma once

#include <limits>

namespace facebook { namespace cl {

template <typename T, int Dim, bool InnerContig>
HostTensor<T, Dim, InnerContig>::HostTensor()
    : ptr_(nullptr) {
  static_assert(Dim > 0, "must have > 0 dimensions");

  for (int i = 0; i < Dim; ++i) {
    size_[i] = 0;
    stride_[i] = 1;
  }
}

/*
template <typename T, int Dim, bool InnerContig>
HostTensor<T, Dim, InnerContig>::HostTensor(
  HostTensor<T, Dim, InnerContig>& t) {
  operator=(t);
}

template <typename T, int Dim, bool InnerContig>
HostTensor<T, Dim, InnerContig>&
HostTensor<T, Dim, InnerContig>::operator=(
  HostTensor<T, Dim, InnerContig>& t) {
  ptr_ = t.ptr_;
  size_ = t.size_;
  stride_ = t.stride_;
  data_ = t.data_;

  return *this;
}

template <typename T, int Dim, bool InnerContig>
HostTensor<T, Dim, InnerContig>::HostTensor(
  HostTensor<T, Dim, InnerContig>&& t)
    : ptr_(std::move(t.ptr_)),
      size_(std::move(t.size_)),
      stride_(std::move(t.stride_)),
      data_(std::move(t.data_)) {
  operator=(std::move(t));
}

template <typename T, int Dim, bool InnerContig>
HostTensor<T, Dim, InnerContig>&
HostTensor<T, Dim, InnerContig>::operator=(
  HostTensor<T, Dim, InnerContig>&& t) {
  ptr_ = std::move(t.ptr_);
  size_ = std::move(t.size_);
  stride_ = std::move(t.stride_);
  data_ = std::move(t.data_);

  t.ptr_ = nullptr;

  for (auto& s : t.size_) {
    s = 0;
  }

  for (auto& s : t.stride_) {
    s = 0;
  }

  return *this;
}
*/

template <typename T, int Dim, bool InnerContig>
HostTensor<T, Dim, InnerContig>::HostTensor(
  HostTensorData<T> data,
  T* ptr,
  const std::array<size_t, Dim>& sizes,
  const std::array<size_t, Dim>& strides)
    : ptr_(ptr),
      size_(sizes),
      stride_(strides),
      data_(std::move(data)) {
}

template <typename T, int Dim, bool InnerContig>
HostTensor<T, Dim, InnerContig>::HostTensor(
  const std::vector<size_t>& sizes)
    : ptr_(nullptr),
      size_(toArray<size_t, Dim>(sizes)),
      stride_(calcStrideArrayFromSizeVec<Dim>(sizes)) {
  static_assert(Dim > 0, "must have > 0 dimensions");

  data_ = HostTensorData<T>(numElements());
  ptr_ = data_.data();
}

template <typename T, int Dim, bool InnerContig>
HostTensor<T, Dim, InnerContig>::HostTensor(
  const std::array<size_t, Dim>& sizes)
    : ptr_(nullptr),
      size_(sizes),
      stride_(calcStrideArrayFromSizeArray<Dim>(sizes)) {
  static_assert(Dim > 0, "must have > 0 dimensions");

  data_ = HostTensorData<T>(numElements());
  ptr_ = data_.data();
}

template <typename T, int Dim, bool InnerContig>
HostTensor<T, Dim, InnerContig>::HostTensor(
  std::initializer_list<size_t> sizes)
    : ptr_(nullptr) {
  CL_ASSERT(sizes.size() == Dim);
  static_assert(Dim > 0, "must have > 0 dimensions");

  int i = 0;
  for (auto s : sizes) {
    size_[i++] = s;
  }

  stride_ = calcStrideArrayFromSizeArray<Dim>(size_);

  data_ = HostTensorData<T>(numElements());
  ptr_ = data_.data();
}

template <typename T, int Dim, bool InnerContig>
HostTensor<T, Dim, InnerContig>::HostTensor(
  const std::array<size_t, Dim>& sizes,
  const std::array<size_t, Dim>& strides)
    : ptr_(nullptr),
      size_(sizes),
      stride_(strides) {
  static_assert(Dim > 0, "must have > 0 dimensions");

  // Find the maximum size * stride product
  size_t maxDimSize = 0;

  for (int i = 0; i < Dim; ++i) {
    size_t dimSize = sizes[i] * strides[i];
    maxDimSize = std::max(maxDimSize, dimSize);
  }

  data_ = HostTensorData<T>(numElements());
  ptr_ = data_.data();
}

template <typename T, int Dim, bool InnerContig>
void
HostTensor<T, Dim, InnerContig>::copyFrom(HostTensor<T, Dim, InnerContig>& t) {
  // The tensor must be fully contiguous
  CL_ASSERT(this->isContiguous() && t.isContiguous());

  // Size must be the same (since dimensions are checked and
  // continuity is assumed, we need only check total number of
  // elements
  CL_ASSERT(this->numElements() == t.numElements());

  if (t.ptr_ && ptr_) {
    std::copy(t.ptr_, t.ptr_ + numElements(), ptr_);
  }
}

template <typename T, int Dim, bool InnerContig>
void
HostTensor<T, Dim, InnerContig>::copyTo(HostTensor<T, Dim, InnerContig>& t) {
  // The tensor must be fully contiguous
  CL_ASSERT(this->isContiguous() && t.isContiguous());

  // Size must be the same (since dimensions are checked and
  // continuity is assumed, we need only check total number of
  // elements
  CL_ASSERT(this->numElements() == t.numElements());

  if (t.ptr_ && ptr_) {
    std::copy(ptr_, ptr_ + numElements(), t.ptr_);
  }
}

template <typename T, int Dim, bool InnerContig>
template <typename OtherT, int OtherDim>
bool
HostTensor<T, Dim, InnerContig>::isSame(
  const HostTensor<OtherT, OtherDim, InnerContig>& rhs) const {
  if (Dim != OtherDim) {
    return false;
  }

  for (int i = 0; i < Dim; ++i) {
    if (this->getSize(i) != rhs.getSize(i)) {
      return false;
    }

    if (this->getStride(i) != rhs.getStride(i)) {
      return false;
    }
  }

  return true;
}

template <typename T, int Dim, bool InnerContig>
template <typename OtherT, int OtherDim>
bool
HostTensor<T, Dim, InnerContig>::isSameSize(
  const HostTensor<OtherT, OtherDim, InnerContig>& rhs) const {
  if (Dim != OtherDim) {
    return false;
  }

  for (int i = 0; i < Dim; ++i) {
    if (this->getSize(i) != rhs.getSize(i)) {
      return false;
    }
  }

  return true;
}

template <typename T, int Dim, bool InnerContig>
template <typename IndexType>
bool
HostTensor<T, Dim, InnerContig>::isSize(
  std::initializer_list<IndexType> size) const {
  int idx = 0;
  for (auto s : size) {
    if (s != getSize(idx++)) {
      return false;
    }
  }

  if (idx != Dim) {
    return false;
  }

  return true;
}


template <typename T, int Dim, bool InnerContig>
template <typename U>
HostTensor<U, Dim, InnerContig>
HostTensor<T, Dim, InnerContig>::cast() {
  static_assert(sizeof(U) == sizeof(T), "cast must be to same size object");

  return HostTensor<U, Dim, InnerContig>(
    data_.cast<U>(),
    (U*) ptr_,
    size_,
    stride_);
}

template <typename T, int Dim, bool InnerContig>
template <typename U>
const HostTensor<U, Dim, InnerContig>
HostTensor<T, Dim, InnerContig>::cast() const {
  static_assert(sizeof(U) == sizeof(T), "cast must be to same size object");

  return HostTensor<U, Dim, InnerContig>(
    data_.cast<U>(),
    (U*) ptr_,
    size_,
    stride_);
}

template <typename T, int Dim, bool InnerContig>
template <typename U>
HostTensor<U, Dim, InnerContig>
HostTensor<T, Dim, InnerContig>::castResize() {
  static_assert(sizeof(U) >= sizeof(T), "only handles greater sizes");
  constexpr int kMultiple = sizeof(U) / sizeof(T);

  CL_ASSERT(canCastResize<U>());

  std::array<size_t, Dim> newSize = size_;
  std::array<size_t, Dim> newStride;

  for (int i = 0; i < Dim - 1; ++i) {
    newStride[i] = stride_[i] / kMultiple;
  }

  newStride[Dim - 1] = 1; // this is the same as the old stride
  newSize[Dim - 1] = size_[Dim - 1] / kMultiple;

  return HostTensor<U, Dim, InnerContig>(
    data_.cast<U>(),
    (U*) ptr_,
    newSize,
    newStride);
}

template <typename T, int Dim, bool InnerContig>
template <typename U>
const HostTensor<U, Dim, InnerContig>
HostTensor<T, Dim, InnerContig>::castResize() const {
  return const_cast<HostTensor<T, Dim, InnerContig>*>(this)->castResize<U>();
}

template <typename T, int Dim, bool InnerContig>
template <typename U>
bool
HostTensor<T, Dim, InnerContig>::canCastResize() const {
  static_assert(sizeof(U) >= sizeof(T), "only handles greater sizes");
  constexpr int kMultiple = sizeof(U) / sizeof(T);

  // Ensure that the base offset is sizeof(U) aligned
  if (((uintptr_t) ptr_) % sizeof(U) != 0) {
    return false;
  }

  // Check all outer strides
  for (int i = 0; i < Dim - 1; ++i) {
    if (stride_[i] % kMultiple != 0) {
      return false;
    }
  }

  // Check inner size
  if (size_[Dim - 1] % kMultiple != 0) {
    return false;
  }

  if (stride_[Dim - 1] != 1) {
    return false;
  }

  return true;
}

template <typename T, int Dim, bool InnerContig>
size_t
HostTensor<T, Dim, InnerContig>::numElements() const {
  size_t size = getSize(0);

  for (int i = 1; i < Dim; ++i) {
    size *= getSize(i);
  }

  return size;
}

template <typename T, int Dim, bool InnerContig>
bool
HostTensor<T, Dim, InnerContig>::isContiguous() const {
  size_t prevSize = 1;

  for (int i = Dim - 1; i >= 0; --i) {
    if (getSize(i) != 1) {
      if (getStride(i) == prevSize) {
        prevSize *= getSize(i);
      } else {
        return false;
      }
    }
  }

  return true;
}

template <typename T, int Dim, bool InnerContig>
bool
HostTensor<T, Dim, InnerContig>::isConsistentlySized(int i) const {
  if (i == 0 && getStride(i) > 0 && getSize(i) > 0) {
    return true;
  } else if ((i > 0) && (i < Dim) && (getStride(i) > 0) &&
             ((getStride(i - 1) / getStride(i)) >= getSize(i))) {
    return true;
  }

  return false;
}

template <typename T, int Dim, bool InnerContig>
bool
HostTensor<T, Dim, InnerContig>::isConsistentlySized() const {
  for (int i = 0; i < Dim; ++i) {
    if (!isConsistentlySized(i)) {
      return false;
    }
  }

  return true;
}

template <typename T, int Dim, bool InnerContig>
bool
HostTensor<T, Dim, InnerContig>::isContiguousDim(int i) const {
  return (i == Dim - 1) || // just in case
    ((i < Dim - 1) &&
     ((getStride(i) / getStride(i + 1)) == getSize(i + 1)));
}

template <typename T, int Dim, bool InnerContig>
HostTensor<T, Dim, InnerContig>
HostTensor<T, Dim, InnerContig>::transpose(int dim1, int dim2) const {
  CL_ASSERT(dim1 >= 0 && dim1 < Dim);
  CL_ASSERT(dim1 >= 0 && dim2 < Dim);

  // If a tensor is innermost contiguous, one cannot transpose the innermost
  // dimension
  if (InnerContig) {
    CL_ASSERT(dim1 != Dim - 1 && dim2 != Dim - 1);
  }

  std::array<size_t, Dim> newSize = size_;
  std::array<size_t, Dim> newStride = stride_;

  size_t tmp = newSize[dim1];
  newSize[dim1] = newSize[dim2];
  newSize[dim2] = tmp;

  tmp = newStride[dim1];
  newStride[dim1] = newStride[dim2];
  newStride[dim2] = tmp;

  return HostTensor<T, Dim, InnerContig>(data_,
                                         ptr_,
                                         newSize,
                                         newStride);
}

template <typename T, int Dim, bool InnerContig>
template <int NewDim>
HostTensor<T, NewDim, InnerContig>
HostTensor<T, Dim, InnerContig>::upcastOuter() {
  // Can only create tensors of greater dimension
  static_assert(NewDim > Dim, "Can only upcast to greater dim");

  std::array<size_t, Dim> newSize;
  std::array<size_t, Dim> newStride;

  int shift = NewDim - Dim;

  for (int i = 0; i < NewDim; ++i) {
    if (i < shift) {
      // These are the extended dimensions
      newSize[i] = 1;
      newStride[i] = size_[0] * stride_[0];
    } else {
      // Shift the remaining dimensions
      newSize[i] = size_[i - shift];
      newStride[i] = stride_[i - shift];
    }
  }

  return HostTensor<T, Dim, InnerContig>(data_,
                                         ptr_,
                                         newSize,
                                         newStride);
}

template <typename T, int Dim, bool InnerContig>
template <int NewDim>
HostTensor<T, NewDim, InnerContig>
HostTensor<T, Dim, InnerContig>::upcastInner() {
  // Can only create tensors of greater dimension
  static_assert(NewDim > Dim, "Can only upcast to greater dim");

  std::array<size_t, Dim> newSize;
  std::array<size_t, Dim> newStride;

  for (int i = 0; i < NewDim; ++i) {
    if (i < Dim) {
      // Existing dimensions get copied over
      newSize[i] = size_[i];
      newStride[i] = stride_[i];
    } else {
      // Extended dimensions
      newSize[i] = 1;
      newStride[i] = 1;
    }
  }

  return HostTensor<T, Dim, InnerContig>(data_,
                                         ptr_,
                                         newSize,
                                         newStride);
}

template <typename T, int Dim, bool InnerContig>
template <int NewDim>
HostTensor<T, NewDim, InnerContig>
HostTensor<T, Dim, InnerContig>::downcastOuter() {
  // Can only create tensors of lesser dimension
  static_assert(NewDim < Dim, "Can only downcast to lesser dim");

  // We can't downcast non-contiguous tensors, since it leaves
  // garbage data in the tensor. The tensor needs to be contiguous
  // in all of the dimensions we are collapsing (no padding in
  // them).
  for (int i = 0; i < Dim - NewDim; ++i) {
    bool cont = isContiguousDim(i);
    CL_ASSERT(cont);
  }

  std::array<size_t, Dim> newSize;
  std::array<size_t, Dim> newStride;

  int ignoredDims = Dim - NewDim;
  size_t collapsedSize = 1;

  for (int i = 0; i < Dim; ++i) {
    if (i < ignoredDims) {
      // Collapse these dimensions
      collapsedSize *= getSize(i);
    } else {
      // Non-collapsed dimensions
      if (i == ignoredDims) {
        // This is the first non-collapsed dimension
        newSize[i - ignoredDims] = collapsedSize * getSize(i);
      } else {
        // Subsequent non-collapsed dimensions
        newSize[i - ignoredDims] = getSize(i);
      }

      newStride[i - ignoredDims] = getStride(i);
    }
  }

  return HostTensor<T, Dim, InnerContig>(data_,
                                         ptr_,
                                         newSize,
                                         newStride);
}

template <typename T, int Dim, bool InnerContig>
template <int NewDim>
HostTensor<T, NewDim, InnerContig>
HostTensor<T, Dim, InnerContig>::downcastInner() {
  // Can only create tensors of lesser dimension
  static_assert(NewDim < Dim, "Can only downcast to lesser dim");

  // We can't downcast non-contiguous tensors, since it leaves
  // garbage data in the tensor. The tensor needs to be contiguous
  // in all of the dimensions we are collapsing (no padding in
  // them).
  for (int i = NewDim; i < Dim; ++i) {
    CL_ASSERT(isContiguousDim(i));
  }

  std::array<size_t, Dim> newSize;
  std::array<size_t, Dim> newStride;

  size_t collapsedSize = 1;

  for (int i = Dim - 1; i >= 0; --i) {
    if (i >= NewDim) {
      // Collapse these dimensions
      collapsedSize *= getSize(i);
    } else {
      // Non-collapsed dimensions
      if (i == NewDim - 1) {
        // This is the first non-collapsed dimension
        newSize[i] = collapsedSize * getSize(i);
        newStride[i] = getStride(Dim - 1);
      } else {
        // Subsequent non-collapsed dimensions
        newSize[i] = getSize(i);
        newStride[i] = getStride(i);
      }
    }
  }

  return HostTensor<T, Dim, InnerContig>(data_,
                                         ptr_,
                                         newSize,
                                         newStride);
}

template <typename T, int Dim, bool InnerContig>
template <int SubDim>
HostTensor<T, SubDim, InnerContig>
HostTensor<T, Dim, InnerContig>::view() {
  return view<SubDim>(ptr_);
}

template <typename T, int Dim, bool InnerContig>
template <int SubDim>
HostTensor<T, SubDim, InnerContig>
HostTensor<T, Dim, InnerContig>::view(T* ptr) {
  static_assert(SubDim >= 1 && SubDim < Dim,
                "can only create view of lesser dim");

  std::array<size_t, Dim> viewSizes;
  std::array<size_t, Dim> viewStrides;

  for (int i = 0; i < SubDim; ++i) {
    viewSizes[i] = size_[Dim - SubDim + i];
    viewStrides[i] = stride_[Dim - SubDim + i];
  }

  return HostTensor<T, Dim, InnerContig>(data_,
                                         ptr,
                                         viewSizes,
                                         viewStrides);
}

template <typename T, int Dim, bool InnerContig>
HostTensor<T, Dim, InnerContig>
HostTensor<T, Dim, InnerContig>::narrowOutermost(size_t start,
                                                 size_t size) {
  return this->narrow(0, start, size);
}

template <typename T, int Dim, bool InnerContig>
HostTensor<T, Dim, InnerContig>
HostTensor<T, Dim, InnerContig>::narrow(int dim,
                                        size_t start,
                                        size_t size) {
  T* newPtr = ptr_;

  CL_ASSERT(start >= 0 &&
            start < size_[dim] &&
            (start + size) <= size_[dim]);

  if (start > 0) {
    newPtr += start * stride_[dim];
  }

  size_t newSize[Dim];
  for (int i = 0; i < Dim; ++i) {
    if (i == dim) {
      CL_ASSERT(start + size <= size_[dim]);
      newSize[i] = size;
    } else {
      newSize[i] = size_[i];
    }
  }

  // If we were innermost contiguous before, we are still innermost contiguous
  return HostTensor<T, Dim, InnerContig>(data_,
                                         newPtr,
                                         newSize,
                                         stride_);
}

template <typename T, int Dim, bool InnerContig>
template <int NewDim>
HostTensor<T, NewDim, InnerContig>
HostTensor<T, Dim, InnerContig>::view(std::initializer_list<size_t> sizes) {
  CL_ASSERT(this->isContiguous());
  CL_ASSERT(sizes.size() == NewDim);

  // The total size of the new view must be the same as the total size
  // of the old view
  size_t curSize = numElements();
  size_t newSize = 1;
  size_t newSizes[Dim];
  int i = 0;

  for (auto s : sizes) {
    newSizes[i++] = s;
    newSize *= s;
  }

  CL_ASSERT(curSize == newSize);

  return HostTensor<T, Dim, InnerContig>(data_,
                                         ptr_,
                                         newSizes,
                                         stride_);
}

namespace detail {

template <typename TensorType>
SubHostTensor<TensorType, 0>&
SubHostTensor<TensorType, 0>::operator=(typename TensorType::DataType v) {
  *ptr_ = v;
  return *this;
}

template <typename TensorType>
SubHostTensor<TensorType, 0>::
operator const typename TensorType::DataType() const {
  return *ptr_;
}

} // namespace detail

} } // namespace
