// Copyright (c) Facebook, Inc. and its affiliates. All Rights Reserved.
// All rights reserved.
//
// This source code is licensed under the license found in the
// LICENSE file in the root directory of this source tree.

// Determines basic properties about a floating-point value
module FloatProperties #(parameter EXP=8,
                         parameter FRAC=23)
  (Float.InputIf in,
   output logic isInf,
   output logic isNan,
   output logic isZero,
   output logic isDenormal);

  initial begin
    assert(in.EXP == EXP);
    assert(in.FRAC == FRAC);
  end

  logic expZero;
  logic expMax;
  logic fracZero;

  always_comb begin
    expZero = in.data.exponent == EXP'(1'b0);
    expMax = in.data.exponent == {EXP{1'b1}};
    fracZero = in.data.fraction == FRAC'(1'b0);

    isInf = expMax && fracZero;
    isNan = expMax && !fracZero;
    isZero = expZero && fracZero;
    isDenormal = expZero && !fracZero;
  end
endmodule
