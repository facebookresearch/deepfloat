// Copyright (c) Facebook, Inc. and its affiliates. All Rights Reserved.
// All rights reserved.
//
// This source code is licensed under the license found in the
// LICENSE file in the root directory of this source tree.


// This contains unimplemented stub functions for CPU-side emulation
// aoc doesn't allow includes here
// #include "PositLibRTL.h"

#ifndef __POSIT_DEFS__
#define __POSIT_DEFS__

typedef unsigned char FloatType;
typedef unsigned short posit16;
typedef unsigned char OpType;
typedef unsigned char DeviceBool;

#endif

FloatType positAdd8_1RTL(FloatType positA,
                         FloatType positB,
                         DeviceBool subtract,
                         DeviceBool roundStochastic) {
  // don't implement for now
  return (FloatType) 0;
}

FloatType positMul8_1RTL(FloatType positA,
                         FloatType positB,
                         DeviceBool roundStochastic) {
  // don't implement for now
  return (FloatType) 0;
}

FloatType positDiv8_1RTL(FloatType positA,
                         FloatType positB,
                         DeviceBool roundStochastic) {
  // don't implement for now
  return (FloatType) 0;
}
