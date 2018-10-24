// Copyright (c) Facebook, Inc. and its affiliates. All Rights Reserved.
// All rights reserved.
//
// This source code is licensed under the license found in the
// LICENSE file in the root directory of this source tree.
#pragma once

#include "CL/opencl.h"
#include <chrono>

namespace facebook { namespace cl {

class Context;

class Event {
 public:
  inline Event() :
      e_(0) {
  }

  inline Event(cl_event e)
      : e_(e) {
  }

  Event(Event&& e);

  inline ~Event() {
    release();
  }

  /// Create an already completed event
  static Event empty(facebook::cl::Context& context);

  Event& operator=(Event&& e);

  inline operator cl_event() {
    return e_;
  }

  /// Wait on the host for the completion of this event
  void wait();

  /// Returns the duration of this event; will wait if the event is not yet
  /// complete
  std::chrono::nanoseconds getDuration();
  float getDurationInMs();

  void release();

 protected:
  cl_event e_;
};

} } // namespace
