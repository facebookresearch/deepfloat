// Copyright (c) Facebook, Inc. and its affiliates. All Rights Reserved.
// All rights reserved.
//
// This source code is licensed under the license found in the
// LICENSE file in the root directory of this source tree.
#pragma once

#include "FloatDefs.h"
#include "utils/Event.h"
#include "utils/Tensor.h"
#include "ops/RoundOp.h"

namespace facebook { namespace cl {

enum class CompareOp { EQ, NE, LT, LE, GT, GE };

enum class MathOp : unsigned char { Add, Sub, Mul, Div, Min, Max };

enum class ScalarOp { Vector, Scalar };

template <typename T>
struct MathArg {
  inline MathArg(const CLTensor<T>& tensor, ScalarOp op = ScalarOp::Vector)
      : t(&tensor),
        // FIXME: different initialization scheme
        scalar(FloatType<kWidth>::kZero),
        useScalar(op == ScalarOp::Scalar) {
  }

  inline MathArg(T v)
      : t(nullptr),
        scalar(v),
        useScalar(true) {
  }

  inline OpType getOp() const {
    if (t && !useScalar) {
      return kVectorOp;
    } else if (t) {
      return kDeviceScalarOp;
    } else {
      return kHostScalarOp;
    }
  }

  const CLTensor<T>* t;
  T scalar;
  bool useScalar;
};

class Context;
class Program;
class Queue;

// out = I_n
Event
runEye(Context& context,
       Program& program,
       Queue& queue,
       CLTensor<FloatType<kWidth>::T>& inOut);

// out = uniform(a, b)
Event
runUniform(Context& context,
           Program& program,
           Queue& queue,
           float a, float b,
           CLTensor<FloatType<kWidth>::T>& inOut);

// out = N(m, s)
Event
runGaussian(Context& context,
            Program& program,
            Queue& queue,
            float mean, float stddev,
            CLTensor<FloatType<kWidth>::T>& inOut);

// out = FloatType<kWidth>::T(in)
Event
runToPosit8(Context& context,
            Program& program,
            Queue& queue,
            const CLTensor<float>& in,
            CLTensor<FloatType<kWidth>::T>& out,
            int expAdjust = 0);

// out = float(in)
Event
runToFloat(Context& context,
           Program& program,
           Queue& queue,
           const CLTensor<FloatType<kWidth>::T>& in,
           CLTensor<float>& out,
           int expAdjust = 0);

// C = beta * C + alpha * AB
Event
runMM(Context& context,
      Program& program,
      Queue& queue,
      const CLTensor<FloatType<kWidth>::T>& a,
      const CLTensor<FloatType<kWidth>::T>& b,
      bool beta,
      RoundOp rounding,
      int inScale,
      int outScale,
      CLTensor<FloatType<kWidth>::T>& c);

// c = beta * c + alpha * Ab
Event
runMV(Context& context,
      Program& program,
      Queue& queue,
      const CLTensor<FloatType<kWidth>::T>& a,
      const CLTensor<FloatType<kWidth>::T>& b,
      bool beta,
      RoundOp rounding,
      int inScale,
      int outScale,
      CLTensor<FloatType<kWidth>::T>& c);

// out = op(a, b)
Event
runBinaryMath(Context& context,
              Program& program,
              Queue& queue,
              const MathArg<FloatType<kWidth>::T>& a,
              const MathArg<FloatType<kWidth>::T>& b,
              MathOp mathOp,
              RoundOp rounding,
              CLTensor<FloatType<kWidth>::T>& out);

// sum or min/max reduction
Event
runReduce(Context& context,
          Program& program,
          Queue& queue,
          const CLTensor<FloatType<kWidth>::T>& a,
          MathOp mathOp,
          RoundOp rounding,
          CLTensor<FloatType<kWidth>::T>& out);

// out = c (+|-) a * b
Event
runMulAdd(Context& context,
          Program& program,
          Queue& queue,
          const MathArg<FloatType<kWidth>::T>& c,
          int scaleC,
          const MathArg<FloatType<kWidth>::T>& a,
          const MathArg<FloatType<kWidth>::T>& b,
          int scaleAB,
          bool subtract,
          RoundOp rounding,
          int scaleOut,
          CLTensor<FloatType<kWidth>::T>& out);


// out = a op b ? sel : 0
Event
runThresholdScalarHost(Context& context,
                       Program& program,
                       Queue& queue,
                       const CLTensor<FloatType<kWidth>::T>& a,
                       FloatType<kWidth>::T b,
                       const CLTensor<FloatType<kWidth>::T>& sel,
                       CompareOp op,
                       CLTensor<FloatType<kWidth>::T>& out);

// out = ln(a)
// a can be out
Event
runLn(Context& context,
      Program& program,
      Queue& queue,
      const CLTensor<FloatType<kWidth>::T>& a,
      CLTensor<FloatType<kWidth>::T>& out);

// out = exp(a)
// a can be out
Event
runExp(Context& context,
       Program& program,
       Queue& queue,
       const CLTensor<FloatType<kWidth>::T>& a,
       CLTensor<FloatType<kWidth>::T>& out);

// out = 1/a
// a can be out
Event
runInv(Context& context,
       Program& program,
       Queue& queue,
       const CLTensor<FloatType<kWidth>::T>& a,
       CLTensor<FloatType<kWidth>::T>& out);

// out = sqrt(a)
// a can be out
Event
runSqrt(Context& context,
        Program& program,
        Queue& queue,
        const CLTensor<FloatType<kWidth>::T>& a,
        CLTensor<FloatType<kWidth>::T>& out);

// out = sigmoid(a)
// a can be out
Event
runSigmoid(Context& context,
           Program& program,
           Queue& queue,
           const CLTensor<FloatType<kWidth>::T>& a,
           CLTensor<FloatType<kWidth>::T>& out);

} }
