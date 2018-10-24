// Copyright (c) Facebook, Inc. and its affiliates. All Rights Reserved.
// All rights reserved.
//
// This source code is licensed under the license found in the
// LICENSE file in the root directory of this source tree.

#ifndef __POSIT_QUIRE_MATH_RTL__
#define __POSIT_QUIRE_MATH_RTL__

#include "PositLibRTL.h"

// Converts a posit to the quire form
Product positQuireConvert8_1RTL(FloatType positA,
                                char adjustScale);

// Converts a product of posits to the quire form
Product positQuireMultiply8_1RTL(FloatType positA,
                                 FloatType positB,
                                 char adjustScale);

// Initialize a quire with a posit value
Accumulator positToQuire8_1RTL(FloatType positA,
                            char adjustScale);

// Initialize a quire with a product value
Accumulator productToQuire8_1RTL(Product productIn);

// Sums a product expansion or a converted posit with a quire
Accumulator quirePositAdd8_1RTL(Product productIn,
                                Accumulator quireIn);

// Sums a quire with a quire
Accumulator quireAdd8_1RTL(Accumulator quireA,
                           Accumulator quireB);

// Converts a quire back to posit with r2ne, with an optional adjustment factor
FloatType quireToPosit8_1RTL(Accumulator quireIn,
                             char adjustMul,
                             DeviceBool roundStochastic);

// Divides a quire by a small unsigned integer
Accumulator quireDivide8_1RTL(Accumulator quireIn,
                              unsigned char div);


#endif
