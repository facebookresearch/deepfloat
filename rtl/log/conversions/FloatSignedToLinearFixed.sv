// Copyright (c) Facebook, Inc. and its affiliates. All Rights Reserved.
// All rights reserved.
//
// This source code is licensed under the license found in the
// LICENSE file in the root directory of this source tree.


// FIXME: implement overflow detection
module FloatSignedToLinearFixed #(parameter SIGNED_EXP=5,
                                  parameter FRAC=8,
                                  parameter ACC_NON_FRAC=16,
                                  parameter ACC_FRAC=16,
                                  parameter OVERFLOW_DETECTION=0)
  (FloatSigned.InputIf in,
   Kulisch.OutputIf out);

  initial begin
    assert(in.EXP == SIGNED_EXP);
    assert(in.FRAC == FRAC);

    assert(out.ACC_NON_FRAC == ACC_NON_FRAC);
    assert(out.ACC_FRAC == ACC_FRAC);

    // We only handle this case at the moment; no rounding or zero field handling
    assert(ACC_FRAC > FRAC);
  end

  localparam TOTAL_ACC = KulischDef::getBits(ACC_NON_FRAC, ACC_FRAC);

  logic [SIGNED_EXP-1:0] rightShift;
  logic isSpecial;
  logic [1+FRAC-1:0] fracLeading1;
  logic [1+FRAC-1:0] fracLeading1Signed;
  logic signed [TOTAL_ACC-1:0] totalExtended;
  logic sign;

  always_comb begin
    // in.data.frac and in.data.exp are garbage in case of isZero or isInf

    // To minimize shifter resources, consider the problem as arithmetic right
    // shift from the MSB
    // aka -in.data.exp + (ACC_NON_FRAC - 1);
    rightShift = ~in.data.exp + SIGNED_EXP'(ACC_NON_FRAC);

    isSpecial = in.data.isZero || in.data.isInf;
    sign = in.data.sign && !isSpecial;

    fracLeading1 = {!isSpecial, isSpecial ? FRAC'(1'b0) : in.data.frac};
    fracLeading1Signed = sign ? -fracLeading1 : fracLeading1;

    totalExtended = {sign, fracLeading1Signed, (TOTAL_ACC-(2+FRAC))'(1'b0)};

    out.data.bits = totalExtended >>> rightShift;
    out.data.isInf = in.data.isInf;
    out.data.isOverflow = 1'b0;
    out.data.overflowSign = 1'b0;
  end
endmodule
