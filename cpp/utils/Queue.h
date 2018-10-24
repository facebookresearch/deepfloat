// Copyright (c) Facebook, Inc. and its affiliates. All Rights Reserved.
// All rights reserved.
//
// This source code is licensed under the license found in the
// LICENSE file in the root directory of this source tree.
#pragma once

#include "CL/opencl.h"

namespace facebook { namespace cl {

class Queue {
 public:
  inline Queue()
      : queue_(0) {
  }

  inline Queue(cl_command_queue e)
      : queue_(e) {
  }

  Queue(Queue&& e);

  Queue& operator=(Queue&& e);

  inline operator cl_command_queue() {
    return queue_;
  }

  void release();

  void blockingWait();

  inline ~Queue() {
    release();
  }

 protected:
  cl_command_queue queue_;
};

} } // namespace
