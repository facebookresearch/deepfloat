// Copyright (c) Facebook, Inc. and its affiliates. All Rights Reserved.
// All rights reserved.
//
// This source code is licensed under the license found in the
// LICENSE file in the root directory of this source tree.


#include "PositConvertRTL.h"
#include "PositMathRTL.h"
#include "PositQuireMathRTL.h"

#define kTileSize 32

// Performs a batched matrix multiplication:
// c[i] := a[i] b[i] + beta * c[i]
// (m x k) x (k x n) = (m x n), row major
__kernel
__attribute((max_global_work_dim(0)))
void positBatchMM8_1(__global FloatType* restrict c,
                     __global FloatType* restrict a,
                     __global FloatType* restrict b,
                     DeviceBool beta,
                     char betaScale,
                     char prodScale,
                     char outScale,
                     DeviceBool roundStochastic,
                     unsigned int batchSize,
                     unsigned int m,
                     unsigned int n,
                     unsigned int k,
                     // typically m * k
                     unsigned int aBatchStride,
                     // typically k * n
                     unsigned int bBatchStride,
                     // typically m * n
                     unsigned int cBatchStride) {

  // Round the matrix size up to handle full tiles
  unsigned int mTiles = ((m + kTileSize - 1) / kTileSize);
  unsigned int nTiles = ((n + kTileSize - 1) / kTileSize);
  unsigned int kTiles = ((k + kTileSize - 1) / kTileSize);

#pragma loop_coalesce 3
  for (unsigned int batch = 0; batch < batchSize; ++batch) {
    for (unsigned int blockM = 0; blockM < mTiles; ++blockM) {
      for (unsigned int blockN = 0; blockN < nTiles; ++blockN) {

        FloatType __attribute__((memory)) aTile[kTileSize][kTileSize];
        FloatType __attribute__((memory)) bTile[kTileSize][kTileSize];
        Accumulator acc[kTileSize][kTileSize];

#pragma unroll 1
        for (unsigned int tileM = 0; tileM < kTileSize; ++tileM) {
#pragma unroll
          for (unsigned int tileN = 0; tileN < kTileSize; ++tileN) {
            unsigned int mIndex = (blockM * kTileSize) + tileM;
            unsigned int nIndex = (blockN * kTileSize) + tileN;
            unsigned int cIndex = mIndex * n + nIndex;

            FloatType oldC = ((mIndex < m) &&
                           (nIndex < n) &&
                           (beta != kZeroValue)) ?
              c[cIndex] : kZeroValue;

            acc[tileM][tileN] = positToQuire8_1RTL(oldC, betaScale);
          } // tileN
        } // tileM

        // Handle all accumulation for this tile
        for (unsigned int blockK = 0; blockK < kTiles; ++blockK) {

          //
          // Load tile
          //
#pragma unroll 1
          for (unsigned int tileM = 0; tileM < kTileSize; ++tileM) {
#pragma unroll
            for (unsigned int tileN = 0; tileN < kTileSize; ++tileN) {

              unsigned int tm = (blockM * kTileSize) + tileM;
              unsigned int tn = (blockN * kTileSize) + tileN;
              unsigned int tkA = (blockK * kTileSize) + tileN;
              unsigned int tkB = (blockK * kTileSize) + tileM;

              aTile[tileM][tileN] = tm < m && tkA < k ? a[tm * k + tkA] : 0;
              bTile[tileN][tileM] = tn < n && tkB < k ? b[tkB * n + tn] : 0;
            }
          }

          for (unsigned int tileM = 0; tileM < kTileSize; ++tileM) {
#pragma unroll 8
            for (unsigned int tileN = 0; tileN < kTileSize; ++tileN) {
                FloatType av0 = aTile[tileM][0];
                FloatType bv0 = bTile[tileN][0];
                Product prod0 =
                  positQuireMultiply8_1RTL(av0, bv0, prodScale);
                Accumulator a0 = quirePositAdd8_1RTL(prod0, acc[tileM][tileN]);

#define LOAD_PROD(N)                                                    \
                FloatType av ## N = aTile[tileM][N];                    \
                FloatType bv ## N = bTile[tileN][N];                    \
                Product prod ## N =                                     \
                  positQuireMultiply8_1RTL(av ## N, bv ## N, prodScale); \
                Accumulator a ## N = productToQuire8_1RTL(prod ## N)

                LOAD_PROD(1);
                LOAD_PROD(2);
                LOAD_PROD(3);
                LOAD_PROD(4);
                LOAD_PROD(5);
                LOAD_PROD(6);
                LOAD_PROD(7);
                LOAD_PROD(8);
                LOAD_PROD(9);
                LOAD_PROD(10);
                LOAD_PROD(11);
                LOAD_PROD(12);
                LOAD_PROD(13);
                LOAD_PROD(14);
                LOAD_PROD(15);
                LOAD_PROD(16);
                LOAD_PROD(17);
                LOAD_PROD(18);
                LOAD_PROD(19);
                LOAD_PROD(20);
                LOAD_PROD(21);
                LOAD_PROD(22);
                LOAD_PROD(23);
                LOAD_PROD(24);
                LOAD_PROD(25);
                LOAD_PROD(26);
                LOAD_PROD(27);
                LOAD_PROD(28);
                LOAD_PROD(29);
                LOAD_PROD(30);
                LOAD_PROD(31);

                Accumulator b0 = quireAdd8_1RTL(a0, a1);
                Accumulator b1 = quireAdd8_1RTL(a2, a3);
                Accumulator b2 = quireAdd8_1RTL(a4, a5);
                Accumulator b3 = quireAdd8_1RTL(a6, a7);
                Accumulator b4 = quireAdd8_1RTL(a8, a9);
                Accumulator b5 = quireAdd8_1RTL(a10, a11);
                Accumulator b6 = quireAdd8_1RTL(a12, a13);
                Accumulator b7 = quireAdd8_1RTL(a14, a15);
                Accumulator b8 = quireAdd8_1RTL(a16, a17);
                Accumulator b9 = quireAdd8_1RTL(a18, a19);
                Accumulator b10 = quireAdd8_1RTL(a20, a21);
                Accumulator b11 = quireAdd8_1RTL(a22, a23);
                Accumulator b12 = quireAdd8_1RTL(a24, a25);
                Accumulator b13 = quireAdd8_1RTL(a26, a27);
                Accumulator b14 = quireAdd8_1RTL(a28, a29);
                Accumulator b15 = quireAdd8_1RTL(a30, a31);

                Accumulator c0 = quireAdd8_1RTL(b0, b1);
                Accumulator c1 = quireAdd8_1RTL(b2, b3);
                Accumulator c2 = quireAdd8_1RTL(b4, b5);
                Accumulator c3 = quireAdd8_1RTL(b6, b7);
                Accumulator c4 = quireAdd8_1RTL(b8, b9);
                Accumulator c5 = quireAdd8_1RTL(b10, b11);
                Accumulator c6 = quireAdd8_1RTL(b12, b13);
                Accumulator c7 = quireAdd8_1RTL(b14, b15);

                Accumulator d0 = quireAdd8_1RTL(c0, c1);
                Accumulator d1 = quireAdd8_1RTL(c2, c3);
                Accumulator d2 = quireAdd8_1RTL(c4, c5);
                Accumulator d3 = quireAdd8_1RTL(c6, c7);

                Accumulator e0 = quireAdd8_1RTL(d0, d1);
                Accumulator e1 = quireAdd8_1RTL(d2, d3);

                acc[tileM][tileN] = quireAdd8_1RTL(e0, e1);
            }
          }
        } // blockK

        //
        // Write out tile results
        //
#pragma unroll 1
        for (unsigned int tileM = 0; tileM < kTileSize; ++tileM) {
#pragma unroll
          for (unsigned int tileN = 0; tileN < kTileSize; ++tileN) {
            unsigned int mIndex = (blockM * kTileSize) + tileM;
            unsigned int nIndex = (blockN * kTileSize) + tileN;
            unsigned int cIndex = mIndex * n + nIndex;

            FloatType out = quireToPosit8_1RTL(acc[tileM][tileN],
                                               outScale,
                                               roundStochastic);

            if (mIndex < m && nIndex < n) {
              c[cIndex] = out;
            }
          } // tileN
        } // tileM
      } // blockN
    } // blockM

    // Increment pointers for next batch
    a += aBatchStride;
    b += bBatchStride;
    c += cBatchStride;
  } // batch
}

#undef kTileSize
