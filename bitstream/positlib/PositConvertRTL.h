// Copyright (c) Facebook, Inc. and its affiliates. All Rights Reserved.
// All rights reserved.
//
// This source code is licensed under the license found in the
// LICENSE file in the root directory of this source tree.

#ifndef __POSIT_CONVERT_RTL__
#define __POSIT_CONVERT_RTL__

#include "PositLibRTL.h"

unsigned int positToFloat8_1RTL(FloatType positIn, char expAdjust);
FloatType floatToPosit8_1RTL(unsigned int floatIn, char expAdjust);

#endif
