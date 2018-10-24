// Copyright (c) Facebook, Inc. and its affiliates. All Rights Reserved.
// All rights reserved.
//
// This source code is licensed under the license found in the
// LICENSE file in the root directory of this source tree.

#ifndef __LOG_LINEAR_MATH_RTL__
#define __LOG_LINEAR_MATH_RTL__

#include "LogLibRTL.h"

Accumulator logToLinear_RTL(FloatType logIn);

FloatType linearToLog_RTL(Accumulator accIn, char adjustExp);

Accumulator linearAdd_RTL(Accumulator linA,
                          Accumulator linB);

Accumulator logMultiplyToLinear_RTL(FloatType logA,
                                    FloatType logB);

Accumulator linearDivide_RTL(Accumulator accIn,
                             unsigned char div);

#endif
