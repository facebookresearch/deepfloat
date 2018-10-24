// Copyright (c) Facebook, Inc. and its affiliates. All Rights Reserved.
// All rights reserved.
//
// This source code is licensed under the license found in the
// LICENSE file in the root directory of this source tree.

module FloatToFloatSigned #(parameter EXP=8,
                            parameter FRAC=23,
                            parameter SIGNED_EXP=3,
                            parameter SIGNED_FRAC=8,
                            parameter SATURATE_MAX=1,
                            parameter DENORMALS=0)
  (Float.InputIf in,
   FloatSigned.OutputIf out);

  initial begin
    assert(in.EXP == EXP);
    assert(in.FRAC == FRAC);

    assert(out.EXP == SIGNED_EXP);
    assert(out.FRAC == SIGNED_FRAC);
  end

  // Determine the incoming float properties
  logic inIsInf;
  logic inIsNan;
  logic inIsZero;
  logic inIsDenormal;

  FloatProperties #(.EXP(EXP),
                    .FRAC(FRAC))
  fprop(.in(in),
        .isInf(inIsInf),
        .isNan(inIsNan),
        .isZero(inIsZero),
        .isDenormal(inIsDenormal));

  // For renormalization
  localparam DENORMAL_OFFSET_SIZE = $clog2(FRAC+1);

  logic [DENORMAL_OFFSET_SIZE-1:0] lzCount;
  logic [FRAC-1:0] renormalizedFrac;

  generate
    if (DENORMALS) begin
      CountLeadingZeros #(.WIDTH(FRAC),
                          .ADD_OFFSET(0))
      clz(.in(in.data.fraction),
          .out(lzCount));

      logic [FRAC-1:0] shiftedFrac;

      always_comb begin
        shiftedFrac = in.data.fraction << lzCount;
        // skip leading 1 if denormal
        renormalizedFrac = inIsDenormal ?
                           {shiftedFrac[FRAC-2:0], 1'b0} : in.data.fraction;
      end
    end else begin
      always_comb begin
        renormalizedFrac = in.data.fraction;
      end
    end
  endgenerate

  logic [SIGNED_FRAC-1:0] outFracRounded;
  logic expRoundUp;

  generate
    // Rounding is not required if SIGNED_FRAC >= FRAC
    if (SIGNED_FRAC < FRAC) begin
      // It is possible that we need to round the incoming float in order to fit
      // in the smaller fraction
      localparam TRAILING_BITS = 2;

      logic [SIGNED_FRAC-1:0] outFracUnrounded;
      logic [TRAILING_BITS-1:0] preRoundTrailingBits;
      logic preRoundStickyBit;

      TrailingStickySelect #(.IN_WIDTH(FRAC),
                             .FRAC(SIGNED_FRAC),
                             .TRAILING_BITS(TRAILING_BITS))
      tss(.in(renormalizedFrac),
          .frac(outFracUnrounded),
          .trailingBits(preRoundTrailingBits),
          .stickyBit(preRoundStickyBit));

      logic roundDown;

      RoundToNearestEven r2ne(.keepBit(outFracUnrounded[0]),
                              .trailingBits(preRoundTrailingBits),
                              .stickyBit(preRoundStickyBit),
                              .roundDown);

      logic [SIGNED_FRAC:0] outFracRoundedWithCarry;
      logic roundUp;

      always_comb begin
        roundUp = !roundDown;
        outFracRoundedWithCarry = {1'b0, outFracUnrounded} + roundUp;
        outFracRounded = outFracRoundedWithCarry[SIGNED_FRAC-1:0];
        expRoundUp = outFracRoundedWithCarry[SIGNED_FRAC];
      end
    end else begin
      // No rounding is required
      if (SIGNED_FRAC == FRAC) begin
        always_comb begin
          outFracRounded = renormalizedFrac;
          expRoundUp = 1'b0;
        end
      end else begin
        always_comb begin
          outFracRounded = {renormalizedFrac, (SIGNED_FRAC - FRAC)'(1'b0)};
          expRoundUp = 1'b0;
        end
      end
    end
  endgenerate

  // Signed float contains no denormals, and exp goes from
  // -2^(EXP - 1) to +2^(EXP - 1) - 1
  // e.g., 2^-128 to 2^127
  //
  // IEEE-style float contains denormals, and normal exp goes from
  // -2^(EXP - 1) + 1 to +2^(EXP - 1)
  // e.g., 2^-126 to 2^126

  // IEEE-style float would need (EXP + 1) bits to represent as signed, as
  // denormals can push us over
  // Signed float would need EXP bits to represent as signed
  // FIXME: if FRAC/DENORMAL_OFFSET_SIZE are huge, this isn't right
  localparam LARGER_EXP_SIZE = Functions::getMax(EXP + DENORMALS, SIGNED_EXP);

  logic signed [LARGER_EXP_SIZE-1:0] inSignedExp;
  logic expUnderflow;
  logic expOverflow;

  generate
    if (DENORMALS) begin
      always_comb begin
        inSignedExp = LARGER_EXP_SIZE'(in.getSignedExponent(in.data)) +
                      signed'(LARGER_EXP_SIZE'(expRoundUp)) -
                      (inIsDenormal ? signed'(LARGER_EXP_SIZE'(lzCount) + 1'b1) :
                       signed'(LARGER_EXP_SIZE'(1'b0)));

      end
    end else begin
      always_comb begin
        inSignedExp = LARGER_EXP_SIZE'(in.getSignedExponent(in.data)) +
                      signed'(LARGER_EXP_SIZE'(expRoundUp));
      end
    end
  endgenerate

  // We cannot underflow or overflow if our output exponent is exactly the same
  generate
    if (SIGNED_EXP >= EXP) begin
      always_comb begin
        expUnderflow = 1'b0;
        expOverflow = 1'b0;
      end
    end else begin
      always_comb begin
        expUnderflow = inSignedExp <
                       -(EXP+1)'(signed'(2 ** (SIGNED_EXP - 1)));
        expOverflow = inSignedExp >
                      (EXP+1)'(signed'(2 ** (SIGNED_EXP - 1) - 1));
      end
    end
  endgenerate

  always_comb begin
    out.data.sign = in.data.sign;
    out.data.isInf = inIsInf || inIsNan ||
                     (!SATURATE_MAX && expOverflow);
    out.data.isZero = !out.data.isInf &&
                      ((inIsZero || (!DENORMALS && inIsDenormal) ||
                        expUnderflow));
    if (SATURATE_MAX && expOverflow) begin
      out.data.exp = out.getMaxExp();
      out.data.frac = out.getMaxFrac();
    end else begin
      out.data.exp = SIGNED_EXP'(inSignedExp);
      out.data.frac = outFracRounded;
    end
  end
endmodule
