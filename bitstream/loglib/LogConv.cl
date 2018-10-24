// Copyright (c) Facebook, Inc. and its affiliates. All Rights Reserved.
// All rights reserved.
//
// This source code is licensed under the license found in the
// LICENSE file in the root directory of this source tree.

#include "LogMathCompareRTL.h"
#include "LogLinearMathRTL.h"

__kernel
__attribute((max_global_work_dim(0)))
void positPool2d_8_1(__global FloatType* restrict input,
                     int batchSize,
                     int channels,
                     int inputH,
                     int inputW,
                     int outputH,
                     int outputW,
                     int kernelHW,
                     int strideHW,
                     int padT,
                     int padL,
                     char inputScale,
                     char outputScale,
                     DeviceBool useAvg,
                     DeviceBool roundStochastic,
                     __global FloatType* restrict output) {
  unsigned char kerSize = (unsigned char) (kernelHW * kernelHW);

  for (int b = 0; b < batchSize; ++b) {
    for (int c = 0; c < channels; ++c) {
      for (int oh = 0; oh < outputH; ++oh) {
        for (int ow = 0; ow < outputW; ++ow) {

          int inputStartH = oh * strideHW - padT;
          int inputEndH = inputStartH + kernelHW;
          int inputStartW = ow * strideHW - padL;
          int inputEndW = inputStartW + kernelHW;

          inputStartH = min(max(inputStartH, 0), inputH);
          inputEndH = min(max(inputEndH, 0), inputH);

          inputStartW = min(max(inputStartW, 0), inputW);
          inputEndW = min(max(inputEndW, 0), inputW);

          FloatType max = kLowestValue;

          Accumulator acc;
          ACC_ZERO(acc);

          // FIXME: this will be completely serial!!! We need known bounds
          for (int ih = inputStartH; ih < inputEndH; ++ih) {
            for (int iw = inputStartW; iw < inputEndW; ++iw) {
              FloatType v = input[((c * inputH) + ih) * inputW + iw];

              Accumulator accV = logToLinear_RTL(v);
              acc = linearAdd_RTL(accV, acc);

              max = logComp_RTL(v, max, kComp_GT) ? v : max;
            } // iw
          } // ih

          acc = linearDivide_RTL(acc, kerSize);
          FloatType avg = linearToLog_RTL(acc, outputScale);

          // If we are entirely within the padding region, the output must be
          // zero. The lowest posit is used as a sentinel value, but we don't
          // want to write this out.
          max = (inputStartH == inputEndH || inputStartW == inputEndW) ?
            kZeroValue : max;

          output[((c * outputH) + oh) * outputW + ow] = useAvg ? avg : max;
        } // ow
      } // oh
    } // c

    // Increment for next batch
    input += channels * inputH * inputW;
    output += channels * outputH * outputW;
  } // batch
}

__kernel
__attribute((max_global_work_dim(0)))
void im2col_8(__global unsigned char* restrict input,
              int batchSize,
              int channels,
              int inputH,
              int inputW,
              int outputH,
              int outputW,
              int kernelHW,
              int strideHW,
              int padT,
              int padL,
              __global unsigned char* restrict output) {
  // input is (batch, inputChannels, inputH, inputW)
  // output is (batch) x ((inputChannels x kH x kW) x (outputH x outputW))
  for (int b = 0; b < batchSize; ++b) {
#pragma loop_coalesce 4
    for (int c = 0; c < channels; ++c) {
      for (int kHOffset = 0; kHOffset < kernelHW; ++kHOffset) {
        for (int kWOffset = 0; kWOffset < kernelHW; ++kWOffset) {
          for (int oh = 0; oh < outputH; ++oh) {
#pragma unroll 4
            for (int ow = 0; ow < outputW; ++ow) {
              // Translate to input point
              int ih = oh * strideHW + kHOffset - padT;
              int iw = ow * strideHW + kWOffset - padL;

              bool inBounds = (ih >= 0) && (ih < inputH) &&
                (iw >= 0) && (iw < inputW);

              output[(((c * kernelHW + kHOffset) *
                       kernelHW + kWOffset) * outputH + oh) * outputW + ow] =
                inBounds ?
                input[(c * inputH + ih) * inputW + iw] : 0;
            } // ow
          } // oh
        } // kWOffset
      } // kHOffset
    } // c

    // Increment for next batch
    input += channels * inputH * inputW;
    output += channels * kernelHW * kernelHW * outputH * outputW;
  } // b
}
