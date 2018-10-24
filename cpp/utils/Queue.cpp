// Copyright (c) Facebook, Inc. and its affiliates. All Rights Reserved.
// All rights reserved.
//
// This source code is licensed under the license found in the
// LICENSE file in the root directory of this source tree.
#include "utils/Queue.h"
#include "utils/OpenCLUtils.h"

namespace facebook { namespace cl {

Queue::Queue(Queue&& e)
    : queue_(std::move(e.queue_)) {
  e.queue_ = 0;
}

Queue&
Queue::operator=(Queue&& e) {
  release();
  queue_ = std::move(e.queue_);

  e.queue_ = 0;
  return *this;
}

void
Queue::release() {
  if (queue_) {
    CHECK_CL(clReleaseCommandQueue(queue_));
    queue_ = 0;
  }
}

void
Queue::blockingWait() {
  if (queue_) {
    CHECK_CL(clFinish(queue_));
  }
}

} } // namespace
