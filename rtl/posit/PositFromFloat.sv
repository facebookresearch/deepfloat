// Copyright (c) Facebook, Inc. and its affiliates. All Rights Reserved.
// All rights reserved.
//
// This source code is licensed under the license found in the
// LICENSE file in the root directory of this source tree.

// This produces a non-rounded unpacked posit (i.e., the exponent and fraction
// are not truncated based on the posit representation).
module PositFromFloat #(parameter POSIT_WIDTH=8,
                        parameter POSIT_ES=1,
                        parameter FLOAT_EXP=8,
                        parameter FLOAT_FRAC=23,
                        parameter TRAILING_BITS=2,
                        parameter FTZ_DENORMAL=0,
                        parameter EXP_ADJUST_BITS=1,
                        parameter EXP_ADJUST=0)
  (Float.InputIf in,
   input logic signed [EXP_ADJUST_BITS-1:0] expAdjust,
   PositUnpacked.OutputIf out,
   output logic [TRAILING_BITS-1:0] trailingBits,
   output logic stickyBit);

  initial begin
    assert(in.EXP == FLOAT_EXP);
    assert(in.FRAC == FLOAT_FRAC);
    assert(out.WIDTH == POSIT_WIDTH);
    assert(out.ES == POSIT_ES);
  end

  localparam LOCAL_FLOAT_EXP_BIAS = FloatDef::getExpBias(FLOAT_EXP, FLOAT_FRAC);
  localparam LOCAL_FLOAT_MIN_SIGNED_NORMAL_EXP =
                                                FloatDef::getMinSignedNormalExp(FLOAT_EXP,
                                                                                FLOAT_FRAC);

  localparam LOCAL_POSIT_EXP_BIAS = PositDef::getExponentBias(POSIT_WIDTH,
                                                              POSIT_ES);
  localparam LOCAL_POSIT_FRACTION_BITS = PositDef::getFractionBits(POSIT_WIDTH,
                                                                   POSIT_ES);
  localparam LOCAL_POSIT_SIGNED_EXP_BITS = PositDef::getSignedExponentBits(POSIT_WIDTH,
                                                                           POSIT_ES);
  localparam LOCAL_POSIT_UNSIGNED_EXP_BITS = PositDef::getUnsignedExponentBits(POSIT_WIDTH,
                                                                               POSIT_ES);
  localparam LOCAL_POSIT_MIN_SIGNED_EXP = PositDef::getMinSignedExponent(POSIT_WIDTH,
                                                                         POSIT_ES);
  localparam LOCAL_POSIT_MAX_SIGNED_EXP = PositDef::getMaxSignedExponent(POSIT_WIDTH,
                                                                         POSIT_ES);
  localparam LOCAL_POSIT_MAX_UNSIGNED_EXP = PositDef::getMaxUnsignedExponent(POSIT_WIDTH,
                                                                             POSIT_ES);

  // We need to determine if the float's exponent is representable in posit
  // form. Either the float or the posit could have a larger max exponent;
  // expand to the form.
  // A denormal float will have a lower exponent (thus wider range) as well,
  // include this in the calculation.
  // If we are adjusting the exponent of the input, we add an additional bit to
  // this to prevent overflow
  // FIXME: really the number of bits added should be based on the max/min value
  // of the exponent plus the max/min value of expAdjust
  localparam MAX_SIGNED_EXP_BITS = $clog2(FLOAT_FRAC + 2) +
                                   Functions::getMax(LOCAL_POSIT_SIGNED_EXP_BITS,
                                                     FLOAT_EXP) +
                                   (EXP_ADJUST ? 1 : 0);

  // This is the larger of the maximum posit and float fraction field
  // representations
  localparam MAX_FRAC_BITS = Functions::getMax(LOCAL_POSIT_FRACTION_BITS, FLOAT_FRAC);

  // Signed exponent of the input
  logic signed [MAX_SIGNED_EXP_BITS-1:0] floatExp;

  // Unsigned exponent with posit bias
  logic [MAX_SIGNED_EXP_BITS-1:0] positExpUnsigned;

  // This is the input fraction extended to the larger of the two possible
  // fraction representations
  logic [MAX_FRAC_BITS-1:0] extendedFrac;

  // If the input float is denormal, we need to renormalize
  logic [MAX_FRAC_BITS-1:0] normalizedFrac;

  // Count of leading zeros for denormal renormalization
  logic [$clog2(MAX_FRAC_BITS+2)-1:0] lzCount;

  // In case of underflow, this is by how far it will underflow
  logic signed [MAX_SIGNED_EXP_BITS-1:0] underflowExpAmount;

  // In case of underflow, these are the trailing and sticky bits
  logic [TRAILING_BITS-1:0] underflowTrailingBits;
  logic underflowStickyBit;

  // For non-over/underflow and non-special values, these are the extracted
  // trailing and sticky bits
  logic [TRAILING_BITS-1:0] normalTrailingBits;
  logic normalStickyBit;

  // Float is zero
  logic isZero;

  // Float is +/- inf
  logic isInf;

  // Float is a NaN
  logic isNan;

  // Float is denormal
  logic isDenormal;

  // Float value is too small
  logic isUnderflow;

  // Float value is too large
  logic isOverflow;

  // Determine nan/denormal/inf/etc.
  FloatProperties #(.EXP(FLOAT_EXP), .FRAC(FLOAT_FRAC))
  fp(.*);

  // If the input float is denormal, we need to renormalize the float to be
  // aligned at the leading 1
  // i.e., 1.bbbb, where bbbb is the fraction post-shift, thus we add 1 to move
  // the leading 1.
  // lzCount is not used if FTZ_DENORMAL is true
  CountLeadingZeros #(.WIDTH(MAX_FRAC_BITS),
                      .ADD_OFFSET(1))
  clz(.in(extendedFrac),
      .out(lzCount));

  // If the float will underflow as a posit, there still may be meaningful
  // trailing and sticky bits that need to be preserved, as the value could be
  // rounded up based on the rounding function.
  // This handles producing these bits.
  // If FTZ_DENORMAL, then this is ignored
  ShiftRightSticky #(.IN_WIDTH(MAX_FRAC_BITS),
                     .OUT_WIDTH(TRAILING_BITS),
                     // FIXME: we are guaranteed to be unsigned
                     .SHIFT_VAL_WIDTH(MAX_SIGNED_EXP_BITS))
  srs(.in(normalizedFrac),
      .shift(underflowExpAmount),
      .out(underflowTrailingBits),
      .sticky(underflowStickyBit),
      .stickyAnd());

  // Regardless of field size, this extracts the trailing and sticky bits
  // Our trailing bits begin at MAX_FRAC_BITS-LOCAL_POSIT_FRACTION_BITS-1
  PartSelect #(.IN_WIDTH(MAX_FRAC_BITS),
               .START_IDX(MAX_FRAC_BITS-LOCAL_POSIT_FRACTION_BITS-1),
               .OUT_WIDTH(TRAILING_BITS))
  trSelect(.in(normalizedFrac),
           .out(normalTrailingBits));

  // This handles producing the sticky bits, if any
  PartSelectReduceOr #(.IN_WIDTH(MAX_FRAC_BITS),
                       .START_IDX(MAX_FRAC_BITS-LOCAL_POSIT_FRACTION_BITS-1-
                                  TRAILING_BITS))
  sbSelect(.in(normalizedFrac),
           .out(normalStickyBit));

  // We need to keep track of any trailing bits post-shift
  ZeroPadRight #(.IN_WIDTH(FLOAT_FRAC),
                 .OUT_WIDTH(MAX_FRAC_BITS))
  zpr(.in(in.data.fraction),
      .out(extendedFrac));

  always_comb begin
    if (FTZ_DENORMAL) begin
      // Any denormal values get flushed to zero
      normalizedFrac = isDenormal ? MAX_FRAC_BITS'(1'b0) : extendedFrac;

      // This is for detecting underflow or overflow; we don't care about
      // underflow as this gets flushed to zero
      if (EXP_ADJUST) begin
        floatExp = signed'(MAX_SIGNED_EXP_BITS'(in.data.exponent)) -
                   signed'(MAX_SIGNED_EXP_BITS'(LOCAL_FLOAT_EXP_BIAS)) +
                   MAX_SIGNED_EXP_BITS'(expAdjust);

      end else begin
        floatExp = signed'(MAX_SIGNED_EXP_BITS'(in.data.exponent)) -
                   signed'(MAX_SIGNED_EXP_BITS'(LOCAL_FLOAT_EXP_BIAS));
      end
    end else begin
      // We have to adjust the fraction if it is denormalized
      normalizedFrac = isDenormal ? (extendedFrac << lzCount) : extendedFrac;

      // This is for detecting underflow or overflow
      if (EXP_ADJUST) begin
        floatExp = (isDenormal ?
                    (signed'(MAX_SIGNED_EXP_BITS'(LOCAL_FLOAT_MIN_SIGNED_NORMAL_EXP)) -
                     signed'(MAX_SIGNED_EXP_BITS'(lzCount))) :
                    (signed'(MAX_SIGNED_EXP_BITS'(in.data.exponent)) -
                     signed'(MAX_SIGNED_EXP_BITS'(LOCAL_FLOAT_EXP_BIAS)))) +
                   MAX_SIGNED_EXP_BITS'(expAdjust);
      end else begin
        floatExp = isDenormal ?
                   (signed'(MAX_SIGNED_EXP_BITS'(LOCAL_FLOAT_MIN_SIGNED_NORMAL_EXP)) -
                    signed'(MAX_SIGNED_EXP_BITS'(lzCount))) :
                   (signed'(MAX_SIGNED_EXP_BITS'(in.data.exponent)) -
                    signed'(MAX_SIGNED_EXP_BITS'(LOCAL_FLOAT_EXP_BIAS)));
      end
    end

    // This is the resulting posit exponent, if we are not in underflow or overflow
    positExpUnsigned = unsigned'(floatExp + signed'(MAX_SIGNED_EXP_BITS'(LOCAL_POSIT_EXP_BIAS)));

    underflowExpAmount = signed'(MAX_SIGNED_EXP_BITS'(LOCAL_POSIT_MIN_SIGNED_EXP)) - floatExp;

    if (FTZ_DENORMAL) begin
      // When denormal, we go straight to zero
      isUnderflow = isDenormal;
    end else begin
      isUnderflow = floatExp < signed'(MAX_SIGNED_EXP_BITS'(LOCAL_POSIT_MIN_SIGNED_EXP));
    end

    isOverflow = floatExp > signed'(MAX_SIGNED_EXP_BITS'(LOCAL_POSIT_MAX_SIGNED_EXP));

    out.data.isZero = isZero || isUnderflow;
    out.data.isInf = isInf || isNan;
    out.data.sign = isInf ? 1'b0 : in.data.sign;

    // exponent
    if (isInf || isNan || isZero || isUnderflow) begin
      out.data.exponent = LOCAL_POSIT_UNSIGNED_EXP_BITS'(1'b0);
    end else if (isOverflow) begin
      // return max
      out.data.exponent = LOCAL_POSIT_UNSIGNED_EXP_BITS'(LOCAL_POSIT_MAX_UNSIGNED_EXP);
    end else begin
      out.data.exponent = positExpUnsigned[LOCAL_POSIT_UNSIGNED_EXP_BITS-1:0];
    end

    // fraction
    if (isInf || isNan || isZero || isUnderflow || isOverflow) begin
      out.data.fraction = {LOCAL_POSIT_FRACTION_BITS{1'b0}};
    end else begin
      out.data.fraction = normalizedFrac[(MAX_FRAC_BITS-1)-:
                                         LOCAL_POSIT_FRACTION_BITS];
    end

    // trailing and sticky
    if (isInf || isNan || isZero || isOverflow) begin
      trailingBits = TRAILING_BITS'(1'b0);
      stickyBit = 1'b0;
    end else if (isUnderflow) begin
      if (FTZ_DENORMAL) begin
        trailingBits = TRAILING_BITS'(1'b0);
        stickyBit = 1'b0;
      end else begin
        trailingBits = underflowTrailingBits;
        stickyBit = underflowStickyBit;
      end
    end else begin
      trailingBits = normalTrailingBits;
      stickyBit = normalStickyBit;
    end
  end
endmodule
