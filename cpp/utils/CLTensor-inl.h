// Copyright (c) Facebook, Inc. and its affiliates. All Rights Reserved.
// All rights reserved.
//
// This source code is licensed under the license found in the
// LICENSE file in the root directory of this source tree.
#include "utils/CLTensor.h"

namespace facebook { namespace cl {

template <typename T>
CLTensor<T>::CLTensor()
    : dim_(0) {
}

/*
template <typename T>
CLTensor<T>::CLTensor(CLTensor<T>& t) {
  operator=(t);
}

template <typename T>
CLTensor<T>&
CLTensor<T>::operator=(CLTensor<T>& t) {
  dim_ = t.dim_;
  size_ = t.size_;
  stride_ = t.stride_;
  data_ = t.data_;
}

template <typename T>
CLTensor<T>::CLTensor(CLTensor<T>&& t) {
  operator=(std::move(t));
}

template <typename T>
CLTensor<T>&
CLTensor<T>::operator=(CLTensor<T>&& t) {
  dim_ = std::move(t.dim_);
  size_ = std::move(t.size_);
  stride_ = std::move(t.stride_);
  data_ = std::move(t.data_);

  t.dim_ = 0;

  return *this;
}
*/

template <typename T>
CLTensor<T>::CLTensor(facebook::cl::Context& context,
                      const std::vector<size_t>& sizes)
    : dim_(sizes.size()),
      size_(sizes),
      stride_(calcStrideVecFromSizeVec(sizes)) {
  data_ = std::make_shared<facebook::cl::DeviceMem<T>>(
    std::move(context.alloc<T>(numElements())));
}

template <typename T>
template <typename IndexT>
CLTensor<T>::CLTensor(facebook::cl::Context& context,
                      std::initializer_list<IndexT> sizes)
    : dim_(sizes.size()),
      size_(vecFromInitList<IndexT>(sizes)),
      stride_(calcStrideVecFromSizeVec(size_)) {
  data_ = std::make_shared<facebook::cl::DeviceMem<T>>(
    std::move(context.alloc<T>(numElements())));
}

template <typename T>
CLTensor<T>::CLTensor(facebook::cl::Context& context,
                      const std::vector<size_t>& sizes,
                      const std::vector<size_t>& strides)
    : dim_(sizes.size()),
      size_(sizes),
      stride_(strides) {
  CL_ASSERT(sizes.size() == strides.size());

  data_ = std::make_shared<facebook::cl::DeviceMem<T>>(
    std::move(context.alloc<T>(numElements())));
}

template <typename T>
template <int Dim>
CLTensor<T>::CLTensor(facebook::cl::Context& context,
                      facebook::cl::Queue& queue,
                      const HostTensor<T, Dim>& t)
    : dim_(Dim),
      size_(t.sizes().begin(), t.sizes().end()),
      stride_(t.strides().begin(), t.strides().end()) {
  data_ = std::make_shared<facebook::cl::DeviceMem<T>>(
    std::move(context.alloc<T>(numElements())));

  copyFrom(queue, t);
}

template <typename T>
template <int Dim>
CLTensor<T>::CLTensor(facebook::cl::Context& context,
                      facebook::cl::Queue& queue,
                      const CLDimTensor<T, Dim>& t)
    : dim_(Dim),
      size_(t.size_.begin(), t.size_.end()),
      stride_(t.stride_.begin(), t.stride_.end()) {

  if (t.offset() != 0) {
    auto subMem = t.data_->at(t.offset());

    data_ = std::make_shared<facebook::cl::DeviceMem<T>>(
      std::move(subMem.copy(queue)));
  } else {
    data_ = std::make_shared<facebook::cl::DeviceMem<T>>(
      std::move(t.data_->copy(queue)));
  }
}

template <typename T>
CLTensor<T>::CLTensor(std::shared_ptr<facebook::cl::DeviceMem<T>> data,
                      const std::vector<size_t>& sizes,
                      const std::vector<size_t>& strides)
    : dim_(sizes.size()),
      size_(sizes),
      stride_(strides),
      data_(data) {
  CL_ASSERT(size_.size() == stride_.size());
}

template <typename T>
facebook::cl::Event
CLTensor<T>::copyFrom(facebook::cl::Queue& queue,
                      const CLTensor<T>& t) {
  // The tensor must be fully contiguous
  CL_ASSERT(isContiguous() && t.isContiguous());

  // Size must be the same (since dimensions are checked and
  // continuity is assumed, we need only check total number of
  // elements
  CL_ASSERT(numElements() == t.numElements());

  // FIXME: handle empty tensors
  CL_ASSERT(data_);

  // if (data_) {
    CL_ASSERT(t.data_);
    CL_ASSERT(data_->size() >= numElements());
    CL_ASSERT(t.data_->size() >= numElements());

    return data_->copyD2DFrom(queue,
                              *t.data_, 0,
                              0, numElements());
  // }
}

template <typename T>
template <int Dim, bool InnerContig>
facebook::cl::Event
CLTensor<T>::copyFrom(facebook::cl::Queue& queue,
                      const HostTensor<T, Dim, InnerContig>& t) {
  // The tensor must be fully contiguous
  CL_ASSERT(isContiguous() && t.isContiguous());

  // Size must be the same (since dimensions are checked and
  // continuity is assumed, we need only check total number of
  // elements
  CL_ASSERT(numElements() == t.numElements());

  // FIXME: handle empty tensors
  CL_ASSERT(data_);

  // if (data_) {
  return data_->copyH2D(queue, t.data(), numElements(), 0);
  // }
}

template <typename T>
facebook::cl::Event
CLTensor<T>::copyTo(facebook::cl::Queue& queue,
                    CLTensor<T>& t) const{
  // The tensor must be fully contiguous
  CL_ASSERT(isContiguous() && t.isContiguous());

  // Size must be the same (since dimensions are checked and
  // continuity is assumed, we need only check total number of
  // elements
  CL_ASSERT(numElements() == t.numElements());

  // FIXME: handle empty tensors
  CL_ASSERT(data_);

//  if (data_) {
    CL_ASSERT(t.data_);
    CL_ASSERT(data_->size() >= numElements());
    CL_ASSERT(t.data_->size() >= numElements());

    return data_->copyD2DTo(queue,
                            *t.data_, 0,
                            0, numElements());
//  }
}

template <typename T>
template <int Dim, bool InnerContig>
facebook::cl::Event
CLTensor<T>::copyTo(facebook::cl::Queue& queue,
                    HostTensor<T, Dim, InnerContig>& t) const {
  CL_ASSERT(dim_ == Dim);

  // The tensor must be fully contiguous
  CL_ASSERT(isContiguous() && t.isContiguous());

  // Size must be the same (since dimensions are checked and
  // continuity is assumed, we need only check total number of
  // elements
  CL_ASSERT(numElements() == t.numElements());

  // FIXME: handle empty tensors
  CL_ASSERT(data_);

  // if (data_) {
  return data_->copyD2H(queue, t.data(), numElements(), 0);
  // }
}

template <typename T>
template <int Dim, bool InnerContig>
CLDimTensor<T, Dim, InnerContig>
CLTensor<T>::toDimTensor() {
  CL_ASSERT((InnerContig && isContiguous()) || !InnerContig);
  CL_ASSERT(dim_ == Dim);

  std::array<size_t, Dim> size;
  std::array<size_t, Dim> stride;

  for (int i = 0; i < Dim; ++i) {
    size[i] = size_[i];
    stride[i] = stride_[i];
  }

  return CLDimTensor<T, Dim, InnerContig>(data_, 0, size, stride, nullptr);
}

template <typename T>
template <int Dim, bool InnerContig>
HostTensor<T, Dim, InnerContig>
CLTensor<T>::toHost(facebook::cl::Queue& queue) const {
  auto hostT = HostTensor<T, Dim, InnerContig>(toArray<size_t, Dim>(size_));
  copyTo(queue, hostT);

  return hostT;
}

template <typename T>
template <typename IndexT>
T
CLTensor<T>::get(facebook::cl::Queue& queue,
                 std::initializer_list<IndexT> at) {
  return getDeviceMem().copyD2HScalar(queue, offset(at));
}

template <typename T>
template <typename IndexT>
void
CLTensor<T>::set(T v,
                 facebook::cl::Queue& queue,
                 std::initializer_list<IndexT> at) {
  getDeviceMem().copyH2DScalar(queue, v, offset(at));
}

template <typename T>
template <typename U>
bool
CLTensor<T>::isSame(const CLTensor<U>& rhs) const {
  if (dims() != rhs.dims()) {
    return false;
  }

  for (int i = 0; i < dims(); ++i) {
    if (getSize(i) != rhs.getSize(i)) {
      return false;
    }

    if (getStride(i) != rhs.getStride(i)) {
      return false;
    }
  }

  return true;
}

template <typename T>
template <typename U>
bool
CLTensor<T>::isSameSize(const CLTensor<U>& rhs) const {
  if (dims() != rhs.dims()) {
    return false;
  }

  for (int i = 0; i < dims(); ++i) {
    if (getSize(i) != rhs.getSize(i)) {
      return false;
    }
  }

  return true;
}

template <typename T>
template <typename IndexType>
bool
CLTensor<T>::isSize(std::initializer_list<IndexType> size) const {
  int idx = 0;
  for (auto s : size) {
    if (s != getSize(idx++)) {
      return false;
    }
  }

  if (idx != dims()) {
    return false;
  }

  return true;
}

template <typename T>
template <typename U>
bool
CLTensor<T>::isSameInstance(const CLTensor<U>& rhs) const {
  return (isSame(rhs) && data_->isSame(rhs.getDeviceMem()));
}

template <typename T>
template <typename U>
CLTensor<U>
CLTensor<T>::cast() {
  static_assert(sizeof(U) == sizeof(T), "cast must be to same size object");

  return CLTensor<U>(
    std::make_shared<facebook::cl::DeviceMem<U>>(data_->cast<U>()),
    size_,
    stride_);
}

template <typename T>
template <typename U>
CLTensor<U>
CLTensor<T>::castResize() {
  static_assert(sizeof(U) >= sizeof(T), "only handles greater sizes");
  constexpr int kMultiple = sizeof(U) / sizeof(T);

  CL_ASSERT(canCastResize<U>());

  std::vector<size_t> newSize = size_;
  std::vector<size_t> newStride(dim_);

  for (int i = 0; i < dim_ - 1; ++i) {
    newSize[i] = size_[i];
    newStride[i] = stride_[i] / kMultiple;
  }

  newStride[dim_ - 1] = 1; // this is the same as the old stride
  newSize[dim_ - 1] = size_[dim_ - 1] / kMultiple;

  return CLTensor<U>(
    std::make_shared<facebook::cl::DeviceMem<U>>(data_->cast<U>()),
    newSize,
    newStride);
}

template <typename T>
template <typename U>
const CLTensor<U>
CLTensor<T>::castResize() const {
  return const_cast<CLTensor<T>*>(this)->castResize<U>();
}

template <typename T>
template <typename U>
bool
CLTensor<T>::canCastResize() const {
  static_assert(sizeof(U) >= sizeof(T), "only handles greater sizes");
  constexpr int kMultiple = sizeof(U) / sizeof(T);

  // Check all outer strides
  for (int i = 0; i < dim_ - 1; ++i) {
    if (stride_[i] % kMultiple != 0) {
      return false;
    }
  }

  // Check inner size
  if (size_[dim_ - 1] % kMultiple != 0) {
    return false;
  }

  if (stride_[dim_ - 1] != 1) {
    return false;
  }

  return true;
}

template <typename T>
template <typename IndexT>
size_t
CLTensor<T>::offset(std::initializer_list<IndexT> at) const {
  CL_ASSERT(at.size() == dim_);

  size_t offset = 0;

  int i = 0;
  for (auto s : at) {
    offset += (size_t) s * stride_[i++];
  }

  return offset;
}

template <typename T>
size_t
CLTensor<T>::numElements() const {
  size_t size = size_[0];

  for (int i = 1; i < dim_; ++i) {
    size *= size_[i];
  }

  return size;
}

template <typename T>
bool
CLTensor<T>::isContiguous() const {
  size_t prevSize = 1;

  for (int i = dim_ - 1; i >= 0; --i) {
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

template <typename T>
bool
CLTensor<T>::isConsistentlySized(int i) const {
  if (i == 0 && getStride(i) > 0 && getSize(i) > 0) {
    return true;
  } else if ((i > 0) && (i < dim_) && (getStride(i) > 0) &&
             ((getStride(i - 1) / getStride(i)) >= getSize(i))) {
    return true;
  }

  return false;
}

template <typename T>
bool
CLTensor<T>::isConsistentlySized() const {
  for (int i = 0; i < dim_; ++i) {
    if (!isConsistentlySized(i)) {
      return false;
    }
  }

  return true;
}

template <typename T>
bool
CLTensor<T>::isContiguousDim(int i) const {
  return (i == dim_ - 1) || // just in case
    ((i < dim_ - 1) &&
     ((getStride(i) / getStride(i + 1)) == getSize(i + 1)));
}

template <typename T>
CLTensor<T>
CLTensor<T>::transpose(int dim1, int dim2) const {
  CL_ASSERT(dim1 >= 0 && dim1 < dim_);
  CL_ASSERT(dim1 >= 0 && dim2 < dim_);

  std::vector<size_t> newSize = size_;
  std::vector<size_t> newStride = stride_;

  std::swap(newSize[dim1], newSize[dim2]);
  std::swap(newStride[dim1], newStride[dim2]);

  return CLTensor<T>(data_, newSize, newStride);
}

template <typename T>
CLTensor<T>
CLTensor<T>::upcastOuter(int newDim) const {
  // Can only create tensors of greater dimension
  CL_ASSERT(newDim > dim_);

  std::vector<size_t> newSize(newDim);
  std::vector<size_t> newStride(newDim);

  int shift = newDim - dim_;

  for (int i = 0; i < newDim; ++i) {
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

  return CLTensor<T>(data_, newSize, newStride);
}

template <typename T>
CLTensor<T>
CLTensor<T>::upcastInner(int newDim) const {
  // Can only create tensors of greater dimension
  CL_ASSERT(newDim > dim_);

  std::vector<size_t> newSize(newDim);
  std::vector<size_t> newStride(newDim);

  for (int i = 0; i < newDim; ++i) {
    if (i < dim_) {
      // Existing dimensions get copied over
      newSize[i] = size_[i];
      newStride[i] = stride_[i];
    } else {
      // Extended dimensions
      newSize[i] = 1;
      newStride[i] = 1;
    }
  }

  return CLTensor<T>(data_, newSize, newStride);
}

template <typename T>
CLTensor<T>
CLTensor<T>::downcastOuter(int newDim) const {
  // Can only create tensors of lesser dimension
  CL_ASSERT(newDim < dim_);

  // We can't downcast non-contiguous tensors, since it leaves
  // garbage data in the tensor. The tensor needs to be contiguous
  // in all of the dimensions we are collapsing (no padding in
  // them).
  for (int i = 0; i < dim_ - newDim; ++i) {
    CL_ASSERT(isContiguousDim(i));
  }

  std::vector<size_t> newSize(newDim);
  std::vector<size_t> newStride(newDim);

  int ignoredDims = dim_ - newDim;
  size_t collapsedSize = 1;

  for (int i = 0; i < dim_; ++i) {
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

  return CLTensor<T>(data_, newSize, newStride);
}

template <typename T>
CLTensor<T>
CLTensor<T>::downcastInner(int newDim) const {
  // Can only create tensors of lesser dimension
  CL_ASSERT(newDim < dim_);

  // We can't downcast non-contiguous tensors, since it leaves
  // garbage data in the tensor. The tensor needs to be contiguous
  // in all of the dimensions we are collapsing (no padding in
  // them).
  for (int i = 0; i < dim_ - newDim; ++i) {
    CL_ASSERT(isContiguousDim(i));
  }

  std::vector<size_t> newSize(newDim);
  std::vector<size_t> newStride(newDim);

  size_t collapsedSize = 1;

  for (int i = dim_ - 1; i >= 0; --i) {
    if (i >= newDim) {
      // Collapse these dimensions
      collapsedSize *= getSize(i);
    } else {
      // Non-collapsed dimensions
      if (i == newDim - 1) {
        // This is the first non-collapsed dimension
        newSize[i] = collapsedSize * getSize(i);
        newStride[i] = getStride(dim_ - 1);
      } else {
        // Subsequent non-collapsed dimensions
        newSize[i] = getSize(i);
        newStride[i] = getStride(i);
      }
    }
  }

  return CLTensor<T>(data_, newSize, newStride);
}

template <typename T>
CLTensor<T>
CLTensor<T>::view(int subDim) const {
  return view(subDim, 0);
}

template <typename T>
CLTensor<T>
CLTensor<T>::view(int subDim, size_t offset) const {
  CL_ASSERT(subDim >= 1 && subDim < dim_);

  std::vector<size_t> viewSizes(subDim);
  std::vector<size_t> viewStrides(subDim);

  for (int i = 0; i < subDim; ++i) {
    viewSizes[i] = size_[dim_ - subDim + i];
    viewStrides[i] = stride_[dim_ - subDim + i];
  }

  if (offset == 0) {
    return CLTensor<T>(data_, viewSizes, viewStrides);
  } else {
    return CLTensor<T>(
      std::make_shared<facebook::cl::DeviceMem<T>>(data_->at(offset)),
      viewSizes,
      viewStrides);
  }
}

template <typename T>
CLTensor<T>
CLTensor<T>::narrowOutermost(size_t start, size_t size) const {
  return narrow(0, start, size);
}

template <typename T>
CLTensor<T>
CLTensor<T>::narrow(int dim, size_t start, size_t size) const {
  size_t newOffset = 0;

  CL_ASSERT(start >= 0 &&
            start < size_[dim] &&
            (start + size) <= size_[dim]);

  if (start > 0) {
    newOffset = start * stride_[dim];
  }

  std::vector<size_t> newSize = size_;

  CL_ASSERT(start + size <= size_[dim]);
  newSize[dim] = size;

  return CLTensor<T>(
    std::make_shared<facebook::cl::DeviceMem<T>>(data_->at(newOffset)),
    newSize,
    stride_);
}

template <typename T>
CLTensor<T>
CLTensor<T>::view(std::initializer_list<size_t> sizes) const {
  return view(vecFromInitList(sizes));
}

template <typename T>
CLTensor<T>
CLTensor<T>::view(const std::vector<size_t>& sizes) const {
  CL_ASSERT(isContiguous());

  // The total size of the new view must be the same as the total size
  // of the old view
  size_t newSize = 1;

  for (auto s : sizes) {
    newSize *= s;
  }

  CL_ASSERT(numElements() == newSize);
  std::vector<size_t> newStrides(calcStrideVecFromSizeVec(sizes));

  return CLTensor<T>(data_, sizes, newStrides);
}

} } // namespace
