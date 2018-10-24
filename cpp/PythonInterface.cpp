// Copyright (c) Facebook, Inc. and its affiliates. All Rights Reserved.
// All rights reserved.
//
// This source code is licensed under the license found in the
// LICENSE file in the root directory of this source tree.
#include <sstream>
#include <tuple>
#include <torch/torch.h>

#include "TorchUtils.h"
#include "FloatDefs.h"
#include "layers/Add.h"
#include "layers/Conv2d.h"
#include "layers/Linear.h"
#include "layers/Pool2d.h"
#include "layers/ReLU.h"
#include "layers/View.h"

namespace facebook { namespace cl {

std::tuple<Context, Program, Queue>
createOpenCLProgram(const std::string& file) {
  auto devices = getClDevices("FPGA", CL_DEVICE_TYPE_ALL);
  CL_ASSERT_MSG(!devices.empty(), "Did not find FPGA device");

  auto context = Context(devices.front());
  auto queue = context.makeQueue();
  auto program = context.makeBinaryProgram(file);

  return std::make_tuple(std::move(context),
                         std::move(program),
                         std::move(queue));
}

} } // namespace

using namespace facebook::cl;

std::string makeLibLocation(const char* path, const char* lib) {
  std::stringstream ss;
  ss << path << "/build_" << lib << "/" << lib << ".aocx";

  return ss.str();
}

std::tuple<Context, Program, Queue>
fpga_init(const std::string& dir,
          const std::string& img) {
  auto lib = makeLibLocation(dir.c_str(), img.c_str());
  std::cout << "Loading lib from " << lib << "\n";

  return createOpenCLProgram(lib.c_str());
}

PYBIND11_MODULE(TORCH_EXTENSION_NAME, m) {
  m.def("fpga_init",
        &fpga_init,
        "fpga_init");

  py::class_<Context>(m, "Context")
    .def(py::init<>());

  py::class_<Program>(m, "Program")
    .def(py::init<>());

  py::class_<Queue>(m, "Queue")
    .def(py::init<>())
    .def("blockingWait", &Queue::blockingWait);

  py::class_<CLTensor<facebook::FloatType<
    facebook::kWidth>::T>>(m, "FpgaFloatTensor")
    .def(py::init<>())
    .def("sizes", &CLTensor<facebook::FloatType<facebook::kWidth>::T>::sizes)
    .def("dims", &CLTensor<facebook::FloatType<facebook::kWidth>::T>::dims);

  py::enum_<MathOp>(m, "MathOp", py::arithmetic())
    .value("Add", MathOp::Add)
    .value("Sub", MathOp::Sub)
    .value("Mul", MathOp::Mul)
    .value("Div", MathOp::Div)
    .value("Min", MathOp::Min)
    .value("Max", MathOp::Max);

  py::enum_<RoundOp>(m, "RoundOp", py::arithmetic())
    .value("R2NE", RoundOp::R2NE)
    .value("Stochastic", RoundOp::Stochastic);

  py::enum_<ScalarOp>(m, "ScalarOp", py::arithmetic())
    .value("Vector", ScalarOp::Vector)
    .value("Scalar", ScalarOp::Scalar);

  py::enum_<CompareOp>(m, "CompareOp", py::arithmetic())
    .value("EQ", CompareOp::EQ)
    .value("NE", CompareOp::NE)
    .value("LT", CompareOp::LT)
    .value("LE", CompareOp::LE)
    .value("GT", CompareOp::GT)
    .value("GE", CompareOp::GE);

  py::class_<Linear>(m, "Linear")
    .def(py::init<Context&,
         Program&,
         Queue&,
         int,
         int,
         bool,
         int,
         int>())
    .def("setRoundMode", &Linear::setRoundMode)
    .def("setOutputScale", &Linear::setOutputScale)
    .def("setInputScale", &Linear::setInputScale)
    .def("getOutputScale", &Linear::getOutputScale)
    .def("getInputScale", &Linear::getInputScale)
    .def("setWeight", &Linear::setWeight)
    .def("setBias", &Linear::setBias)
    .def("getInput", &Linear::getInput)
    .def("getOutput", &Linear::getOutput)
    .def("forward", &Linear::forward)
    .def("str", &Linear::str);

  py::class_<Conv2d>(m, "Conv2d")
    .def(py::init<Context&,
         Program&,
         Queue&,
         int,
         int,
         int,
         int,
         int,
         int,
         bool,
         int,
         int>())
    .def("setRoundMode", &Conv2d::setRoundMode)
    .def("setOutputScale", &Conv2d::setOutputScale)
    .def("setInputScale", &Conv2d::setInputScale)
    .def("getOutputScale", &Conv2d::getOutputScale)
    .def("getInputScale", &Conv2d::getInputScale)
    .def("setWeight", &Conv2d::setWeight)
    .def("setBias", &Conv2d::setBias)
    .def("getInput", &Conv2d::getInput)
    .def("getOutput", &Conv2d::getOutput)
    .def("forward", &Conv2d::forward)
    .def("str", &Conv2d::str);

  py::enum_<PoolOp>(m, "PoolOp", py::arithmetic())
    .value("Avg", PoolOp::Avg)
    .value("Max", PoolOp::Max);

  py::class_<Pool2d>(m, "Pool2d")
    .def(py::init<Context&,
         Program&,
         Queue&,
         int,
         int,
         int,
         int,
         PoolOp,
         int,
         int>())
    .def("setRoundMode", &Pool2d::setRoundMode)
    .def("setOutputScale", &Pool2d::setOutputScale)
    .def("setInputScale", &Pool2d::setInputScale)
    .def("getOutputScale", &Pool2d::getOutputScale)
    .def("getInputScale", &Pool2d::getInputScale)
    .def("forward", &Pool2d::forward)
    .def("getInput", &Pool2d::getInput)
    .def("getOutput", &Pool2d::getOutput)
    .def("str", &Pool2d::str);

  py::class_<ReLU>(m, "ReLU")
    .def(py::init<Context&,
         Program&,
         Queue&>())
    .def("forward", &ReLU::forward)
    .def("getInput", &ReLU::getInput)
    .def("getOutput", &ReLU::getOutput)
    .def("str", &ReLU::str);

  py::class_<Add>(m, "Add")
    .def(py::init<Context&,
         Program&,
         Queue&,
         int,
         int,
         int>())
    .def("setRoundMode", &Add::setRoundMode)
    .def("setOutputScale", &Add::setOutputScale)
    .def("setInputScale", &Add::setInputScale)
    .def("getOutputScale", &Add::getOutputScale)
    .def("getInputScale", &Add::getInputScale)
    .def("setAddScale", &Add::setAddScale)
    .def("getAddScale", &Add::getAddScale)
    .def("getInput", &Add::getInput)
    .def("getOutput", &Add::getOutput)
    .def("forward", &Add::forward)
    .def("setAdd", &Add::setAdd)
    .def("str", &Add::str);

  py::class_<View>(m, "View")
    .def(py::init<Context&,
         Program&,
         Queue&,
         std::vector<std::vector<int>>&>())
    .def("forward", &View::forward)
    .def("getInput", &View::getInput)
    .def("getOutput", &View::getOutput)
    .def("str", &View::str);

  m.def("to_posit", &torchToDevicePosit, "to_posit");
  m.def("to_float", &devicePositToTorch, "to_float");
  m.def("to_host_posit", &devicePositToTorchPosit, "to_host_posit");

  py::class_<facebook::cl::Event>(m, "Event")
    .def(py::init<>());

  py::class_<facebook::cl::MathArg<
    facebook::FloatType<facebook::kWidth>::T>>(m, "MathArg")
    .def(py::init<const CLTensor<facebook::FloatType<
         facebook::kWidth>::T>&, ScalarOp>());

  m.def("reduce", &facebook::cl::runReduce, "reduce");
  m.def("mm", &facebook::cl::runMM, "mm");
  m.def("mul_add", &facebook::cl::runMulAdd, "mul_add");
  m.def("binary_math", &facebook::cl::runBinaryMath, "binary_math");
}
