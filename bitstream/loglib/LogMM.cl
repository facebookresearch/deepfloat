// Copyright (c) Facebook, Inc. and its affiliates. All Rights Reserved.
// All rights reserved.
//
// This source code is licensed under the license found in the
// LICENSE file in the root directory of this source tree.


#include "LogMathRTL.h"
#include "LogLinearMathRTL.h"

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
                            beta) ?
              c[cIndex] : kZeroValue;

            acc[tileM][tileN] = logToLinear_RTL(oldC);
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

              aTile[tileM][tileN] =
                tm < m && tkA < k ? a[tm * k + tkA] : kZeroValue;
              bTile[tileN][tileM] =
                tn < n && tkB < k ? b[tkB * n + tn] : kZeroValue;
            }
          }

          //
          // Multiply and accumulate
          //
/*
          for (unsigned int tileK = 0; tileK < kTileSize; ++tileK) {
//#pragma unroll
            for (unsigned int tileM = 0; tileM < kTileSize; ++tileM) {
#pragma unroll
              for (unsigned int tileN = 0; tileN < kTileSize; ++tileN) {

                Accumulator oldAcc = acc[tileM][tileN];
                FloatType av = aTile[tileM][tileK];
                FloatType bv = bTile[tileN][tileK];

                Accumulator ab = logMultiplyToLinear_RTL(av, bv);

                acc[tileM][tileN] = linearAdd_RTL(ab, oldAcc);
              } // tileN
            } // tileM
          } // tileK
*/
          for (unsigned int tileM = 0; tileM < kTileSize; ++tileM) {
#pragma unroll 8
            for (unsigned int tileN = 0; tileN < kTileSize; ++tileN) {
              Accumulator oldAcc = acc[tileM][tileN];

#define LOAD_PROD(N)                                                    \
              FloatType av ## N = aTile[tileM][N];                        \
              FloatType bv ## N = bTile[tileN][N];                        \
              Accumulator a ## N = logMultiplyToLinear_RTL(av ## N, bv ## N)

              LOAD_PROD(0);
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

              Accumulator b0 = linearAdd_RTL(a0, a1);
              Accumulator b1 = linearAdd_RTL(a2, a3);
              Accumulator b2 = linearAdd_RTL(a4, a5);
              Accumulator b3 = linearAdd_RTL(a6, a7);
              Accumulator b4 = linearAdd_RTL(a8, a9);
              Accumulator b5 = linearAdd_RTL(a10, a11);
              Accumulator b6 = linearAdd_RTL(a12, a13);
              Accumulator b7 = linearAdd_RTL(a14, a15);
              Accumulator b8 = linearAdd_RTL(a16, a17);
              Accumulator b9 = linearAdd_RTL(a18, a19);
              Accumulator b10 = linearAdd_RTL(a20, a21);
              Accumulator b11 = linearAdd_RTL(a22, a23);
              Accumulator b12 = linearAdd_RTL(a24, a25);
              Accumulator b13 = linearAdd_RTL(a26, a27);
              Accumulator b14 = linearAdd_RTL(a28, a29);
              Accumulator b15 = linearAdd_RTL(a30, a31);

              Accumulator c0 = linearAdd_RTL(b0, b1);
              Accumulator c1 = linearAdd_RTL(b2, b3);
              Accumulator c2 = linearAdd_RTL(b4, b5);
              Accumulator c3 = linearAdd_RTL(b6, b7);
              Accumulator c4 = linearAdd_RTL(b8, b9);
              Accumulator c5 = linearAdd_RTL(b10, b11);
              Accumulator c6 = linearAdd_RTL(b12, b13);
              Accumulator c7 = linearAdd_RTL(b14, b15);

              Accumulator d0 = linearAdd_RTL(c0, c1);
              Accumulator d1 = linearAdd_RTL(c2, c3);
              Accumulator d2 = linearAdd_RTL(c4, c5);
              Accumulator d3 = linearAdd_RTL(c6, c7);

              Accumulator e0 = linearAdd_RTL(d0, d1);
              Accumulator e1 = linearAdd_RTL(d2, d3);

              Accumulator f0 = linearAdd_RTL(e0, e1);

              // FIXME: load and accumulate earlier
              acc[tileM][tileN] = linearAdd_RTL(f0, oldAcc);
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

            FloatType out = linearToLog_RTL(acc[tileM][tileN], outScale);

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
