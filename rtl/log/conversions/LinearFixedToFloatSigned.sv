// Copyright (c) Facebook, Inc. and its affiliates. All Rights Reserved.
// All rights reserved.
//
// This source code is licensed under the license found in the
// LICENSE file in the root directory of this source tree.

// adjustExp is a signed value added to the returned exponent, so as to perform
// transparent adjustment
module LinearFixedToFloatSigned #(parameter ACC_NON_FRAC=16,
                                  parameter ACC_FRAC=16,
                                  parameter EXP=Functions::clog2(2+ // sign + clz
                                                                 KulischDef::getBits(ACC_NON_FRAC,
                                                                                     ACC_FRAC)-1),
                                  parameter FRAC=23,
                                  parameter TRAILING_BITS=2,
                                  parameter USE_ADJUST=0,
                                  parameter ADJUST_EXP_SIZE=1,
                                  parameter SATURATE_MAX=1)
  (Kulisch.InputIf in,
   input signed [ADJUST_EXP_SIZE-1:0] adjustExp,
   FloatSigned.OutputIf out,
   output logic [TRAILING_BITS-1:0] trailingBits,
   output logic stickyBit);

  initial begin
    assert(in.ACC_NON_FRAC == ACC_NON_FRAC);
    assert(in.ACC_FRAC == ACC_FRAC);

    assert(out.EXP == EXP);
    assert(out.FRAC == FRAC);
  end

  localparam TOTAL_ACC = KulischDef::getBits(ACC_NON_FRAC, ACC_FRAC);

  logic sign;

  logic [TOTAL_ACC-1:0] absAcc;
  logic [TOTAL_ACC-2:0] absAccNoSignBit;

  // TOTAL_ACC-1+1+1 includes ADD_OFFSET and allows the value to be this exact
  // result
  localparam LZ_COUNT_BITS = $clog2(TOTAL_ACC-1+1+1);

  logic [LZ_COUNT_BITS-1:0] lzCount;

  CountLeadingZeros #(.WIDTH(TOTAL_ACC-1),
                      .ADD_OFFSET(1))
  clz(.in(absAccNoSignBit),
      .out(lzCount));

  logic [TOTAL_ACC-2:0] shiftedAcc;

  // Part selection for rounding
  logic [FRAC-1:0] outFrac;
  logic [TRAILING_BITS-1:0] normalTrailingBits;
  logic normalStickyBit;

  TrailingStickySelect #(.IN_WIDTH(TOTAL_ACC-1),
                         .FRAC(FRAC),
                         .TRAILING_BITS(TRAILING_BITS))
  tss(.in(shiftedAcc),
      .frac(outFrac),
      .trailingBits(normalTrailingBits),
      .stickyBit(normalStickyBit));

  // Adjustment factor in the same regime as the exponent
  logic signed [EXP-1:0] adjustAsExp;

  // The exponent, unadjusted
  logic signed [EXP-1:0] expUnadjusted;

  // The final exponent, adjusted
  logic signed [EXP-1:0] expAdjusted;

  // Whether or not the post-adjustment exponent underflows
  logic expAdjustUnderflow;

  // Whether or not the post-adjustment exponent overflows
  logic expAdjustOverflow;

  // If we are in overflow (either because the input was in overflow or the
  // adjusted exponent overflows), this is the sign
  logic overflowSign;

  always_comb begin
    sign = in.getSign(in.data);

    // fraction
    absAcc = sign ? -in.data.bits : in.data.bits;
    absAccNoSignBit = absAcc[ACC_NON_FRAC+ACC_FRAC-1:0];
    shiftedAcc = absAccNoSignBit << lzCount;

    // FIXME: is this big enough?
    expUnadjusted = EXP'(ACC_NON_FRAC) - lzCount;

    if (USE_ADJUST) begin
      adjustAsExp = EXP'(adjustExp);
      expAdjusted = expUnadjusted + adjustAsExp;

      // Underflow if we went from neg -> pos, and the adjustment is negative
      expAdjustUnderflow = expUnadjusted[EXP-1] &&
                           ~expAdjusted[EXP-1] &&
                           adjustAsExp[EXP-1];

      // Overflow if we went from pos -> neg, and the adjustment is positive
      expAdjustOverflow = ~expUnadjusted[EXP-1] &&
                          expAdjusted[EXP-1] &&
                          ~adjustAsExp[EXP-1];

    end else begin
      expAdjusted = expUnadjusted;
      expAdjustUnderflow = 1'b0;
      expAdjustOverflow = 1'b0;
    end

    overflowSign = in.data.isOverflow ?
                   in.data.overflowSign :
                   (expAdjustOverflow ? sign : 1'b0);

    if (in.data.isInf ||
        ((in.data.isOverflow || expAdjustOverflow)
         && !SATURATE_MAX)) begin
      out.data = out.inf(overflowSign);

      trailingBits = TRAILING_BITS'(1'b0);
      stickyBit = 1'b0;
    end else if ((in.data.isOverflow || expAdjustOverflow) &&
                 SATURATE_MAX) begin
      out.data = out.getMax(overflowSign);

      trailingBits = TRAILING_BITS'(1'b0);
      stickyBit = 1'b0;
    end else begin
      out.data.sign = sign;
      out.data.isInf = 1'b0;
      out.data.isZero = expAdjustUnderflow || ~(|absAccNoSignBit);
      out.data.exp = expAdjusted;
      out.data.frac = outFrac;

      trailingBits = normalTrailingBits;
      stickyBit = normalStickyBit;
    end

    // $display("prod %s %b %b", out.print(out.data), expAdjustUnderflow,
    // expAdjustOverflow);
    // $display("exp %b %b %b",
    //          expUnadjusted, EXP'(adjustExp), expAdjusted);
  end
endmodule
