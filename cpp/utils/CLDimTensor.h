// Copyright (c) Facebook, Inc. and its affiliates. All Rights Reserved.
// All rights reserved.
//
// This source code is licensed under the license found in the
// LICENSE file in the root directory of this source tree.
#pragma once

#include "utils/Context.h"
#include "utils/CopyUtils.h"
#include "utils/DeviceMem.h"
#include "utils/Event.h"
#include "utils/Kernel.h"
#include "utils/Queue.h"
#include <array>
#include <initializer_list>
#include <memory>

namespace facebook { namespace cl {

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
class CLDimTensor {
 public:
  enum { NumDim = Dim };
  typedef T DataType;
  enum { IsInnerContig = InnerContig };
  typedef CLDimTensor<T, Dim, InnerContig> TensorType;

  /// Default constructor
  CLDimTensor();

  /*
  /// Addrefs the tensor; does not copy
  CLDimTensor(CLDimTensor<T, Dim, InnerContig>& t) = default;

  /// Addrefs the tensor; does not copy
  CLDimTensor<T, Dim, InnerContig>&
  operator=(CLDimTensor<T, Dim, InnerContig>& t) = default;

  /// Move constructor
  CLDimTensor(CLDimTensor<T, Dim, InnerContig>&& t);

  /// Move assignment
  CLDimTensor<T, Dim, InnerContig>&
  operator=(CLDimTensor<T, Dim, InnerContig>&& t);
  */

  /// Construct a new device tensor, copying from the host (blocking copy)
  CLDimTensor(facebook::cl::Context& context,
              facebook::cl::Queue& queue,
              HostTensor<T, Dim, InnerContig>& t);

  /// Constructor that calculates strides with no padding
  /// Host constructor
  CLDimTensor(facebook::cl::Context& context,
              const std::array<size_t, Dim>& sizes);

  template <typename IndexT>
  CLDimTensor(facebook::cl::Context& context,
              std::initializer_list<IndexT> sizes);

  /// Constructor that takes arbitrary size/stride arrays.
  /// Errors if you attempt to pass non-contiguous strides to a
  /// contiguous tensor.
  /// Host constructor
  CLDimTensor(facebook::cl::Context& context,
              const std::array<size_t, Dim>& sizes,
              const std::array<size_t, Dim>& strides);

 protected:
  CLDimTensor(std::shared_ptr<facebook::cl::DeviceMem<T>> data,
              size_t offset,
              const std::array<size_t, Dim>& sizes,
              const std::array<size_t, Dim>& strides,
              facebook::cl::Queue* queue);

 public:
  /// Associates a tensor with this queue
  CLDimTensor<T, Dim, InnerContig> with(facebook::cl::Queue& queue);

  /// Creates a new host tensor and copies to the host
  HostTensor<T, Dim, InnerContig> toHost();

  /// Copies a tensor into ourselves; sizes must match
  void copyFrom(CLDimTensor<T, Dim, InnerContig>& t);

  /// Copies a host tensor into ourselves; sizes must match
  void copyFrom(HostTensor<T, Dim, InnerContig>& t);

  /// Copies ourselves into a tensor; sizes must match
  void copyTo(CLDimTensor<T, Dim, InnerContig>& t);

  /// Copies ourselves into a host tensor; sizes must match
  void copyTo(HostTensor<T, Dim, InnerContig>& t);

  /// Returns true if the two tensors are of the same dimensionality,
  /// size and stride.
  template <typename OtherT, int OtherDim>
  bool isSame(const CLDimTensor<OtherT, OtherDim, InnerContig>& rhs) const;

  /// Returns true if the two tensors are of the same dimensionality and size
  template <typename OtherT, int OtherDim>
  bool isSameSize(const CLDimTensor<OtherT, OtherDim, InnerContig>& rhs) const;

  /// Cast to a tensor of a different type of the same size and
  /// stride. U and our type T must be of the same size
  template <typename U>
  CLDimTensor<U, Dim, InnerContig> cast();

  /// Const version of `cast`
  template <typename U>
  const CLDimTensor<U, Dim, InnerContig> cast() const;

  /// Cast to a tensor of a different type which is potentially a
  /// different size than our type T. Tensor must be aligned and the
  /// innermost dimension must be a size that is a multiple of
  /// sizeof(U) / sizeof(T), and the stride of the innermost dimension
  /// must be contiguous. The stride of all outer dimensions must be a
  /// multiple of sizeof(U) / sizeof(T) as well.
  template <typename U>
  CLDimTensor<U, Dim, InnerContig> castResize();

  /// Const version of `castResize`
  template <typename U>
  const CLDimTensor<U, Dim, InnerContig>
  castResize() const;

  /// Returns true if we can castResize() this tensor to the new type
  template <typename U>
  bool canCastResize() const;

  /// Returns our current offset
  size_t offset() const {
    return offset_;
  }

  facebook::cl::Queue& getQueue() {
    CL_ASSERT(queue_);
    return *queue_;
  }

  /// Returns our memory object
  facebook::cl::DeviceMem<T>& getDeviceMem() {
    CL_ASSERT(data_);
    return *data_;
  }

  const facebook::cl::DeviceMem<T>& getDeviceMem() const {
    CL_ASSERT(data_);
    return *data_;
  }

/*

/// Returns a raw pointer to the end of our data, assuming
/// continuity
inline T* end() {
CL_ASSERT(hostData_);
return data() + numElements();
}

/// Returns a raw pointer to the start of our data (const).
inline const T* data() const {
CL_ASSERT(hostData_);
return hostData_->data<T>(offset_);
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
  inline detail::SubCLDimTensor<TensorType, Dim - 1>
  operator[](size_t);

  /// Returns a read/write view of a portion of our tensor (const).
  inline const detail::SubCLDimTensor<TensorType, Dim - 1>
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
  CLDimTensor<T, Dim, InnerContig>
  transpose(int dim1, int dim2) const;

  /// Upcast a tensor of dimension `D` to some tensor of dimension
  /// D' > D by padding the leading dimensions by 1
  /// e.g., upcasting a 2-d tensor `[2][3]` to a 4-d tensor `[1][1][2][3]`
  template <int NewDim>
  CLDimTensor<T, NewDim, InnerContig> upcastOuter();

  /// Upcast a tensor of dimension `D` to some tensor of dimension
  /// D' > D by padding the lowest/most varying dimensions by 1
  /// e.g., upcasting a 2-d tensor `[2][3]` to a 4-d tensor `[2][3][1][1]`
  template <int NewDim>
  CLDimTensor<T, NewDim, InnerContig> upcastInner();

  /// Downcast a tensor of dimension `D` to some tensor of dimension
  /// D' < D by collapsing the leading dimensions. asserts if there is
  /// padding on the leading dimensions.
  template <int NewDim>
  CLDimTensor<T, NewDim, InnerContig> downcastOuter();

  /// Downcast a tensor of dimension `D` to some tensor of dimension
  /// D' < D by collapsing the leading dimensions. asserts if there is
  /// padding on the leading dimensions.
  template <int NewDim>
  CLDimTensor<T, NewDim, InnerContig> downcastInner();

  /// Returns a tensor that is a view of the `SubDim`-dimensional slice
  /// of this tensor, starting where our data begins
  template <int SubDim>
  CLDimTensor<T, SubDim, InnerContig> view();

  /// View beginning at a particular offset
  template <int SubDim>
  CLDimTensor<T, SubDim, InnerContig> view(size_t offset);

  /// Returns a tensor of the same dimension that is a view of the
  /// original tensor with the specified dimension restricted to the
  /// elements in the range [start, start + size)
  CLDimTensor<T, Dim, InnerContig>
  narrowOutermost(size_t start, size_t size);

  /// Returns a tensor of the same dimension that is a view of the
  /// original tensor with the specified dimension restricted to the
  /// elements in the range [start, start + size).
  /// Can occur in an arbitrary dimension
  CLDimTensor<T, Dim, InnerContig>
  narrow(int dim, size_t start, size_t size);

  /// Returns a view of the given tensor expressed as a tensor of a
  /// different number of dimensions.
  /// Only works if we are contiguous.
  template <int NewDim, typename IndexT>
  CLDimTensor<T, NewDim, InnerContig>
  view(std::initializer_list<IndexT> sizes);

 protected:
  friend class CLTensor<T>;

  /// Offset beginning at
  size_t offset_;

  /// Size per each dimension
  std::array<size_t, Dim> size_;

  /// Array of strides (in sizeof(T) terms) per each dimension
  std::array<size_t, Dim> stride_;

  std::shared_ptr<facebook::cl::DeviceMem<T>> data_;
  facebook::cl::Queue* queue_;
};

namespace detail {

/// Specialization for a view of a single value (0-dimensional)
template <typename TensorType>
class SubCLDimTensor<TensorType, 0> {
 public:
  // Assign a value from the host
  SubCLDimTensor<TensorType, 0>& operator=(typename TensorType::DataType v);

  // Return a value from the device
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
  friend class SubCLDimTensor<TensorType, 1>;

  /// Our parent tensor can create us
  friend class CLDimTensor<typename TensorType::DataType,
                           1,
                           TensorType::IsInnerContig>;

  inline SubCLDimTensor(TensorType& t, size_t offset)
      : tensor_(t),
        offset_(offset) {
  }

  /// The tensor we're referencing
  TensorType& tensor_;

  /// Where our value is located
  size_t offset_;
};

/// A `SubDim`-rank slice of a parent Tensor
template <typename TensorType, int SubDim>
class SubCLDimTensor {
 public:
  /// Returns a view of the data located at our offset (the dimension
  /// `SubDim` - 1 tensor).
  inline SubCLDimTensor<TensorType, SubDim - 1>
  operator[](size_t index) {
    if (TensorType::IsInnerContig && SubDim == 1) {
      // Innermost dimension is stride 1 for contiguous arrays
      return SubCLDimTensor<TensorType, SubDim - 1>(
        tensor_,
        offset_ + index);
    } else {
      return SubCLDimTensor<TensorType, SubDim - 1>(
        tensor_,
        offset_ + index * tensor_.getStride(TensorType::NumDim - SubDim));
    }
  }

  /// Returns a view of the data located at our offset (the dimension
  /// `SubDim` - 1 tensor) (const).
  inline const SubCLDimTensor<TensorType, SubDim - 1>
  operator[](size_t index) const {
    if (TensorType::IsInnerContig && SubDim == 1) {
      // Innermost dimension is stride 1 for contiguous arrays
      return SubCLDimTensor<TensorType, SubDim - 1>(
        tensor_,
        offset_ + index);
    } else {
      return SubCLDimTensor<TensorType, SubDim - 1>(
        tensor_,
        offset_ + index * tensor_.getStride(TensorType::NumDim - SubDim));
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
  CLDimTensor<typename TensorType::DataType,
              SubDim,
              TensorType::IsInnerContig> view() {
    return tensor_.template view<SubDim>(offset_);
  }

 protected:
  /// One dimension greater can create us
  friend class SubCLDimTensor<TensorType, SubDim + 1>;

  /// Our parent tensor can create us
  friend class
  CLDimTensor<typename TensorType::DataType,
              TensorType::NumDim,
              TensorType::IsInnerContig>;

  inline SubCLDimTensor(TensorType& t, size_t offset)
      : tensor_(t),
        offset_(offset) {
  }

  /// The tensor we're referencing
  TensorType& tensor_;

  /// The start of our sub-region
  size_t offset_;
};

} // namespace detail

template <typename T, int Dim, bool InnerContig>
inline
detail::SubCLDimTensor<CLDimTensor<T, Dim, InnerContig>, Dim - 1>
CLDimTensor<T, Dim, InnerContig>::operator[](size_t index) {
  return detail::SubCLDimTensor<TensorType, Dim - 1>(
    detail::SubCLDimTensor<TensorType, Dim>(*this, offset_)[index]);
}

template <typename T, int Dim, bool InnerContig>
inline
const detail::SubCLDimTensor<CLDimTensor<T, Dim, InnerContig>, Dim - 1>
CLDimTensor<T, Dim, InnerContig>::operator[](size_t index) const {
  return detail::SubCLDimTensor<TensorType, Dim - 1>(
    detail::SubCLDimTensor<TensorType, Dim>(
      const_cast<TensorType&>(*this), offset_)[index]);
}

/// For passing a CLDimTensor to a kernel
template <typename T, int Dim, bool InnerContig>
struct PassArg<CLDimTensor<T, Dim, InnerContig>> {
  static void pass(facebook::cl::Kernel& kernel,
                   unsigned int num,
                   const CLDimTensor<T, Dim, InnerContig>& arg) {
    CL_ASSERT(arg.isContiguous());

    // If we are starting from some offset, use that
    DeviceMem<T> offsetMem;
    cl_mem m = arg.getDeviceMem().get();

    if (arg.offset() != 0) {
      offsetMem = arg.getDeviceMem().at(arg.offset());
      m = offsetMem.get();
    }

    CHECK_CL(clSetKernelArg(kernel, num, sizeof(cl_mem), &m));
  }
};

} } // namespace

#include "utils/CLDimTensor-inl.h"
