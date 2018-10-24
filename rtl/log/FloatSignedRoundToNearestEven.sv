// Copyright (c) Facebook, Inc. and its affiliates. All Rights Reserved.
// All rights reserved.
//
// This source code is licensed under the license found in the
// LICENSE file in the root directory of this source tree.

// Performs r2ne on a signed float
module FloatSignedRoundToNearestEven #(parameter EXP=8,
                                       parameter FRAC=23,
                                       parameter SATURATE_MAX=1)
  (FloatSigned.InputIf in,
   input [1:0] trailingBits,
   input stickyBit,
   FloatSigned.OutputIf out,
   output logic roundUp);

  initial begin
    assert(in.EXP == EXP);
    assert(in.FRAC == FRAC);
    assert(out.EXP == EXP);
    assert(out.FRAC == FRAC);
  end

  logic roundDown;

  RoundToNearestEven r2ne(.keepBit(in.data.frac[0]),
                          .trailingBits,
                          .stickyBit,
                          .roundDown);

  logic [EXP+FRAC-1:0] expAndFraction;
  logic [EXP+FRAC-1:0] expAndFractionIncrement;
  logic overflow;

  always_comb begin
    expAndFraction = {in.data.exp, in.data.frac};
    roundUp = !roundDown;
    expAndFractionIncrement = expAndFraction + roundUp;

    // The exponent portion is signed. We overflow if the exponent was
    // originally positive but becomes negative
    overflow = ~expAndFraction[EXP+FRAC-1] &&
               expAndFractionIncrement[EXP+FRAC-1];

    out.data.sign = in.data.sign;
    out.data.isInf = in.data.isInf || (!SATURATE_MAX && overflow);
    out.data.isZero = !out.data.isInf && in.data.isZero;
    // These can be garbage if isInf || isZero
    out.data.exp = (SATURATE_MAX && overflow) ?
                   {1'b0, {(EXP-1){1'b1}}} :
                   expAndFractionIncrement[EXP+FRAC-1-:EXP];
    out.data.frac = (SATURATE_MAX && overflow) ?
                    {FRAC{1'b1}} :
                    expAndFractionIncrement[FRAC-1:0];
  end
endmodule
