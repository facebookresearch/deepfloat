// Copyright (c) Facebook, Inc. and its affiliates. All Rights Reserved.
// All rights reserved.
//
// This source code is licensed under the license found in the
// LICENSE file in the root directory of this source tree.

#include "LogMathCompareRTL.h"

// Scalar:
// out[i] = positA[i] > positB ? positSel[i] : 0
// Vector:
// out[i] = positA[i] > positB[i] ? positSel[i] : 0
// Some of A, B, sel and out may in fact be the same, but there are no write
// dependencies between them, so we mark them all as __restrict
__kernel
__attribute((max_global_work_dim(0)))
void positThreshold8_1(global FloatType* restrict positA,
                       global FloatType* restrict positB,
                       unsigned int n,
                       FloatType positBHost,
                       global FloatType* restrict positSel,
                       OpType opType,
                       OpType compType,
                       global FloatType* restrict positOut) {
  for (unsigned int i = 0; i < n; ++i) {
    FloatType pa = positA[i];

    FloatType pb;
    if (opType == kHostScalarOp) {
      pb = positBHost;
    } else {
      pb = positB[(opType == kDeviceScalarOp) ? 0 : i];
    }

    positOut[i] = logComp_RTL(pa, pb, compType) ? positSel[i] : kZeroValue;
  }
}
