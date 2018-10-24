// Copyright (c) Facebook, Inc. and its affiliates. All Rights Reserved.
// All rights reserved.
//
// This source code is licensed under the license found in the
// LICENSE file in the root directory of this source tree.
#pragma once

#include <limits>

namespace facebook { namespace cl {

template <typename T, int Dim, bool InnerContig>
CLDimTensor<T, Dim, InnerContig>::CLDimTensor()
    : offset_(0),
      queue_(nullptr) {
  static_assert(Dim > 0, "must have > 0 dimensions");

  for (int i = 0; i < Dim; ++i) {
    size_[i] = 0;
    stride_[i] = 1;
  }
}

/*
template <typename T, int Dim, bool InnerContig>
CLDimTensor<T, Dim, InnerContig>::CLDimTensor(
  CLDimTensor<T, Dim, InnerContig>&& t)
    : offset_(std::move(t.offset_)),
      size_(std::move(t.size_)),
      stride_(std::move(t.stride_)),
      data_(std::move(t.data_)),
      queue_(std::move(t.queue_)) {
  t.offset_ = 0;
  for (auto& s : t.size_) {
    s = 0;
  }

  for (auto& s : t.stride_) {
    s = 0;
  }

  t.data_ = nullptr;
  t.queue_ = nullptr;
}

template <typename T, int Dim, bool InnerContig>
CLDimTensor<T, Dim, InnerContig>&
CLDimTensor<T, Dim, InnerContig>::operator=(
  CLDimTensor<T, Dim, InnerContig>&& t) {
  offset_ = t.offset_;
  stride_ = std::move(t.stride_);
  size_ = std::move(t.size_);
  data_ = std::move(t.data_);
  queue_ = std::move(t.queue_);

  t.offset_ = 0;
  for (auto& s : t.size_) {
    s = 0;
  }

  for (auto& s : t.stride_) {
    s = 0;
  }

  t.data_ = nullptr;
  t.queue_ = nullptr;

  return *this;
}
*/

template <typename T, int Dim, bool InnerContig>
CLDimTensor<T, Dim, InnerContig>::CLDimTensor(facebook::cl::Context& context,
                                              facebook::cl::Queue& queue,
                                              HostTensor<T, Dim, InnerContig>& t)
    : CLDimTensor(context, t.sizes()) {
  CL_ASSERT(t.isContiguous());

  // FIXME: figure out better way to do this
  queue_ = &queue;
  copyFrom(t);
  queue_ = nullptr;
}

template <typename T, int Dim, bool InnerContig>
CLDimTensor<T, Dim, InnerContig>::CLDimTensor(
  std::shared_ptr<facebook::cl::DeviceMem<T>> data,
  size_t offset,
  const std::array<size_t, Dim>& sizes,
  const std::array<size_t, Dim>& strides,
  facebook::cl::Queue* queue)
    : offset_(offset),
      size_(sizes),
      stride_(strides),
      data_(data),
      queue_(queue) {
}

template <typename T, int Dim, bool InnerContig>
CLDimTensor<T, Dim, InnerContig>::CLDimTensor(
  facebook::cl::Context& context,
  const std::array<size_t, Dim>& sizes)
    : offset_(0),
      size_(sizes),
      queue_(nullptr) {
  static_assert(Dim > 0, "must have > 0 dimensions");

  stride_[Dim - 1] = 1;
  for (int i = Dim - 2; i >= 0; --i) {
    stride_[i] = stride_[i + 1] * sizes[i + 1];
  }

  data_ = std::make_shared<facebook::cl::DeviceMem<T>>(
    std::move(context.alloc<T>(numElements())));
}

template <typename T, int Dim, bool InnerContig>
template <typename IndexT>
CLDimTensor<T, Dim, InnerContig>::CLDimTensor(
  facebook::cl::Context& context,
  std::initializer_list<IndexT> sizes)
    : offset_(0),
      queue_(nullptr) {
  CL_ASSERT(sizes.size() == Dim);
  static_assert(Dim > 0, "must have > 0 dimensions");

  int i = 0;
  for (auto s : sizes) {
    size_[i++] = (size_t) s;
  }

  stride_[Dim - 1] = 1;
  for (int j = Dim - 2; j >= 0; --j) {
    stride_[j] = stride_[j + 1] * size_[j + 1];
  }

  data_ = std::make_shared<facebook::cl::DeviceMem<T>>(
    context.alloc<T>(numElements()));
}

template <typename T, int Dim, bool InnerContig>
CLDimTensor<T, Dim, InnerContig>::CLDimTensor(
  facebook::cl::Context& context,
  const std::array<size_t, Dim>& sizes,
  const std::array<size_t, Dim>& strides)
    : offset_(0),
      size_(sizes),
      stride_(strides),
      queue_(nullptr) {
  static_assert(Dim > 0, "must have > 0 dimensions");

  // Find the maximum size * stride product
  size_t maxDimSize = 0;

  for (int i = 0; i < Dim; ++i) {
    size_t dimSize = sizes[i] * strides[i];
    maxDimSize = std::max(maxDimSize, dimSize);
  }

  data_ = std::make_shared<facebook::cl::DeviceMem<T>>(
    context.alloc<T>(maxDimSize));
}

template <typename T, int Dim, bool InnerContig>
CLDimTensor<T, Dim, InnerContig>
CLDimTensor<T, Dim, InnerContig>::with(facebook::cl::Queue& queue) {
  CL_ASSERT(!queue_);
  return CLDimTensor<T, Dim, InnerContig>(data_,
                                          offset_,
                                          size_,
                                          stride_,
                                          &queue);
}

template <typename T, int Dim, bool InnerContig>
HostTensor<T, Dim, InnerContig>
CLDimTensor<T, Dim, InnerContig>::toHost() {
  // We only handle contiguous copies
  CL_ASSERT(isContiguous());

  auto hostT = HostTensor<T, Dim, InnerContig>(size_);
  copyTo(hostT);
  return hostT;
}

template <typename T, int Dim, bool InnerContig>
void
CLDimTensor<T, Dim, InnerContig>::copyFrom(CLDimTensor<T, Dim, InnerContig>& t) {
  // We must have a queue that is ordered with
  CL_ASSERT(queue_);

  // The tensor must be fully contiguous
  CL_ASSERT(this->isContiguous() && t.isContiguous());

  // Size must be the same (since dimensions are checked and
  // continuity is assumed, we need only check total number of
  // elements
  CL_ASSERT(this->numElements() == t.numElements());

  if (data_) {
    CL_ASSERT(t.data_);
    CL_ASSERT(data_->size() - offset_ >= numElements());
    CL_ASSERT(t.data_->size() - t.offset_ >= numElements());

    data_->copyD2DFrom(*queue_,
                       *t->data_, t.offset_,
                       offset_, numElements());
  }
}

template <typename T, int Dim, bool InnerContig>
void
CLDimTensor<T, Dim, InnerContig>::copyFrom(HostTensor<T, Dim, InnerContig>& t) {
  // We must have a queue that is ordered with
  CL_ASSERT(queue_);

  // The tensor must be fully contiguous
  CL_ASSERT(this->isContiguous() && t.isContiguous());

  // Size must be the same (since dimensions are checked and
  // continuity is assumed, we need only check total number of
  // elements
  CL_ASSERT(this->numElements() == t.numElements());

  if (data_) {
    data_->copyH2D(*queue_, t.data(), numElements(), offset_);
  }
}

template <typename T, int Dim, bool InnerContig>
void
CLDimTensor<T, Dim, InnerContig>::copyTo(CLDimTensor<T, Dim, InnerContig>& t) {
  // We must have a queue that is ordered with
  CL_ASSERT(queue_);

  // The tensor must be fully contiguous
  CL_ASSERT(this->isContiguous() && t.isContiguous());

  // Size must be the same (since dimensions are checked and
  // continuity is assumed, we need only check total number of
  // elements
  CL_ASSERT(this->numElements() == t.numElements());

  if (data_) {
    CL_ASSERT(t.data_);
    CL_ASSERT(data_->size() - offset_ >= this->numElements());
    CL_ASSERT(t.data_->size() - t.offset_ >= this->numElements());

    data_->copyD2DTo(*queue_,
                     *t->data_, offset_,
                     t.offset_, numElements());
  }
}

template <typename T, int Dim, bool InnerContig>
void
CLDimTensor<T, Dim, InnerContig>::copyTo(HostTensor<T, Dim, InnerContig>& t) {
  // We must have a queue that is ordered with
  CL_ASSERT(queue_);

  // The tensor must be fully contiguous
  CL_ASSERT(this->isContiguous() && t.isContiguous());

  // Size must be the same (since dimensions are checked and
  // continuity is assumed, we need only check total number of
  // elements
  CL_ASSERT(this->numElements() == t.numElements());

  if (data_) {
    data_->copyD2H(*queue_, t.data(), numElements(), offset_);
  }
}

template <typename T, int Dim, bool InnerContig>
template <typename OtherT, int OtherDim>
bool
CLDimTensor<T, Dim, InnerContig>::isSame(
  const CLDimTensor<OtherT, OtherDim, InnerContig>& rhs) const {
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
CLDimTensor<T, Dim, InnerContig>::isSameSize(
  const CLDimTensor<OtherT, OtherDim, InnerContig>& rhs) const {
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
template <typename U>
CLDimTensor<U, Dim, InnerContig>
CLDimTensor<T, Dim, InnerContig>::cast() {
  static_assert(sizeof(U) == sizeof(T), "cast must be to same size object");

  return CLDimTensor<U, Dim, InnerContig>(
    std::make_shared<facebook::cl::DeviceMem<U>>(data_->cast<U>()),
    offset_,
    size_,
    stride_,
    queue_);
}

template <typename T, int Dim, bool InnerContig>
template <typename U>
const CLDimTensor<U, Dim, InnerContig>
CLDimTensor<T, Dim, InnerContig>::cast() const {
  static_assert(sizeof(U) == sizeof(T), "cast must be to same size object");

  return CLDimTensor<U, Dim, InnerContig>(
    std::make_shared<facebook::cl::DeviceMem<U>>(data_->cast<U>()),
    offset_,
    size_,
    stride_,
    queue_);
}

template <typename T, int Dim, bool InnerContig>
template <typename U>
CLDimTensor<U, Dim, InnerContig>
CLDimTensor<T, Dim, InnerContig>::castResize() {
  static_assert(sizeof(U) >= sizeof(T), "only handles greater sizes");
  constexpr int kMultiple = sizeof(U) / sizeof(T);

  CL_ASSERT(canCastResize<U>());

  std::array<size_t, Dim> newSize = size_;
  std::array<size_t, Dim> newStride;

  for (int i = 0; i < Dim - 1; ++i) {
    newSize[i] = size_[i];
    newStride[i] = stride_[i] / kMultiple;
  }

  newStride[Dim - 1] = 1; // this is the same as the old stride
  newSize[Dim - 1] = size_[Dim - 1] / kMultiple;

  return CLDimTensor<U, Dim, InnerContig>(
    std::make_shared<facebook::cl::DeviceMem<U>>(data_->cast<U>()),
    offset_ / kMultiple,
    newSize,
    newStride,
    queue_);
}

template <typename T, int Dim, bool InnerContig>
template <typename U>
const CLDimTensor<U, Dim, InnerContig>
CLDimTensor<T, Dim, InnerContig>::castResize() const {
  return const_cast<CLDimTensor<T, Dim, InnerContig>*>(this)->castResize<U>();
}

template <typename T, int Dim, bool InnerContig>
template <typename U>
bool
CLDimTensor<T, Dim, InnerContig>::canCastResize() const {
  static_assert(sizeof(U) >= sizeof(T), "only handles greater sizes");
  constexpr int kMultiple = sizeof(U) / sizeof(T);

  // Ensure that the base offset is sizeof(U) aligned
  if ((offset_ * sizeof(T)) % sizeof(U) != 0) {
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
CLDimTensor<T, Dim, InnerContig>::numElements() const {
  size_t size = getSize(0);

  for (int i = 1; i < Dim; ++i) {
    size *= getSize(i);
  }

  return size;
}

template <typename T, int Dim, bool InnerContig>
bool
CLDimTensor<T, Dim, InnerContig>::isContiguous() const {
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
CLDimTensor<T, Dim, InnerContig>::isConsistentlySized(int i) const {
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
CLDimTensor<T, Dim, InnerContig>::isConsistentlySized() const {
  for (int i = 0; i < Dim; ++i) {
    if (!isConsistentlySized(i)) {
      return false;
    }
  }

  return true;
}

template <typename T, int Dim, bool InnerContig>
bool
CLDimTensor<T, Dim, InnerContig>::isContiguousDim(int i) const {
  return (i == Dim - 1) || // just in case
    ((i < Dim - 1) &&
     ((getStride(i) / getStride(i + 1)) == getSize(i + 1)));
}

template <typename T, int Dim, bool InnerContig>
CLDimTensor<T, Dim, InnerContig>
CLDimTensor<T, Dim, InnerContig>::transpose(int dim1, int dim2) const {
  CL_ASSERT(dim1 >= 0 && dim1 < Dim);
  CL_ASSERT(dim1 >= 0 && dim2 < Dim);

  // If a tensor is innermost contiguous, one cannot transpose the innermost
  // dimension
  if (InnerContig) {
    CL_ASSERT(dim1 != Dim - 1 && dim2 != Dim - 1);
  }

  std::array<size_t, Dim> newSize = size_;
  std::array<size_t, Dim> newStride = stride_;

  std::swap(newSize[dim1], newSize[dim2]);
  std::swap(newStride[dim1], newStride[dim2]);

  return CLDimTensor<T, Dim, InnerContig>(data_,
                                          offset_,
                                          newSize,
                                          newStride,
                                          queue_);
}

template <typename T, int Dim, bool InnerContig>
template <int NewDim>
CLDimTensor<T, NewDim, InnerContig>
CLDimTensor<T, Dim, InnerContig>::upcastOuter() {
  // Can only create tensors of greater dimension
  static_assert(NewDim > Dim, "Can only upcast to greater dim");

  std::array<size_t, NewDim> newSize;
  std::array<size_t, NewDim> newStride;

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

  return CLDimTensor<T, Dim, InnerContig>(data_,
                                          offset_,
                                          newSize,
                                          newStride,
                                          queue_);
}

template <typename T, int Dim, bool InnerContig>
template <int NewDim>
CLDimTensor<T, NewDim, InnerContig>
CLDimTensor<T, Dim, InnerContig>::upcastInner() {
  // Can only create tensors of greater dimension
  static_assert(NewDim > Dim, "Can only upcast to greater dim");

  std::array<size_t, NewDim> newSize;
  std::array<size_t, NewDim> newStride;

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

  return CLDimTensor<T, Dim, InnerContig>(data_,
                                          offset_,
                                          newSize,
                                          newStride,
                                          queue_);
}

template <typename T, int Dim, bool InnerContig>
template <int NewDim>
CLDimTensor<T, NewDim, InnerContig>
CLDimTensor<T, Dim, InnerContig>::downcastOuter() {
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

  std::array<size_t, NewDim> newSize;
  std::array<size_t, NewDim> newStride;

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

  return CLDimTensor<T, Dim, InnerContig>(data_,
                                          offset_,
                                          newSize,
                                          newStride,
                                          queue_);
}

template <typename T, int Dim, bool InnerContig>
template <int NewDim>
CLDimTensor<T, NewDim, InnerContig>
CLDimTensor<T, Dim, InnerContig>::downcastInner() {
  // Can only create tensors of lesser dimension
  static_assert(NewDim < Dim, "Can only downcast to lesser dim");

  // We can't downcast non-contiguous tensors, since it leaves
  // garbage data in the tensor. The tensor needs to be contiguous
  // in all of the dimensions we are collapsing (no padding in
  // them).
  for (int i = NewDim; i < Dim; ++i) {
    CL_ASSERT(isContiguousDim(i));
  }

  std::array<size_t, NewDim> newSize;
  std::array<size_t, NewDim> newStride;

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

  return CLDimTensor<T, NewDim, InnerContig>(data_,
                                             offset_,
                                             newSize,
                                             newStride,
                                             queue_);
}

template <typename T, int Dim, bool InnerContig>
template <int SubDim>
CLDimTensor<T, SubDim, InnerContig>
CLDimTensor<T, Dim, InnerContig>::view() {
  return view<SubDim>(0);
}

template <typename T, int Dim, bool InnerContig>
template <int SubDim>
CLDimTensor<T, SubDim, InnerContig>
CLDimTensor<T, Dim, InnerContig>::view(size_t offset) {
  static_assert(SubDim >= 1 && SubDim < Dim,
                "can only create view of lesser dim");

  std::array<size_t, SubDim> viewSizes;
  std::array<size_t, SubDim> viewStrides;

  for (int i = 0; i < SubDim; ++i) {
    viewSizes[i] = size_[Dim - SubDim + i];
    viewStrides[i] = stride_[Dim - SubDim + i];
  }

  return CLDimTensor<T, SubDim, InnerContig>(data_,
                                             offset_ + offset,
                                             viewSizes,
                                             viewStrides,
                                             queue_);
}

template <typename T, int Dim, bool InnerContig>
CLDimTensor<T, Dim, InnerContig>
CLDimTensor<T, Dim, InnerContig>::narrowOutermost(size_t start,
                                                  size_t size) {
  return this->narrow(0, start, size);
}

template <typename T, int Dim, bool InnerContig>
CLDimTensor<T, Dim, InnerContig>
CLDimTensor<T, Dim, InnerContig>::narrow(int dim,
                                         size_t start,
                                         size_t size) {
  size_t newOffset = offset_;

  CL_ASSERT(start >= 0 &&
            start < size_[dim] &&
            (start + size) <= size_[dim]);

  if (start > 0) {
    newOffset += start * stride_[dim];
  }

  std::array<size_t, Dim> newSize = size_;

  CL_ASSERT(start + size <= size_[dim]);
  newSize[dim] = size;

  // If we were innermost contiguous before, we are still innermost contiguous
  return CLDimTensor<T, Dim, InnerContig>(data_,
                                          newOffset,
                                          newSize,
                                          stride_,
                                          queue_);
}

template <typename T, int Dim, bool InnerContig>
template <int NewDim, typename IndexT>
CLDimTensor<T, NewDim, InnerContig>
CLDimTensor<T, Dim, InnerContig>::view(std::initializer_list<IndexT> sizes) {
  CL_ASSERT(this->isContiguous());
  CL_ASSERT(sizes.size() == NewDim);

  // The total size of the new view must be the same as the total size
  // of the old view
  size_t curSize = numElements();
  size_t newSize = 1;

  std::array<size_t, NewDim> newSizes;
  std::array<size_t, NewDim> newStrides;

  int i = 0;

  for (auto s : sizes) {
    newSizes[i++] = (IndexT) s;
    newSize *= (IndexT) s;
  }

  CL_ASSERT(curSize == newSize);

  newStrides[NewDim - 1] = 1;
  for (int j = NewDim - 2; j >= 0; --j) {
    newStrides[j] = newStrides[j + 1] * size_[j + 1];
  }

  return CLDimTensor<T, NewDim, InnerContig>(data_,
                                             offset_,
                                             newSizes,
                                             newStrides,
                                             queue_);
}

namespace detail {

template <typename TensorType>
SubCLDimTensor<TensorType, 0>&
SubCLDimTensor<TensorType, 0>::operator=(typename TensorType::DataType v) {
  tensor_.getDeviceMem().copyH2D(tensor_.getQueue(), &v, 1, offset_);

  return *this;
}

template <typename TensorType>
SubCLDimTensor<TensorType, 0>::
operator const typename TensorType::DataType() const {
  typename TensorType::DataType v;
  return tensor_.getDeviceMem().copyD2H(tensor_.getQueue(), &v, 1, offset_);

  return v;
}

} // namespace detail

} } // namespace
