// Copyright (c) Facebook, Inc. and its affiliates. All Rights Reserved.
// All rights reserved.
//
// This source code is licensed under the license found in the
// LICENSE file in the root directory of this source tree.
#include "layers/Sequential.h"

#include "ops/TensorPrint.h"
#include <iostream>
#include <sstream>

namespace facebook { namespace cl {

Sequential::Sequential(const std::string& name)
    : name_(name),
      log_(false) {
}

std::string
Sequential::str() const {
  std::stringstream ss;
  ss << "Sequential";
  if (!name_.empty()) {
    ss << " " << name_;
  }

  if (!layers_.empty()) {
    ss << "\n";
  }

  for (int i = 0; i < layers_.size(); ++i) {
    ss << i << ":\n";
    ss << layers_[i]->str() << "\n";
  }

  return ss.str();
}

void
Sequential::log(bool b) {
  log_ = b;
}

size_t
Sequential::numLayers() const {
  return layers_.size();
}

Layer&
Sequential::getLayer(int i) {
  return *layers_[i];
}

void
Sequential::setRoundMode(RoundOp mode) {
  Layer::setRoundMode(mode);

  for (auto& l : layers_) {
    l->setRoundMode(mode);
  }
}

RoundOp
Sequential::getRoundMode() const {
  // FIXME: what should this be?
  return Layer::getRoundMode();
}

CLTensor<FloatType<kWidth>::T>&
Sequential::forward(Context& context,
                    Program& program,
                    Queue& queue,
                    const CLTensor<FloatType<kWidth>::T>& input) {
  input_ = input;

  CLTensor<FloatType<kWidth>::T>* prevOut = nullptr;

  for (int i = 0; i < layers_.size(); ++i) {
    auto& layer = layers_[i];
    if (!prevOut) {
      if (log_) {
        std::cout << "Layer " << (i + 1) << " input:" << std::endl;
        printPositTensor(context, program, queue, input);
      }

      prevOut = &(layer->forward(context, program, queue, input));

    } else {
      prevOut = &(layer->forward(context, program, queue, *prevOut));
    }

    if (log_) {
      std::cout << "Layer " << (i + 1) << " output: " << layer->str() << std::endl;
      printPositTensor(context, program, queue, *prevOut);
    }
  }

  if (prevOut) {
    output_ = *prevOut;
  }

  return output_;
}

CLTensor<FloatType<kWidth>::T>&
Sequential::updateGradInput(Context& context,
                            Program& program,
                            Queue& queue,
                            const CLTensor<FloatType<kWidth>::T>& input,
                            const CLTensor<FloatType<kWidth>::T>& gradOutput) {
  CL_ASSERT(input.isSameInstance(input_));

  CLTensor<FloatType<kWidth>::T>* prevGradInput = nullptr;

  for (int i = layers_.size() - 1; i >= 0; --i) {
    auto& layer = layers_[i];

    if (!prevGradInput) {
      if (log_) {
        std::cout << "Layer " << (i + 1) << " gradOutput:" << std::endl;
        printPositTensor(context, program, queue, gradOutput);
      }

      prevGradInput =
        &(layer->updateGradInput(context, program, queue,
                                 // FIXME
                                 layer->input_, gradOutput));

    } else {
      prevGradInput =
        &(layer->updateGradInput(context, program, queue,
                                 // FIXME
                                 layer->input_, *prevGradInput));
    }

    if (log_) {
      std::cout << "Layer " << (i + 1) << " gradInput: " << layer->str() << std::endl;
      printPositTensor(context, program, queue, *prevGradInput);
    }
  }

  if (prevGradInput) {
    gradInput_ = *prevGradInput;
  }

  return output_;
}

void
Sequential::accGradParameters(Context& context,
                              Program& program,
                              Queue& queue,
                              float scale,
                              const CLTensor<FloatType<kWidth>::T>& input,
                              const CLTensor<FloatType<kWidth>::T>& gradOutput) {
  for (int i = 0; i < layers_.size(); ++i) {
    const CLTensor<FloatType<kWidth>::T>& curInput = (i == 0) ?
      input : layers_[i - 1]->output_;
    const CLTensor<FloatType<kWidth>::T>& curGradOutput = (i == layers_.size() - 1) ?
      gradOutput : layers_[i + 1]->gradInput_;

    auto& layer = *layers_[i];

    layer.accGradParameters(context, program, queue,
                            scale,
                            curInput, curGradOutput);

    auto params = layer.getParameters();
    if (!params.empty()) {
      if (log_) {
        for (auto& p : params) {
          std::cout << "Layer " << (i + 1) << " " << layer.str()
                    << " grad param:" << std::endl;
          printPositTensor(context, program, queue, *p.gradParam);
        }
      }
    }
  }
}

std::vector<ParameterInfo>
Sequential::getParameters() {
  std::vector<ParameterInfo> params;

  for (auto& l : layers_) {
    auto lp = l->getParameters();

    params.insert(params.end(),
                  std::make_move_iterator(lp.begin()),
                  std::make_move_iterator(lp.end()));
  }

  return params;
}

void
Sequential::zeroGrad(Context& context,
                     Program& program,
                     Queue& queue) {
  for (auto& l : layers_) {
    l->zeroGrad(context, program, queue);
  }
}

} }
