// Copyright (c) Facebook, Inc. and its affiliates. All Rights Reserved.
// All rights reserved.
//
// This source code is licensed under the license found in the
// LICENSE file in the root directory of this source tree.
#include "layers/Linear.h"

#include <cmath>
#include <sstream>
#include "ops/TensorMath.h"
#include "ops/TensorMemory.h"

namespace facebook { namespace cl {

Linear::Linear(Context& context,
               Program& program,
               Queue& queue,
               int inFeatures,
               int outFeatures,
               bool bias,
               int inputScale,
               int outputScale)
    : weight_(context, {outFeatures, inFeatures}),
      // FIXME: implement transposed MM
      weightTranspose_(context, {inFeatures, outFeatures}),
      bias_(bias ? new CLTensor<FloatType<kWidth>::T>(context, {outFeatures}) : nullptr),
      gradWeight_(context, {outFeatures, inFeatures}),
      gradBias_(bias ? new CLTensor<FloatType<kWidth>::T>(context, {outFeatures}) : nullptr),
      inFeatures_(inFeatures),
      outFeatures_(outFeatures),
      inputScale_(inputScale),
      outputScale_(outputScale) {
  reset(context, program, queue);
}

std::string
Linear::str() const {
  std::stringstream ss;
  ss << "Linear (" << inFeatures_
     << " -> " << outFeatures_
     << (bias_ ? " (biased)" : "")
     << ")";

  return ss.str();
}

void
Linear::setInputScale(int scale) {
  inputScale_ = scale;
}

int
Linear::getInputScale() const {
  return inputScale_;
}

void
Linear::setOutputScale(int scale) {
  outputScale_ = scale;
}

int
Linear::getOutputScale() const {
  return outputScale_;
}

void
Linear::reset(Context& context,
              Program& program,
              Queue& queue) {
  float stdv = 1.0f / std::sqrt((float) weight_.getSize(1));
  runUniform(context, program, queue, -stdv, stdv, weight_);
  runTranspose(context, program, queue, weight_, weightTranspose_);

  if (bias_) {
    runUniform(context, program, queue, -stdv, stdv, *bias_);
  }
}

void
Linear::setWeightHost(Context& context,
                      Program& program,
                      Queue& queue,
                      const HostTensor<float, 2>& weight) {
  CL_ASSERT(weight.isSize({outFeatures_, inFeatures_}));

  CLTensor<float> tmp(context, queue, weight);

  runToPosit8(context, program, queue, tmp, weight_);
  runTranspose(context, program, queue, weight_, weightTranspose_);
}

void
Linear::setWeight(Context& context,
                  Program& program,
                  Queue& queue,
                  const CLTensor<FloatType<kWidth>::T>& weight) {
  CL_ASSERT(weight.isSize({outFeatures_, inFeatures_}));
  weight_ = weight;
  runTranspose(context, program, queue, weight_, weightTranspose_);
}

void
Linear::setBiasHost(Context& context,
                    Program& program,
                    Queue& queue,
                    const HostTensor<float, 1>& bias) {
  CL_ASSERT(bias.isSize({outFeatures_}));

  if (!bias_) {
    bias_.reset(new CLTensor<FloatType<kWidth>::T>(context, {outFeatures_}));
    gradBias_.reset(new CLTensor<FloatType<kWidth>::T>(context, {outFeatures_}));
  }

  CLTensor<float> tmp(context, queue, bias);
  runToPosit8(context, program, queue, tmp, *bias_);
}

void
Linear::setBias(Context& context,
                Program& program,
                Queue& queue,
                const CLTensor<FloatType<kWidth>::T>& bias) {
  CL_ASSERT(bias.isSize({outFeatures_}));

  if (!bias_) {
    bias_.reset(new CLTensor<FloatType<kWidth>::T>(context, {outFeatures_}));
    gradBias_.reset(new CLTensor<FloatType<kWidth>::T>(context, {outFeatures_}));
  }

  *bias_ = bias;
}

CLTensor<FloatType<kWidth>::T>&
Linear::forward(Context& context,
                Program& program,
                Queue& queue,
                const CLTensor<FloatType<kWidth>::T>& input) {
  CL_ASSERT(input.dims() <= 2);

  input_ = input;

  if (input.dims() == 1) {
    if ((output_.dims() != 1) ||
        (output_.getSize(0) != outFeatures_)) {
      output_ = CLTensor<FloatType<kWidth>::T>(context, {outFeatures_});
    }

    CL_ASSERT(output_.getSize(0) == weight_.getSize(0));

    if (bias_) {
      CL_ASSERT(output_.getSize(0) == bias_->getSize(0));

      runMemcpy(context, program, queue,
                *bias_,
                output_.getSize(0),
                1,
                0,
                0,
                output_);
    }

    runMV(context, program, queue,
          weight_, input,
          (bool) bias_, /* beta */
          getRoundMode(),
          inputScale_,
          outputScale_,
          output_);
  } else if (input.dims() == 2) {
    int numBatch = input.getSize(0);

    if ((output_.dims() != 2) ||
        (output_.getSize(0) != numBatch) ||
        (output_.getSize(1) != outFeatures_)) {
      output_ = CLTensor<FloatType<kWidth>::T>(context, {numBatch, outFeatures_});
    }

    if (bias_) {
      runMemcpy(context, program, queue,
                *bias_,
                // Size of batch
                output_.getSize(1),
                // Total number of batches
                numBatch,
                // Source stride
                0,
                // Dest stride
                output_.getStride(0),
                // Output
                output_);
    }

    // (batch x in) x (in x out) = (batch x out)
    runMM(context, program, queue,
          input, weightTranspose_,
          (bool) bias_ /* beta */,
          getRoundMode(),
          inputScale_,
          outputScale_,
          output_);
  }

  return output_;
}

CLTensor<FloatType<kWidth>::T>&
Linear::updateGradInput(Context& context,
                        Program& program,
                        Queue& queue,
                        const CLTensor<FloatType<kWidth>::T>& input,
                        const CLTensor<FloatType<kWidth>::T>& gradOutput) {
  CL_ASSERT(input.dims() <= 2);
  CL_ASSERT(gradOutput.dims() <= 2);
  CL_ASSERT(input.dims() == gradOutput.dims());
  CL_ASSERT(input_.isSameInstance(input));

  if (!gradInput_.isSameSize(input)) {
    // resize gradInput
    gradInput_ = CLTensor<FloatType<kWidth>::T>(context, input.sizes());
  }

  // (batch x output) x (output x input)
  if (input.dims() == 1) {
    runMV(context, program, queue,
          weightTranspose_, gradOutput,
          false /* beta */,
          getRoundMode(),
          (char) 0, // FIXME: what here for inputScale?
          (char) 0, // FIXME: what here for outputScale?
          gradInput_);
  } else if (input.dims() == 2) {
    runMM(context, program, queue,
          gradOutput, weight_,
          false /* beta */,
          getRoundMode(),
          (char) 0, // FIXME: what here for inputScale?
          (char) 0, // FIXME: what here for outputScale?
          gradInput_);
  }

  return gradInput_;
}

void
Linear::accGradParameters(Context& context,
                          Program& program,
                          Queue& queue,
                          float scale,
                          const CLTensor<FloatType<kWidth>::T>& input,
                          const CLTensor<FloatType<kWidth>::T>& gradOutput) {
  CL_ASSERT(input.dims() == 1 || input.dims() == 2);
  CL_ASSERT(input.dims() == gradOutput.dims());

  // gradWeight += scale * (gradOutput^t x input)
  // gradBias += scale * (gradOutput^t x [batch 1s])

  // FIXME: unimplemented conversion to posit
  CL_ASSERT_MSG(scale == 1.0f, "NYI");
  // FloatType<kWidth>::T pScale = FloatType<kWidth>::kOne;

  if (input.dims() == 1) {
    // outer product of gradOutput x input
    // gradOutput -> (gradOutput, 1)
    // input -> (1, input)
    auto gradOutputView = gradOutput.upcastInner(2);
    auto inputView = input.upcastOuter(2);

    runMM(context, program, queue,
          gradOutputView, inputView,
          true, /* FIXME: beta */
          getRoundMode(),
          (char) 0, // FIXME: what here for inputScale?
          (char) 0, // FIXME: what here for outputScale?
          gradWeight_);

    if (bias_) {
      runBinaryMath(context, program, queue,
                    MathArg<FloatType<kWidth>::T>(*gradBias_),
                    MathArg<FloatType<kWidth>::T>(gradOutput),
                    MathOp::Add,
                    getRoundMode(),
                    *gradBias_);
    }
  } else if (input.dims() == 2) {
    // FIXME: need transposed MM
    auto gradOutputTranspose =
      CLTensor<FloatType<kWidth>::T>(context, gradOutput.transpose(0, 1).sizes());

    runTranspose(context, program, queue,
                 gradOutput, gradOutputTranspose);

    runMM(context, program, queue,
          gradOutputTranspose, input,
          true, /* FIXME: beta */
          getRoundMode(),
          (char) 0, // FIXME: what here for inputScale?
          (char) 0, // FIXME: what here for outputScale?
          gradWeight_);

    if (bias_) {
      // FIXME: cache
      // FIXME: integrate with above
      auto oneBuffer =
        CLTensor<FloatType<kWidth>::T>(context, {input.getSize(0)});

      runMemset(context, program, queue,
                FloatType<kWidth>::kOne,
                oneBuffer);

      runMV(context, program, queue,
            gradOutputTranspose, oneBuffer,
            true, /* FIXME: beta */
            getRoundMode(),
            (char) 0, // FIXME: what here for inputScale?
            (char) 0, // FIXME: what here for outputScale?
            *gradBias_);
    }
  }
}

std::vector<ParameterInfo>
Linear::getParameters() {
  std::vector<ParameterInfo> params;

  ParameterInfo info;
  info.param = &weight_;
  info.gradParam = &gradWeight_;
  info.name = str() + " W";
  params.emplace_back(std::move(info));

  if (bias_) {
    ParameterInfo info;
    info.param = bias_.get();
    info.gradParam = gradBias_.get();
    info.name = str() + " bias";
    params.emplace_back(std::move(info));
  }

  return params;
}

void
Linear::zeroGrad(Context& context,
                 Program& program,
                 Queue& queue) {
  runMemset(context, program, queue, FloatType<kWidth>::kZero, gradWeight_);
  if (bias_) {
    runMemset(context, program, queue, FloatType<kWidth>::kZero, *gradBias_);
  }
}

} }
