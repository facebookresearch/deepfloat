// Copyright (c) Facebook, Inc. and its affiliates. All Rights Reserved.
// All rights reserved.
//
// This source code is licensed under the license found in the
// LICENSE file in the root directory of this source tree.

#ifndef __POSIT_MATH_RTL__
#define __POSIT_MATH_RTL__

#include "PositLibRTL.h"

FloatType positAdd8_1RTL(FloatType positA,
                         FloatType positB,
                         DeviceBool subtract,
                         DeviceBool roundStochastic);

FloatType positMul8_1RTL(FloatType positA,
                         FloatType positB,
                         DeviceBool roundStochastic);

FloatType positDiv8_1RTL(FloatType positA,
                         FloatType positB);

#endif
