// Copyright (c) Facebook, Inc. and its affiliates. All Rights Reserved.
// All rights reserved.
//
// This source code is licensed under the license found in the
// LICENSE file in the root directory of this source tree.
#pragma once

#include <string>
#include <vector>
#include "CL/opencl.h"

#define CHECK_CL_MSG(err, msg)                  \
  do {                                          \
    if ((err) != CL_SUCCESS) {                          \
      throwClError(err, __LINE__, __FILE__, msg);       \
    }                                                   \
  } while (false)

#define CHECK_CL(err) CHECK_CL_MSG(err, nullptr)

#define CL_ASSERT_MSG(status, msg)              \
  do {                                          \
    if (! (bool) (status)) {                    \
      throwError(__LINE__, __FILE__, msg);      \
    }                                           \
  } while (false)

#define CL_ASSERT(status) CL_ASSERT_MSG(status, nullptr)

void throwError(int line,
                const char* file,
                const char* msg);

void throwClError(cl_int err,
                  int line,
                  const char* file,
                  const char* msg);

std::string oclErrorToString(cl_int err);

std::vector<cl_device_id> getClDevices(const std::string& platformName,
                                       cl_device_type deviceType);
