// Copyright (c) Facebook, Inc. and its affiliates. All Rights Reserved.
// All rights reserved.
//
// This source code is licensed under the license found in the
// LICENSE file in the root directory of this source tree.
#include "ops/TensorMemory.h"
#include "utils/MathUtils.h"

namespace facebook { namespace cl {

Event
runMemset(Context& context,
          Program& program,
          Queue& queue,
          FloatType<kWidth>::T v,
          CLTensor<FloatType<kWidth>::T>& inOut) {
  auto ker = program.getKernel("mem_8");

  return ker.callTask(queue,
                      inOut, // dummy
                      (unsigned int) 0,
                      v,
                      kHostScalarOp,
                      inOut, // dst
                      (unsigned int) 0,
                      1,
                      (unsigned int) inOut.numElements(),
                      0,
                      0);
}

Event
runMemcpy(Context& context,
          Program& program,
          Queue& queue,
          const CLTensor<FloatType<kWidth>::T>& src,
          unsigned int batchSize,
          unsigned int numBatches,
          unsigned int srcBatchStride,
          unsigned int dstBatchStride,
          CLTensor<FloatType<kWidth>::T>& dst) {
  auto ker = program.getKernel("mem_8");

  return ker.callTask(queue,
                      src,
                      (unsigned int) 0,
                      (FloatType<kWidth>::T) 0,
                      kVectorOp,
                      dst, // dst
                      (unsigned int) 0,
                      numBatches,
                      batchSize,
                      srcBatchStride,
                      dstBatchStride);
}

Event
runBroadcast(Context& context,
             Program& program,
             Queue& queue,
             const CLTensor<FloatType<kWidth>::T>& src,
             unsigned int srcOffset,
             unsigned int srcBatchStride,
             CLTensor<FloatType<kWidth>::T>& dst,
             unsigned int dstOffset,
             unsigned int dstBatchStride,
             unsigned int numBroadcast,
             unsigned int numBatches) {
  auto ker = program.getKernel("mem_8");

  return ker.callTask(queue,
                      src, // dummy
                      srcOffset,
                      (FloatType<kWidth>::T) 0,
                      kDeviceScalarOp,
                      dst, // dst
                      dstOffset,
                      numBatches,
                      numBroadcast,
                      srcBatchStride,
                      dstBatchStride);
}

Event
runGather(Context& context,
          Program& program,
          Queue& queue,
          const CLTensor<FloatType<kWidth>::T>& src,
          const CLTensor<unsigned int>& index,
          FloatType<kWidth>::T invalid,
          CLTensor<FloatType<kWidth>::T>& dst) {
  auto ker = program.getKernel("gather_8");

  // dst is 1d
  // src is 1d or 2d
  // index is 1d
  CL_ASSERT(dst.dims() == 1);
  CL_ASSERT(index.dims() == 1);
  CL_ASSERT(src.dims() != 0 && src.dims() <= 2);
  CL_ASSERT(index.isSameSize(dst));

  if (src.dims() == 1) {
    return ker.callTask(queue,
                        src,
                        (unsigned int) index.getSize(0),
                        (unsigned int) src.getSize(0), // batch size
                        (unsigned int) 0, // batch stride
                        index,
                        // FIXME: why does the linker complain about this but
                        // not kZero?
                        FloatType<kWidth>::T(FloatType<kWidth>::kInf),
                        dst);
  } else {
    return ker.callTask(queue,
                        src,
                        (unsigned int) index.getSize(0),
                        (unsigned int) src.getSize(1), // batch size
                        (unsigned int) src.getStride(0), // batch stride
                        index,
                        // FIXME: why does the linker complain about this but
                        // not kZero?
                        FloatType<kWidth>::T(FloatType<kWidth>::kInf),
                        dst);
  }
}

Event
runScatter(Context& context,
           Program& program,
           Queue& queue,
           const CLTensor<FloatType<kWidth>::T>& src,
           const CLTensor<unsigned int>& index,
           FloatType<kWidth>::T invalid,
           CLTensor<FloatType<kWidth>::T>& dst) {
  auto ker = program.getKernel("scatter_8");

  // dst is 1d or 2d
  // src is 1d
  // index is 1d
  CL_ASSERT(dst.dims() != 0 && src.dims() <= 2);
  CL_ASSERT(src.dims() == 1);
  CL_ASSERT(index.dims() == 1);
  CL_ASSERT(index.isSameSize(src));

  if (dst.dims() == 1) {
    CL_ASSERT(src.getSize(0) == 1);

    return ker.callTask(queue,
                        src,
                        index,
                        (unsigned int) 1,
                        (unsigned int) dst.getSize(0), // batch size
                        0, // batch stride
                        dst);
  } else {
    CL_ASSERT(dst.getSize(0) == src.getSize(0));

    return ker.callTask(queue,
                        src,
                        index,
                        (unsigned int) dst.getSize(0),
                        (unsigned int) dst.getSize(1), // batch size
                        (unsigned int) dst.getStride(0), // batch stride
                        dst);
  }
}

// out = in^t
Event
runTranspose(Context& context,
             Program& program,
             Queue& queue,
             const CLTensor<FloatType<kWidth>::T>& in,
             CLTensor<FloatType<kWidth>::T>& out) {
  auto kerTr = program.getKernel("transpose2d_8");

  CL_ASSERT(in.dims() == 2);
  CL_ASSERT(out.dims() == 2);
  CL_ASSERT(in.getSize(0) == out.getSize(1));
  CL_ASSERT(in.getSize(1) == out.getSize(0));
  CL_ASSERT(in.isContiguous());
  CL_ASSERT(out.isContiguous());
  CL_ASSERT(!in.isSameInstance(out));

  // FIXME: for transpose, we must be innermost contiguous, but we can be outer
  // non-contiguous
  constexpr size_t kTileSize = 32;
  auto gy = roundUp(in.getSize(0), kTileSize);
  auto gx = roundUp(in.getSize(1), kTileSize);

  return kerTr.call(queue,
                    Array3(gx, gy),
                    Array3(kTileSize, kTileSize),
                    in, out,
                    (unsigned int) in.getSize(0),
                    (unsigned int) in.getSize(1), 0);
}

} } // namespace
