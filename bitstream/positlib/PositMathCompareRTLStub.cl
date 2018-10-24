// Copyright (c) Facebook, Inc. and its affiliates. All Rights Reserved.
// All rights reserved.
//
// This source code is licensed under the license found in the
// LICENSE file in the root directory of this source tree.


FloatType positMax8_1RTL(FloatType positA,
                         FloatType positB) {
  // don't implement for now
  bool aNeg = (positA & (unsigned char) 0x80);
  bool bNeg = (positB & (unsigned char) 0x80);

  if (aNeg && bNeg) {
    return positA < positB ? positA : positB;
  } else if (!aNeg && !bNeg) {
    return positA >= positB ? positA : positB;
  } else {
    return bNeg ? positA : positB;
  }
}

FloatType positMin8_1RTL(FloatType positA,
                         FloatType positB) {
  // don't implement for now
  return (FloatType) 0;
}

DeviceBool positComp8_1RTL(FloatType positA,
                           FloatType positB,
                           OpType comp) {
  // don't implement for now
  return (DeviceBool) 0;
}
