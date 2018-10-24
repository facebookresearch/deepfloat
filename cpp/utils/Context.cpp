// Copyright (c) Facebook, Inc. and its affiliates. All Rights Reserved.
// All rights reserved.
//
// This source code is licensed under the license found in the
// LICENSE file in the root directory of this source tree.
#include "utils/Context.h"
#include "utils/OpenCLUtils.h"

namespace facebook { namespace cl {

template <typename T>
T getDeviceInfo(cl_device_id id, cl_device_info info) {
  T v = 0;
  CHECK_CL(clGetDeviceInfo(id, info, sizeof(T), &v, 0));

  return v;
}

Context::Context() :
    device_(0),
    context_(0),
    svm_(false),
    align_(0) {
}

Context::Context(cl_device_id device,
                 ContextCallback callback,
                 void* userData)
    : device_(device),
      context_(0) {
  cl_int err = 0;
  context_ = clCreateContext(nullptr,
                             1,
                             &device,
                             callback,
                             userData,
                             &err);
  CHECK_CL(err);

  cl_device_svm_capabilities svmCaps =
    getDeviceInfo<cl_device_svm_capabilities>(device,
                                              CL_DEVICE_SVM_CAPABILITIES);
  svm_ = (svmCaps & CL_DEVICE_SVM_COARSE_GRAIN_BUFFER) != 0;

  align_ = getDeviceInfo<cl_uint>(device, CL_DEVICE_MEM_BASE_ADDR_ALIGN);

  defaultQueue_ = makeQueue();
}

Context::Context(Context&& e) :
    device_(0),
    context_(0),
    svm_(false) {
  operator=(std::move(e));
}

Context::~Context() {
  release();
}

Context&
Context::operator=(Context&& e) {
  release();
  device_ = std::move(e.device_);
  context_ = std::move(e.context_);
  svm_ = std::move(e.svm_);
  defaultQueue_ = std::move(e.defaultQueue_);

  e.device_ = 0;
  e.context_ = 0;
  e.svm_ = false;

  return *this;
}

Program
Context::makeBinaryProgram(const std::string& binaryFile) {
  auto fp = fopen(binaryFile.c_str(), "rb");
  if (!fp) {
    std::string res = "program file '" + binaryFile + "' not found";
    CL_ASSERT_MSG(fp, res.c_str());
  }

  fseek(fp, 0, SEEK_END);
  size_t bytes = ftell(fp);
  rewind(fp);

  std::vector<unsigned char> binary(bytes);
  if(!fread(binary.data(), bytes, 1, fp)) {
    fclose(fp);
    return Program();
  }

  auto ptr = (const unsigned char*) binary.data();
  auto size = binary.size();

  cl_int binaryStatus = 0;
  cl_int err = 0;
  auto program =
    facebook::cl::Program(
      clCreateProgramWithBinary(context_,
                                1,
                                &device_,
                                &size,
                                &ptr,
                                &binaryStatus,
                                &err));
  CHECK_CL_MSG(err, "clCreateProgramWithBinary failed");
  CHECK_CL_MSG(binaryStatus, "clCreateProgramWithBinary: binary status failed");

  CHECK_CL(clBuildProgram(program, 0, nullptr, "", nullptr, nullptr));

  return program;
}

Queue
Context::makeQueue(cl_command_queue_properties properties) {
  cl_int err = 0;
  cl_command_queue q =
    clCreateCommandQueue(context_, device_, properties, &err);

  CHECK_CL(err);

  return Queue(q);
}

Queue&
Context::getDefaultQueue() {
  return defaultQueue_;
}

void
Context::release() {
  if (context_) {
    CHECK_CL(clReleaseContext(context_));
    context_ = 0;
  }
}

} } // namespace
