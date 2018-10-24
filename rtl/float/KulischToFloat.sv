// Copyright (c) Facebook, Inc. and its affiliates. All Rights Reserved.
// All rights reserved.
//
// This source code is licensed under the license found in the
// LICENSE file in the root directory of this source tree.

// FIXME: no denormal handling
module KulischToFloat #(parameter ACC_NON_FRAC=16,
                        parameter ACC_FRAC=16,
                        parameter EXP=8,
                        parameter FRAC=23,
                        parameter SATURATE_MAX=1)
  (Kulisch.InputIf in,
   Float.OutputIf out);

  initial begin
    assert(in.ACC_NON_FRAC == ACC_NON_FRAC);
    assert(in.ACC_FRAC == ACC_FRAC);

    assert(out.EXP == EXP);
    assert(out.FRAC == FRAC);
  end

  localparam TOTAL_ACC = 1 + ACC_NON_FRAC + ACC_FRAC;

  logic sign;

  logic [TOTAL_ACC-1:0] absAcc;
  logic [TOTAL_ACC-2:0] absAccNoSignBit;

  localparam LZ_COUNT_BITS = $clog2(TOTAL_ACC-1+1+1);

  logic [LZ_COUNT_BITS-1:0] lzCount;

  CountLeadingZeros #(.WIDTH(TOTAL_ACC-1),
                      .ADD_OFFSET(1))
  clz(.in(absAccNoSignBit),
      .out(lzCount));

  logic [TOTAL_ACC-2:0] shiftedAcc;
  logic [FRAC-1:0] fracOut;

  PartSelect #(.IN_WIDTH(TOTAL_ACC-1),
               .START_IDX(TOTAL_ACC-2),
               .OUT_WIDTH(FRAC))
  ps(.in(shiftedAcc),
     .out(fracOut));

  logic signed [EXP-1:0] signedExp;

  always_comb begin
    sign = in.getSign(in.data);
    absAcc = sign ? -in.data.bits : in.data.bits;
    absAccNoSignBit = absAcc[ACC_NON_FRAC+ACC_FRAC-1:0];

    shiftedAcc = absAccNoSignBit << lzCount;

    // FIXME: we aren't checking to see if EXP is big enough
    signedExp = (EXP)'(ACC_NON_FRAC) - lzCount;

    if (in.data.isInf || (!SATURATE_MAX && in.data.isOverflow)) begin
      out.data = out.getInf(1'b0);
    end else if (SATURATE_MAX && in.data.isOverflow) begin
      out.data = out.getMax(in.data.overflowSign);
    end else if (lzCount == LZ_COUNT_BITS'(TOTAL_ACC)) begin
      out.data = out.getZero(1'b0);
    end else begin
      out.data.sign = sign;
      out.data.exponent = signedExp + FloatDef::getExpBias(EXP, FRAC);
      out.data.fraction = fracOut;
    end
  end
endmodule
