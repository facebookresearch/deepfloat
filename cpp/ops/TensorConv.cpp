// Copyright (c) Facebook, Inc. and its affiliates. All Rights Reserved.
// All rights reserved.
//
// This source code is licensed under the license found in the
// LICENSE file in the root directory of this source tree.
#include "ops/TensorConv.h"
#include "ops/TensorMath.h"
#include "ops/TensorMemory.h"
#include "utils/MathUtils.h"

namespace facebook { namespace cl {

Event
runIm2ColNCHW(Context& context,
              Program& program,
              Queue& queue,
              const CLTensor<FloatType<kWidth>::T>& in,
              unsigned int kHW,
              unsigned int padT,
              unsigned int padL,
              unsigned int strideHW,
              CLTensor<FloatType<kWidth>::T>& out) {
  auto ker = program.getKernel("im2col_8");

  CL_ASSERT(in.dims() == 4);
  CL_ASSERT(out.dims() == 3);

  // in = (batch) x (cin) x (h) x (w)
  // ker = (cout) x (cin x kh x kw)
  // out = (batch) x (cin x kh x kw) x (outputH x outputW)
  size_t outputH =
    calcKernelOutputSize(in.getSize(2), padT, padT, kHW, strideHW);
  size_t outputW =
    calcKernelOutputSize(in.getSize(3), padL, padL, kHW, strideHW);

  CL_ASSERT(out.getSize(0) == in.getSize(0));
  CL_ASSERT(out.getSize(1) == in.getSize(1) * kHW * kHW);
  CL_ASSERT(out.getSize(2) == outputH * outputW);

  return ker.callTask(queue,
                      in,
                      (unsigned int) in.getSize(0), // batch
                      (unsigned int) in.getSize(1), // channels
                      (unsigned int) in.getSize(2), // inputH
                      (unsigned int) in.getSize(3), // inputW
                      (unsigned int) outputH,
                      (unsigned int) outputW,
                      kHW,
                      strideHW,
                      padT,
                      padL,
                      out);
}

Event
runForwardPool2dNCHW(Context& context,
                     Program& program,
                     Queue& queue,
                     const CLTensor<FloatType<kWidth>::T>& in,
                     PoolOp poolType,
                     int kHW,
                     int padT,
                     int padL,
                     int strideHW,
                     RoundOp rounding,
                     char inScale,
                     char outScale,
                     CLTensor<FloatType<kWidth>::T>& out) {
  auto ker = program.getKernel("positPool2d_8_1");

  CL_ASSERT(in.dims() == 4);
  CL_ASSERT(out.dims() == 4);

  size_t outputH =
    calcKernelOutputSize(in.getSize(2), padT, padT, kHW, strideHW);
  size_t outputW =
    calcKernelOutputSize(in.getSize(3), padL, padL, kHW, strideHW);

  CL_ASSERT(out.getSize(0) == in.getSize(0));
  CL_ASSERT(out.getSize(1) == in.getSize(1));
  CL_ASSERT(out.getSize(2) == outputH);
  CL_ASSERT(out.getSize(3) == outputW);

  return ker.callTask(queue,
                      in,
                      (int) in.getSize(0), // batch
                      (int) in.getSize(1), // channels
                      (int) in.getSize(2), // inputH
                      (int) in.getSize(3), // inputW
                      (int) outputH,
                      (int) outputW,
                      kHW,
                      strideHW,
                      padT,
                      padL,
                      inScale,
                      outScale,
                      toDeviceBool(poolType == PoolOp::Avg),
                      toDeviceBool(rounding == RoundOp::Stochastic),
                      out);
}

Event
runForwardConv2dNCHW(Context& context,
                     Program& program,
                     Queue& queue,
                     const CLTensor<FloatType<kWidth>::T>& in,
                     CLTensor<FloatType<kWidth>::T>& workspace,
                     const CLTensor<FloatType<kWidth>::T>& ker,
                     const CLTensor<FloatType<kWidth>::T>* bias,
                     int padT,
                     int padL,
                     int strideHW,
                     RoundOp rounding,
                     char inScale,
                     char outScale,
                     CLTensor<FloatType<kWidth>::T>& out) {
  // Only square kernels supported at the moment
  int kernelHW = ker.getSize(2);
  CL_ASSERT(kernelHW == ker.getSize(3));

  size_t outputH =
    calcKernelOutputSize(in.getSize(2), padT, padT, kernelHW, strideHW);
  size_t outputW =
    calcKernelOutputSize(in.getSize(3), padL, padL, kernelHW, strideHW);

  CL_ASSERT(in.getSize(0) == out.getSize(0));
  CL_ASSERT(ker.getSize(0) == out.getSize(1));
  CL_ASSERT(in.getSize(1) == ker.getSize(1));
  CL_ASSERT(out.getSize(2) == outputH);
  CL_ASSERT(out.getSize(3) == outputW);

  size_t workspace1 = in.getSize(1) * kernelHW * kernelHW;
  size_t workspace2 = outputH * outputW;

  if (workspace.dims() != 3 ||
      workspace.getSize(0) != in.getSize(0) ||
      workspace.getSize(1) != workspace1 ||
      workspace.getSize(2) != workspace2) {
    workspace = CLTensor<FloatType<kWidth>::T>(context,
                                 {in.getSize(0),
                                     in.getSize(1) * kernelHW * kernelHW,
                                     outputH * outputW});
  }

  runIm2ColNCHW(context, program, queue,
                in,
                kernelHW,
                padT,
                padL,
                strideHW,
                workspace);

  // in = (batch) x (cin) x (h) x (w)
  // ker = (cout) x (cin x kh x kw)
  // out = (batch) x (cin x kh x kw) x (outputH x outputW)

  if (bias) {
    for (int b = 0; b < out.getSize(0); ++b) {
      CL_ASSERT(bias->getSize(0) == out.getSize(1));

      runBroadcast(context, program, queue,
                   // src
                   *bias,
                   // src offset
                   0,
                   // src batch stride
                   1,
                   // dst
                   out,
                   // dst offset
                   b * out.getSize(1) * out.getSize(2) * out.getSize(3),
                   // dst batch stride,
                   out.getSize(2) * out.getSize(3),
                   // num broadcast
                   out.getSize(2) * out.getSize(3),
                   // num batches
                   out.getSize(1));
    }
  }

  auto outView = out.view({out.getSize(0),
        out.getSize(1),
        out.getSize(2) * out.getSize(3)});

  return runMM(context, program, queue,
               // a matrix (kernels) is not batched
               ker.view({ker.getSize(0),
                     ker.getSize(1) * kernelHW * kernelHW}),
               // b matrix is batched
               workspace,
               (bool) bias,
               rounding,
               inScale,
               outScale,
               // c matrix is batched
               outView);
}

} } // namespace
