// Copyright (c) Facebook, Inc. and its affiliates. All Rights Reserved.
// All rights reserved.
//
// This source code is licensed under the license found in the
// LICENSE file in the root directory of this source tree.
#include "utils/OpenCLUtils.h"
#include <stdexcept>
#include <sstream>
#include <iostream>

void throwError(int line,
                const char* file,
                const char* msg) {
  std::stringstream ss;
  ss << "Assert failed at " << file << " line " << line;

  if (msg) {
    ss << ": " << msg;
  }

  throw std::runtime_error(ss.str());
}

void throwClError(cl_int err,
                  int line,
                  const char* file,
                  const char* msg) {
  std::stringstream ss;
  ss << "OpenCL error " << oclErrorToString(err)
     << " at " << file << " line " << line;

  if (msg) {
    ss << ": " << msg;
  }

  throw std::runtime_error(ss.str());
}

std::string oclErrorToString(cl_int err) {
  switch(err) {
    case -1:
      return "CL_DEVICE_NOT_FOUND";
      break;
    case -2:
      return "CL_DEVICE_NOT_AVAILABLE";
      break;
    case -3:
      return "CL_COMPILER_NOT_AVAILABLE";
      break;
    case -4:
      return "CL_MEM_OBJECT_ALLOCATION_FAILURE";
      break;
    case -5:
      return "CL_OUT_OF_RESOURCES";
      break;
    case -6:
      return "CL_OUT_OF_HOST_MEMORY";
      break;
    case -7:
      return "CL_PROFILING_INFO_NOT_AVAILABLE";
      break;
    case -8:
      return "CL_MEM_COPY_OVERLAP";
      break;
    case -9:
      return "CL_IMAGE_FORMAT_MISMATCH";
      break;
    case -10:
      return "CL_IMAGE_FORMAT_NOT_SUPPORTED";
      break;
    case -11:
      return "CL_BUILD_PROGRAM_FAILURE";
      break;
    case -12:
      return "CL_MAP_FAILURE";
      break;
    case -13:
      return "CL_MISALIGNED_SUB_BUFFER_OFFSET";
      break;
    case -14:
      return "CL_EXEC_STATUS_ERROR_FOR_EVENTS_IN_WAIT_LIST";
      break;
    case -30:
      return "CL_INVALID_VALUE";
      break;
    case -31:
      return "CL_INVALID_DEVICE_TYPE";
      break;
    case -32:
      return "CL_INVALID_PLATFORM";
      break;
    case -33:
      return "CL_INVALID_DEVICE";
      break;
    case -34:
      return "CL_INVALID_CONTEXT";
      break;
    case -35:
      return "CL_INVALID_QUEUE_PROPERTIES";
      break;
    case -36:
      return "CL_INVALID_COMMAND_QUEUE";
      break;
    case -37:
      return "CL_INVALID_HOST_PTR";
      break;
    case -38:
      return "CL_INVALID_MEM_OBJECT";
      break;
    case -39:
      return "CL_INVALID_IMAGE_FORMAT_DESCRIPTOR";
      break;
    case -40:
      return "CL_INVALID_IMAGE_SIZE";
      break;
    case -41:
      return "CL_INVALID_SAMPLER";
      break;
    case -42:
      return "CL_INVALID_BINARY";
      break;
    case -43:
      return "CL_INVALID_BUILD_OPTIONS";
      break;
    case -44:
      return "CL_INVALID_PROGRAM";
      break;
    case -45:
      return "CL_INVALID_PROGRAM_EXECUTABLE";
      break;
    case -46:
      return "CL_INVALID_KERNEL_NAME";
      break;
    case -47:
      return "CL_INVALID_KERNEL_DEFINITION";
      break;
    case -48:
      return "CL_INVALID_KERNEL";
      break;
    case -49:
      return "CL_INVALID_ARG_INDEX";
      break;
    case -50:
      return "CL_INVALID_ARG_VALUE";
      break;
    case -51:
      return "CL_INVALID_ARG_SIZE";
      break;
    case -52:
      return "CL_INVALID_KERNEL_ARGS";
      break;
    case -53:
      return "CL_INVALID_WORK_DIMENSION";
      break;
    case -54:
      return "CL_INVALID_WORK_GROUP_SIZE";
      break;
    case -55:
      return "CL_INVALID_WORK_ITEM_SIZE";
      break;
    case -56:
      return "CL_INVALID_GLOBAL_OFFSET";
      break;
    case -57:
      return "CL_INVALID_EVENT_WAIT_LIST";
      break;
    case -58:
      return "CL_INVALID_EVENT";
      break;
    case -59:
      return "CL_INVALID_OPERATION";
      break;
    case -60:
      return "CL_INVALID_GL_OBJECT";
      break;
    case -61:
      return "CL_INVALID_BUFFER_SIZE";
      break;
    case -62:
      return "CL_INVALID_MIP_LEVEL";
      break;
    case -63:
      return "CL_INVALID_GLOBAL_WORK_SIZE";
      break;
    default:
    {
      std::stringstream ss;
      ss << "Unrecognized CL error " << err;
      return ss.str();
    }
  }
}

std::vector<cl_device_id>
getClDevices(const std::string& platformStr,
             cl_device_type deviceType) {
  cl_uint n = 0;
  CHECK_CL(clGetPlatformIDs(0, nullptr, &n));

  std::vector<cl_platform_id> platformIds(n);
  CHECK_CL(clGetPlatformIDs(n, platformIds.data(), nullptr));

  for (auto pid : platformIds) {

    size_t size = 0;
    CHECK_CL(clGetPlatformInfo(pid, CL_PLATFORM_NAME, 0, nullptr, &size));

    std::string name(size, 0);

    // FIXME c++17 adds non-const data()
    CHECK_CL(clGetPlatformInfo(pid, CL_PLATFORM_NAME,
                               size, &name[0], nullptr));

    if (name.find(platformStr) != std::string::npos) {
      // This is a platform of concern
      cl_uint num = 0;
      CHECK_CL(clGetDeviceIDs(pid, deviceType, 0, nullptr, &num));

      std::vector<cl_device_id> devices(num);
      CHECK_CL(clGetDeviceIDs(pid, deviceType, num, devices.data(), nullptr));

      return devices;
    }
  }

  return std::vector<cl_device_id>();
}
