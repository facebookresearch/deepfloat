// Copyright (c) Facebook, Inc. and its affiliates. All Rights Reserved.
// All rights reserved.
//
// This source code is licensed under the license found in the
// LICENSE file in the root directory of this source tree.

#include "PositMathRTL.h"
#include "PositMathCompareRTL.h"
#include "PositQuireMathRTL.h"

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
            pout = positAdd8_1RTL(pa, pb, (mathOp == kSub), roundStochastic);
            break;
          case kMul:
            pout = positMul8_1RTL(pa, pb, roundStochastic);
            break;
          case kDiv:
            // FIXME: implement roundStochastic
            pout = positDiv8_1RTL(pa, pb);
            break;
          case kMin:
            pout = positMin8_1RTL(pa, pb);
            break;
          case kMax:
          default:
            pout = positMax8_1RTL(pa, pb);
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
    // largest non-inf posit
    kMaxValue :
    // smallest non-inf posit
    NEG_FLOAT(kMaxValue);

  Product pp;

  for (unsigned int i = 0; i < n; ++i) {
    FloatType pa = positA[i];

    // FIXME: compiler crashes if this is inside a branch below
    Accumulator qa = positToQuire8_1RTL(pa, (char) 0);
    sumReduce = quireAdd8_1RTL(qa, sumReduce);

    if (mathOp == kMin) {
      minMaxReduce = positMin8_1RTL(pa, minMaxReduce);
    } else {
      minMaxReduce = positMax8_1RTL(pa, minMaxReduce);
    }
  }

  *positOut = (mathOp == kAdd) ?
    quireToPosit8_1RTL(sumReduce, (char) 0, roundStochastic) :
    minMaxReduce;
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
      Accumulator acc = positToQuire8_1RTL(pc, scaleC);

      // acc = c (+|-) a * b
      pa = subtract ?
        ((pa == kZeroValue || pa == kInfValue) ? pa : NEG_FLOAT(pa)) :
        pa;

      Product prod = positQuireMultiply8_1RTL(pa, positB[i], scaleAB);
      acc = quirePositAdd8_1RTL(prod, acc);

      positOut[i] = quireToPosit8_1RTL(acc, scaleOut, roundStochastic);
    }
  }
}

#undef kTileSize
