// Copyright (c) Facebook, Inc. and its affiliates. All Rights Reserved.
// All rights reserved.
//
// This source code is licensed under the license found in the
// LICENSE file in the root directory of this source tree.
#pragma once

#include "FloatDefs.h"
#include "utils/Event.h"
#include "utils/Tensor.h"

/// Collection of memory manipulation operators

namespace facebook { namespace cl {

class Context;
class Program;
class Queue;

// out = v
Event
runMemset(Context& context,
          Program& program,
          Queue& queue,
          FloatType<kWidth>::T v,
          CLTensor<FloatType<kWidth>::T>& inOut);

Event
runMemcpy(Context& context,
          Program& program,
          Queue& queue,
          const CLTensor<FloatType<kWidth>::T>& src,
          unsigned int batchSize,
          unsigned int numBatches,
          unsigned int srcBatchStride,
          unsigned int dstBatchStride,
          CLTensor<FloatType<kWidth>::T>& dst);

// dst[dstOffset + b * dstBatchStride + i] = src[srcOffset + b * srcBatchStride]
// for all i in numBroadcast and b in numBatches
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
             unsigned int numBatches);

// dst[i] = src[index[i]] if src is 1-d
// dst[i] = src[i][index[i]] if src is 2-d
Event
runGather(Context& context,
          Program& program,
          Queue& queue,
          const CLTensor<FloatType<kWidth>::T>& src,
          const CLTensor<unsigned int>& index,
          FloatType<kWidth>::T invalid,
          CLTensor<FloatType<kWidth>::T>& dst);

// dst[i][index[i]] = src[i] if dst is 2-d
// dst[index[0]] = src[0] if dst is 1-d
Event
runScatter(Context& context,
           Program& program,
           Queue& queue,
           const CLTensor<FloatType<kWidth>::T>& src,
           const CLTensor<unsigned int>& index,
           FloatType<kWidth>::T invalid,
           CLTensor<FloatType<kWidth>::T>& dst);

// out = in^t
Event
runTranspose(Context& context,
             Program& program,
             Queue& queue,
             const CLTensor<FloatType<kWidth>::T>& in,
             CLTensor<FloatType<kWidth>::T>& out);

// Input is [channel][height][width]
Event
runIm2Col(Context& context,
          Program& program,
          Queue& queue,
          const CLTensor<FloatType<kWidth>::T>& in,
          unsigned int kH, unsigned int kW,
          unsigned int padT, unsigned int padB,
          unsigned int padL, unsigned int padR,
          unsigned int strideH, unsigned int strideW,
          CLTensor<FloatType<kWidth>::T>& out);

} }
