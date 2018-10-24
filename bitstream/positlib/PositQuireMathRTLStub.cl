// Copyright (c) Facebook, Inc. and its affiliates. All Rights Reserved.
// All rights reserved.
//
// This source code is licensed under the license found in the
// LICENSE file in the root directory of this source tree.


Product positQuireConvert8_1RTL(FloatType positA) {
  Product p;
  p.data = 0;

  return p;
}

Product
positQuireMultiply8_1RTL(FloatType positA,
                         FloatType positB,
                         char adjustScale) {
  Product p;
  p.data = 0;

  return p;
}

Accumulator
positToQuire8_1RTL(FloatType positA,
                   char adjustScale) {
  Accumulator q;
  ACC_ZERO(q);

  return q;
}

Accumulator
productToQuire8_1RTL(Product productIn) {
  Accumulator q;
  ACC_ZERO(q);

  return q;
}

Accumulator
quirePositAdd8_1RTL(Product productIn,
                    Accumulator quireIn) {
  Accumulator q;
  ACC_ZERO(q);

  return q;
}

Accumulator
quireAdd8_1RTL(Accumulator quireA,
               Accumulator quireB) {
  Accumulator q;
  ACC_ZERO(q);

  return q;
}

FloatType
quireToPosit8_1RTL(Accumulator quireIn,
                   char adjustMul,
                   DeviceBool roundStochastic) {
  return (FloatType) 0;
}

Accumulator
quireDivide8_1RTL(Accumulator quireIn,
                  unsigned char div) {
  Accumulator q;
  ACC_ZERO(q);

  return q;
}
