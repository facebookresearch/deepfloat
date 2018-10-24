// Copyright (c) Facebook, Inc. and its affiliates. All Rights Reserved.
// All rights reserved.
//
// This source code is licensed under the license found in the
// LICENSE file in the root directory of this source tree.

#ifndef __LOG_MATH_RTL__
#define __LOG_MATH_RTL__

#include "LogLibRTL.h"

FloatType logAdd_RTL(FloatType a,
                   FloatType b,
                   DeviceBool subtract);

FloatType logMul_RTL(FloatType a,
                   FloatType b);

//FloatType logDiv8_1RTL(FloatType a,
//                     FloatType b);

#endif
