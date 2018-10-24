// Copyright (c) Facebook, Inc. and its affiliates. All Rights Reserved.
// All rights reserved.
//
// This source code is licensed under the license found in the
// LICENSE file in the root directory of this source tree.

#ifndef __POSIT_MATH_COMPARE_RTL__
#define __POSIT_MATH_COMPARE_RTL__

#include "PositLibRTL.h"

FloatType positMax8_1RTL(FloatType positA,
                         FloatType positB);

FloatType positMin8_1RTL(FloatType positA,
                         FloatType positB);

DeviceBool positComp8_1RTL(FloatType positA,
                           FloatType positB,
                           OpType comp);

#endif
