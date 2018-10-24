// Copyright (c) Facebook, Inc. and its affiliates. All Rights Reserved.
// All rights reserved.
//
// This source code is licensed under the license found in the
// LICENSE file in the root directory of this source tree.


// Handles:
//
// memcpy (srcOp == kVectorOp)
// memset (srcOp == kHostScalarOp)
// broadcast (srcOp == kDeviceScalarOp)
#define kTileSize 8

__kernel
__attribute((max_global_work_dim(0)))
void mem_8(__global volatile FloatType* restrict src,
           unsigned int srcOffset,
           FloatType srcHost,
           OpType srcOp,
           __global FloatType* restrict dst,
           unsigned int dstOffset,
           unsigned int numBatches,
           unsigned int batchSize,
           unsigned int srcBatchStride,
           unsigned int dstBatchStride) {
  src += srcOffset;
  dst += dstOffset;

  unsigned int batchTiles = (batchSize + kTileSize - 1) / kTileSize;

  for (unsigned int batch = 0; batch < numBatches; ++batch) {
    for (unsigned int tile = 0; tile < batchTiles; ++tile) {
      FloatType v = src[batch * srcBatchStride];

#pragma unroll
      for (unsigned int j = 0; j < kTileSize; ++j) {
        unsigned int i = (tile * kTileSize + j);
        bool inBounds = i < batchSize;

        if (inBounds) {
          if (srcOp == kHostScalarOp) {
            v = srcHost;
          } else if (srcOp == kVectorOp) {
            v = src[batch * srcBatchStride + i];
          }

          dst[batch * dstBatchStride + i] = v;
        }
      }
    }
  }
}

#undef kTileSize

// Performs a (possibly batched) gather
// if srcBatchStride == 0: gather multiple elements from a 1-d array
// dst[i] = src[index[i]] if index[i] < srcSize, otherwise dst[i] = invalid
// if srcBatchStride > 0: gather a single element from multiple 1-d arrays
// strided by srcBatchStride
// dst[i] = src[i][index[i]] if index[i] < srcSize, otherwise dst[i] = invalid
__kernel
__attribute((max_global_work_dim(0)))
void gather_8(__global FloatType* restrict src,
              unsigned int n,
              unsigned int srcBatchSize,
              unsigned int srcBatchStride,
              __global unsigned int* restrict index,
              FloatType invalid,
              __global FloatType* restrict dst) {
  for (unsigned int i = 0; i < n; ++i) {
    unsigned int idx = index[i];
    dst[i] = (idx < srcBatchSize) ? src[i * srcBatchStride + idx] : invalid;
  }
}

// dst[i][index[i]] = src[i]
__kernel
__attribute((max_global_work_dim(0)))
void scatter_8(__global FloatType* restrict src,
               __global unsigned int* restrict index,
               unsigned int n,
               unsigned int dstBatchSize,
               unsigned int dstBatchStride,
               __global FloatType* restrict dst) {
  for (unsigned int i = 0; i < n; ++i) {
    unsigned int idx = index[i];
    if (idx < dstBatchSize) {
      dst[i * dstBatchStride + idx] = src[i];
    }
  }
}

#define kTileSize 32

// Take a 2d region of memory (m x n)
// Slice along rows to start at col nOffset (m x (n - nOffset))
// Transpose to ((n - nOffset) x m)
//
// The global size is (n - nOffset, m, 1)
// The local size is (kTileSize, kTileSize, 1)
//
// 8 bit data types
__kernel
__attribute((reqd_work_group_size(kTileSize, kTileSize, 1)))
void transpose2d_8(__global FloatType* restrict inMatrix,
                   __global FloatType* restrict outMatrix,
                   unsigned int m,
                   unsigned int n,
                   unsigned int nOffset) {
  __local FloatType tile[kTileSize][kTileSize];

  unsigned int gx = get_global_id(0);
  unsigned int gy = get_global_id(1);

  unsigned int bx = get_group_id(0);
  unsigned int by = get_group_id(1);

  unsigned int tx = get_local_id(0);
  unsigned int ty = get_local_id(1);

  unsigned int readRow = gy;
  unsigned int readCol = gx + nOffset;

  // Is the read point valid?
  if (readRow < m && readCol < n) {
    tile[ty][tx] = inMatrix[readRow * n + readCol];
  }

  barrier(CLK_LOCAL_MEM_FENCE);

  unsigned int writeRow = bx * kTileSize + ty;
  unsigned int writeCol = by * kTileSize + tx;

  // Is the write point valid?
  if (writeCol < m && writeRow + nOffset < n) {
    outMatrix[writeRow * m + writeCol] = tile[tx][ty];
  }
}

#undef kTileSize
