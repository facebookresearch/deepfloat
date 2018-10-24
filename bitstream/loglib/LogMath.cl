// Copyright (c) Facebook, Inc. and its affiliates. All Rights Reserved.
// All rights reserved.
//
// This source code is licensed under the license found in the
// LICENSE file in the root directory of this source tree.

#include "LogMathRTL.h"
#include "LogMathCompareRTL.h"
#include "LogLinearMathRTL.h"

#define kTileSize 4

// Some of A, B and out may in fact be the same, but there are no write
// dependencies between them, so we mark them all as __restrict
__kernel
__attribute((max_global_work_dim(0)))
void positBinaryMath8_1(global volatile FloatType* restrict positA,
                        unsigned int aBatchStride,
                        FloatType positAHost,
                        OpType opA,
                        global volatile FloatType* restrict positB,
                        unsigned int bBatchStride,
                        FloatType positBHost,
                        OpType opB,
                        unsigned int numBatch,
                        unsigned int batchSize,
                        OpType mathOp,
                        DeviceBool roundStochastic,
                        global FloatType* restrict positOut,
                        unsigned int outBatchStride) {
  unsigned int batchTiles = ((batchSize + kTileSize - 1) / kTileSize);

  for (unsigned int b = 0; b < numBatch; ++b) {
    for (unsigned int t = 0; t < batchTiles; ++t) {
#pragma unroll
      for (unsigned int j = 0; j < kTileSize; ++j) {
        unsigned int i = t * kTileSize + j;

        bool inBounds = (i < batchSize);

        FloatType pa;
        if (opA == kHostScalarOp || !inBounds) {
          pa = positAHost;
        } else {
          pa = positA[(opA == kDeviceScalarOp) ? 0 : i];
        }

        FloatType pb;
        if (opB == kHostScalarOp || i >= batchSize) {
          pb = positBHost;
        } else {
          pb = positB[(opB == kDeviceScalarOp) ? 0 : i];
        }

        FloatType pout;
        switch (mathOp) {
          case kAdd:
          case kSub:
            pout = logAdd_RTL(pa, pb, (mathOp == kSub));
            break;
          case kMul:
            pout = logMul_RTL(pa, pb);
            break;
          case kDiv:
            pout = (FloatType) 0; // positDiv8_1RTL(pa, pb);
            break;
          case kMin:
            pout = logComp_RTL(pa, pb, kComp_LE) ? pa : pb;
            break;
          case kMax:
          default:
            pout = logComp_RTL(pa, pb, kComp_GE) ? pa : pb;
            break;
        }

        if (inBounds) {
          positOut[i] = pout;
        }
      }
    } // tiles

    positA += aBatchStride;
    positB += bBatchStride;
    positOut += outBatchStride;
  } // batch
}

#undef kTileSize

__kernel
__attribute((max_global_work_dim(0)))
void positReduce8_1(global FloatType* restrict positA,
                    unsigned int n,
                    OpType mathOp,
                    DeviceBool roundStochastic,
                    global FloatType* restrict positOut) {
  Accumulator sumReduce;
  ACC_ZERO(sumReduce);

  FloatType minMaxReduce = (mathOp == kMin) ?
    // largest non-inf
    kMaxValue :
    // smallest non-inf
    NEG_FLOAT(kMaxValue);

  for (unsigned int i = 0; i < n; ++i) {
    FloatType pa = positA[i];

    Accumulator qa = logToLinear_RTL(pa);
    sumReduce = linearAdd_RTL(qa, sumReduce);

    if (mathOp == kMin) {
      minMaxReduce = logComp_RTL(minMaxReduce, pa, kComp_LE) ?
        minMaxReduce : pa;
    } else {
      minMaxReduce = logComp_RTL(minMaxReduce, pa, kComp_GE) ?
        minMaxReduce : pa;
    }
  }

  *positOut = (mathOp == kAdd) ? linearToLog_RTL(sumReduce, 0) : minMaxReduce;
}

// Exact multiply-add:
// out_i = c(_i) (+|-) a(_i) * b_i
// Some of A, B, C and out may in fact be the same, but there are no write
// dependencies between them, so we mark them all as __restrict
#define kTileSize 4

__kernel
__attribute((max_global_work_dim(0)))
void positMulAdd8_1(global FloatType* restrict positC,
                    FloatType positCHost,
                    OpType opC,
                    char scaleC,

                    global FloatType* restrict positA,
                    FloatType positAHost,
                    OpType opA,

                    global FloatType* restrict positB,
                    char scaleAB,

                    DeviceBool subtract,
                    DeviceBool roundStochastic,
                    char scaleOut,

                    unsigned int n,
                    global FloatType* restrict positOut) {
  unsigned int tiles = ((n + kTileSize - 1) / kTileSize);

  for (unsigned int t = 0; t < tiles; ++t) {
#pragma unroll
    for (unsigned int j = 0; j < kTileSize; ++j) {
      unsigned int i = t * kTileSize + j;

      FloatType pc;
      if (opC == kHostScalarOp) {
        pc = positCHost;
      } else {
        pc = positC[(opC == kDeviceScalarOp) ? 0 : i];
      }

      FloatType pa;
      if (opA == kHostScalarOp) {
        pa = positAHost;
      } else {
        pa = positA[(opA == kDeviceScalarOp) ? 0 : i];
      }

      // acc = c
      Accumulator acc = logToLinear_RTL(pc);

      // acc = c (+|-) a * b
      pa = subtract ?
        ((pa == kZeroValue || pa == kInfValue) ? pa : NEG_FLOAT(pa)) :
        pa;

      Accumulator mul = logMultiplyToLinear_RTL(pa, positB[i]);
      acc = linearAdd_RTL(mul, acc);

      positOut[i] = linearToLog_RTL(acc, scaleOut);
    }
  }
}

#undef kTileSize
