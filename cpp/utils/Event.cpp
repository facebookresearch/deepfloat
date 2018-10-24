// Copyright (c) Facebook, Inc. and its affiliates. All Rights Reserved.
// All rights reserved.
//
// This source code is licensed under the license found in the
// LICENSE file in the root directory of this source tree.
#include "utils/Event.h"
#include "utils/Context.h"
#include "utils/OpenCLUtils.h"

namespace facebook { namespace cl {

Event::Event(Event&& e)
    : e_(std::move(e.e_)) {
  e.e_ = 0;
}

Event&
Event::operator=(Event&& e) {
  release();
  e_ = std::move(e.e_);
  e.e_ = 0;

  return *this;
}

Event
Event::empty(facebook::cl::Context& context) {
  cl_int err = 0;
  cl_event e = clCreateUserEvent(context, &err);
  CHECK_CL(err);

  Event event(e);
  CHECK_CL(clSetUserEventStatus(e, CL_COMPLETE));

  return event;
}

void
Event::release() {
  if (e_) {
    CHECK_CL(clReleaseEvent(e_));
    e_ = 0;
  }
}

void
Event::wait() {
  CHECK_CL(clWaitForEvents(1, &e_));
}

std::chrono::nanoseconds
Event::getDuration() {
  cl_ulong start = 0;
  cl_ulong end = 0;

  wait();

  CHECK_CL(clGetEventProfilingInfo(e_,
                                   CL_PROFILING_COMMAND_START,
                                   sizeof(cl_ulong),
                                   &start,
                                   nullptr));

  CHECK_CL(clGetEventProfilingInfo(e_,
                                   CL_PROFILING_COMMAND_END,
                                   sizeof(cl_ulong),
                                   &end,
                                   nullptr));

  return std::chrono::nanoseconds(end - start);
}

float
Event::getDurationInMs() {
  auto ns = getDuration();
  return (float) ns.count() / 1e6f;
}

} } // namespace
