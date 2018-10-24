// Copyright (c) Facebook, Inc. and its affiliates. All Rights Reserved.
// All rights reserved.
//
// This source code is licensed under the license found in the
// LICENSE file in the root directory of this source tree.
#include "ops/TensorMath.h"
#include "utils/MathUtils.h"
#include <random>

namespace facebook { namespace cl {

namespace {

OpType compareOpToDeviceOp(CompareOp op) {
  switch (op) {
    case CompareOp::EQ:
      return kComp_EQ;
    case CompareOp::NE:
      return kComp_NE;
    case CompareOp::LT:
      return kComp_LT;
    case CompareOp::LE:
      return kComp_LE;
    case CompareOp::GT:
      return kComp_GT;
    case CompareOp::GE:
      return kComp_GE;
    default:
      CL_ASSERT_MSG(false, "undefined operator");
      return kComp_EQ;
  }
}

OpType mathOpToDeviceOp(MathOp op) {
  switch (op) {
    case MathOp::Add:
      return kMathOp_Add;
    case MathOp::Sub:
      return kMathOp_Sub;
    case MathOp::Mul:
      return kMathOp_Mul;
    case MathOp::Div:
      return kMathOp_Div;
    case MathOp::Min:
      return kMathOp_Min;
    case MathOp::Max:
      return kMathOp_Max;
    default:
      CL_ASSERT_MSG(false, "undefined operator");
      return kMathOp_Add;
  }
}

void validatePointwiseArgs(const MathArg<FloatType<kWidth>::T>& a,
                           const MathArg<FloatType<kWidth>::T>& b,
                           CLTensor<FloatType<kWidth>::T>& out) {

  CL_ASSERT(out.isContiguous());

  if (a.t) {
    CL_ASSERT(a.t->isContiguous());

    if (a.useScalar) {
      CL_ASSERT(a.t->numElements() == 1);
    } else {
      CL_ASSERT(a.t->numElements() == out.numElements());
    }
  }

  if (b.t) {
    CL_ASSERT(b.t->isContiguous());

    if (b.useScalar) {
      CL_ASSERT(b.t->numElements() == 1);
    } else {
      CL_ASSERT(b.t->numElements() == out.numElements());
    }
  }

  if (a.t && b.t && !a.useScalar && !b.useScalar) {
    CL_ASSERT(a.t->isSameSize(*b.t));
  }
}

}

Event
runEye(Context& context,
       Program& program,
       Queue& queue,
       CLTensor<FloatType<kWidth>::T>& inOut) {
  CL_ASSERT(inOut.dims() == 2);

  // FIXME: implement on the FPGA
  HostTensor<FloatType<kWidth>::T, 2> t(inOut.sizes());

  for (int i = 0; i < t.getSize(0); ++i) {
    for (int j = 0; j < t.getSize(0); ++j) {
      if (i == j) {
        t[i][i] = FloatType<kWidth>::kOne;
      } else {
        t[i][j] = FloatType<kWidth>::kZero;
      }
    }
  }

  return inOut.copyFrom(queue, t);
}

Event
runUniform(Context& context,
           Program& program,
           Queue& queue,
           float a, float b,
           CLTensor<FloatType<kWidth>::T>& inOut) {
  std::random_device rd;
  std::mt19937 gen(rd());
  std::uniform_real_distribution<float> d(a, b);

  HostTensor<float, 1> rand({inOut.numElements()});

  for (size_t i = 0; i < rand.getSize(0); ++i) {
    rand[i] = d(gen);
  }

  auto device = CLTensor<float>(context, queue, rand).view(inOut.sizes());
  return runToPosit8(context, program, queue, device, inOut);
}

Event
runGaussian(Context& context,
            Program& program,
            Queue& queue,
            float mean, float stddev,
            CLTensor<FloatType<kWidth>::T>& inOut) {
  std::random_device rd;
  std::mt19937 gen(rd());
  std::normal_distribution<float> d(mean, stddev);

  HostTensor<float, 1> rand({inOut.numElements()});

  for (size_t i = 0; i < rand.getSize(0); ++i) {
    rand[i] = d(gen);
  }

  auto device = CLTensor<float>(context, queue, rand).view(inOut.sizes());
  return runToPosit8(context, program, queue, device, inOut);
}

Event
runToPosit8(Context& context,
            Program& program,
            Queue& queue,
            const CLTensor<float>& in,
            CLTensor<FloatType<kWidth>::T>& out,
            int expAdjust) {
  auto ker = program.getKernel("floatToPosit8_1");
  CL_ASSERT(in.isSameSize(out));
  CL_ASSERT(in.isContiguous());
  CL_ASSERT(out.isContiguous());

  return ker.callTask(queue,
                      in,
                      (char) expAdjust,
                      (unsigned int) in.numElements(),
                      out);
}

// out = float(in)
Event
runToFloat(Context& context,
           Program& program,
           Queue& queue,
           const CLTensor<FloatType<kWidth>::T>& in,
           CLTensor<float>& out,
           int expAdjust) {
  auto ker = program.getKernel("positToFloat8_1");
  CL_ASSERT(in.isSameSize(out));
  CL_ASSERT(in.isContiguous());
  CL_ASSERT(out.isContiguous());

  return ker.callTask(queue,
                      in,
                      (char) expAdjust,
                      (unsigned int) in.numElements(),
                      out);
}

// out = AB
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
      CLTensor<FloatType<kWidth>::T>& c) {
  auto kerMM = program.getKernel("positBatchMM8_1");

  CL_ASSERT(c.dims() == 2 || c.dims() == 3);
  CL_ASSERT(a.dims() == 2 || a.dims() == 3);
  CL_ASSERT(b.dims() == 2 || b.dims() == 3);

  // If c is 3 dimensional, we are in batch mode. A and B individually might be
  // batched or un-batched
  int cBatch = c.dims() == 3;
  int aBatch = a.dims() == 3;
  int bBatch = b.dims() == 3;

  if (!cBatch) {
    CL_ASSERT(a.dims() == 2);
    CL_ASSERT(b.dims() == 2);
    CL_ASSERT(a.getSize(0) == c.getSize(0));
    CL_ASSERT(a.getSize(1) == b.getSize(0));
    CL_ASSERT(b.getSize(1) == c.getSize(1));
  } else {
    CL_ASSERT(a.getSize(0 + aBatch) == c.getSize(1));
    CL_ASSERT(a.getSize(1 + aBatch) == b.getSize(0 + bBatch));
    CL_ASSERT(b.getSize(1 + bBatch) == c.getSize(2));

    if (aBatch) {
      CL_ASSERT(a.getSize(0) == c.getSize(0));
    }

    if (bBatch) {
      CL_ASSERT(b.getSize(0) == c.getSize(0));
    }
  }

  // FIXME: handle transposed MM
  CL_ASSERT(a.isContiguous());
  CL_ASSERT(b.isContiguous());
  CL_ASSERT(c.isContiguous());

  CL_ASSERT(!c.isSameInstance(a));
  CL_ASSERT(!c.isSameInstance(b));

  unsigned int m = c.getSize(0 + cBatch);
  unsigned int n = c.getSize(1 + cBatch);
  unsigned int k = a.getSize(1 + aBatch);

  // std::cout << "MM size " << "(" << m << " x " << k << ")"
  //           << " x (" << k << " x " << n << ")\n";

  // std::cout << "Running with scale " << (int) scale << "\n";

  return kerMM.callTask(queue,
                        c, a, b,
                        toDeviceBool(beta),
                        (char) 0,
                        (char) inScale,
                        (char) outScale,
                        toDeviceBool(rounding == RoundOp::Stochastic),
                        cBatch ? (unsigned int) c.getSize(0) : 1,
                        m, n, k,
                        (unsigned int) (aBatch ?
                                        a.getSize(1) * a.getSize(2) : 0),
                        (unsigned int) (bBatch ?
                                        b.getSize(1) * b.getSize(2) : 0),
                        (unsigned int) (cBatch ?
                                        c.getSize(1) * c.getSize(2) : 0));
}

// out = Ab
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
      CLTensor<FloatType<kWidth>::T>& c) {
  auto kerMM = program.getKernel("positBatchMM8_1");

  // FIXME: implement batch
  CL_ASSERT(a.dims() == 2);
  CL_ASSERT(b.dims() == 1);
  CL_ASSERT(c.dims() == 1);

  CL_ASSERT(a.getSize(0) == c.getSize(0));
  CL_ASSERT(a.getSize(1) == b.getSize(0));

  // FIXME: handle transposed MM
  CL_ASSERT(a.isContiguous());
  CL_ASSERT(b.isContiguous());
  CL_ASSERT(c.isContiguous());

  CL_ASSERT(!c.isSameInstance(a));
  CL_ASSERT(!c.isSameInstance(b));

  return kerMM.callTask(queue,
                        c, a, b,
                        toDeviceBool(beta),
                        (char) 0,
                        (char) inScale,
                        (char) outScale,
                        toDeviceBool(rounding == RoundOp::Stochastic),
                        1, // batch size
                        (unsigned int) c.getSize(0),
                        (unsigned int) 1,
                        (unsigned int) a.getSize(1),
                        0,
                        0,
                        0);
}

// out = op(a, b)
Event
runBinaryMath(Context& context,
              Program& program,
              Queue& queue,
              const MathArg<FloatType<kWidth>::T>& a,
              const MathArg<FloatType<kWidth>::T>& b,
              MathOp mathOp,
              RoundOp rounding,
              CLTensor<FloatType<kWidth>::T>& out) {
  auto ker = program.getKernel("positBinaryMath8_1");

  validatePointwiseArgs(a, b, out);

  return ker.callTask(queue,
                      a.t ? *a.t : out,
                      0,
                      a.scalar,
                      a.getOp(),
                      b.t ? *b.t : out,
                      0,
                      b.scalar,
                      b.getOp(),
                      1,
                      (unsigned int) out.numElements(),
                      mathOpToDeviceOp(mathOp),
                      toDeviceBool(rounding == RoundOp::Stochastic),
                      out,
                      0);
}

Event
runReduce(Context& context,
          Program& program,
          Queue& queue,
          const CLTensor<FloatType<kWidth>::T>& a,
          MathOp mathOp,
          RoundOp rounding,
          CLTensor<FloatType<kWidth>::T>& out) {
  auto ker = program.getKernel("positReduce8_1");

  CL_ASSERT(out.numElements() == 1);
  CL_ASSERT(mathOp == MathOp::Add ||
            mathOp == MathOp::Min ||
            mathOp == MathOp::Max);

  return ker.callTask(queue,
                      a,
                      (unsigned int) a.numElements(),
                      mathOpToDeviceOp(mathOp),
                      toDeviceBool(rounding == RoundOp::Stochastic),
                      out);
}

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
          CLTensor<FloatType<kWidth>::T>& out) {
  auto ker = program.getKernel("positMulAdd8_1");

  if (c.t) {
    CL_ASSERT(c.t->isContiguous());

    if (c.useScalar) {
      CL_ASSERT(c.t->numElements() == 1);
    } else {
      CL_ASSERT(c.t->numElements() == out.numElements());
    }
  }

  if (a.t) {
    CL_ASSERT(a.t->isContiguous());

    if (a.useScalar) {
      CL_ASSERT(a.t->numElements() == 1);
    } else {
      CL_ASSERT(a.t->numElements() == out.numElements());
    }
  }

  // always a tensor
  CL_ASSERT(b.t);
  CL_ASSERT(b.t->isContiguous());
  CL_ASSERT(b.t->numElements() == out.numElements());

  return ker.callTask(queue,
                      c.t ? *c.t : out,
                      c.scalar,
                      c.getOp(),
                      (char) scaleC,

                      a.t ? *a.t : out,
                      a.scalar,
                      a.getOp(),

                      *b.t,
                      (char) scaleAB,

                      toDeviceBool(subtract),
                      toDeviceBool(rounding == RoundOp::Stochastic),
                      (char) scaleOut,
                      (unsigned int) out.numElements(),
                      out);
}

Event
runThresholdScalarHost(Context& context,
                       Program& program,
                       Queue& queue,
                       const CLTensor<FloatType<kWidth>::T>& a,
                       FloatType<kWidth>::T b,
                       const CLTensor<FloatType<kWidth>::T>& sel,
                       CompareOp op,
                       CLTensor<FloatType<kWidth>::T>& out) {
  auto ker = program.getKernel("positThreshold8_1");

  CL_ASSERT(a.isSameSize(out));
  CL_ASSERT(a.isSameSize(sel));
  CL_ASSERT(a.isContiguous());
  CL_ASSERT(sel.isContiguous());
  CL_ASSERT(out.isContiguous());

  return ker.callTask(queue,
                      a,
                      a, // b
                      (unsigned int) a.numElements(),
                      b,
                      sel,
                      kHostScalarOp,
                      compareOpToDeviceOp(op),
                      out);
}

Event
runSpecialPointwiseInplace(Context& context,
                           Program& program,
                           Queue& queue,
                           unsigned char funcType,
                           const CLTensor<FloatType<kWidth>::T>& a,
                           CLTensor<FloatType<kWidth>::T>& out) {
  auto ker = program.getKernel("positSpecialFunc8_1");

  if (!a.isSameInstance(out)) {
    // Must copy then operate in-place
    out.copyFrom(queue, a);
  }

  return ker.callTask(queue,
                      out,
                      funcType,
                      (unsigned int) out.numElements());
}

// out = ln(a)
// a can be out
Event
runLn(Context& context,
      Program& program,
      Queue& queue,
      const CLTensor<FloatType<kWidth>::T>& a,
      CLTensor<FloatType<kWidth>::T>& out) {
  return runSpecialPointwiseInplace(context, program, queue, 1, a, out);
}

// out = ln(a)
// a can be out
Event
runExp(Context& context,
       Program& program,
       Queue& queue,
       const CLTensor<FloatType<kWidth>::T>& a,
       CLTensor<FloatType<kWidth>::T>& out) {
  return runSpecialPointwiseInplace(context, program, queue, 0, a, out);
}

// out = 1/a
// a can be out
Event
runInv(Context& context,
       Program& program,
       Queue& queue,
       const CLTensor<FloatType<kWidth>::T>& a,
       CLTensor<FloatType<kWidth>::T>& out) {
  return runSpecialPointwiseInplace(context, program, queue, 2, a, out);
}

// out = sqrt(a)
// a can be out
Event
runSqrt(Context& context,
        Program& program,
        Queue& queue,
        const CLTensor<FloatType<kWidth>::T>& a,
        CLTensor<FloatType<kWidth>::T>& out) {
  return runSpecialPointwiseInplace(context, program, queue, 3, a, out);
}

// out = sigmoid(a)
// a can be out
Event
runSigmoid(Context& context,
           Program& program,
           Queue& queue,
           const CLTensor<FloatType<kWidth>::T>& a,
           CLTensor<FloatType<kWidth>::T>& out) {
  return runSpecialPointwiseInplace(context, program, queue, 4, a, out);
}

} }
