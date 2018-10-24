// Copyright (c) Facebook, Inc. and its affiliates. All Rights Reserved.
// All rights reserved.
//
// This source code is licensed under the license found in the
// LICENSE file in the root directory of this source tree.

// Contracts a float of one width to one of a lower width
// FIXME: add flag to skip denormal adjustment; denormals in the new width would
// flush to zero
module FloatContract #(parameter EXP_IN=8,
                       parameter FRAC_IN=23,
                       parameter EXP_OUT=8,
                       parameter FRAC_OUT=23,
                       parameter TRAILING_BITS=2,
                       parameter SATURATE_TO_MAX_FLOAT=0)
  (Float.InputIf in,
   Float.OutputIf out,
   output logic [TRAILING_BITS-1:0] trailingBitsOut,
   output logic stickyBitOut,
   output logic isNanOut);

  localparam LOCAL_EXP_IN_BIAS = FloatDef::getExpBias(EXP_IN, FRAC_IN);
  localparam LOCAL_EXP_OUT_BIAS = FloatDef::getExpBias(EXP_OUT, FRAC_OUT);

  // This is <= 0
  localparam EXP_BIAS_DIFF = LOCAL_EXP_OUT_BIAS - LOCAL_EXP_IN_BIAS;
  localparam ABS_EXP_BIAS_DIFF = -EXP_BIAS_DIFF;

  // Number of bits from the input fraction that we capture for sticky bits
  localparam STICKY_BIT_SIZE_DENORMAL =
     Functions::getMin(FRAC_IN,
                       Functions::getMax(ABS_EXP_BIAS_DIFF - TRAILING_BITS, 0));

  localparam STICKY_BIT_SIZE_NORMAL =
     Functions::getMax(FRAC_IN - FRAC_OUT - TRAILING_BITS, 0);

  initial begin
    assert(in.EXP == EXP_IN);
    assert(in.FRAC == FRAC_IN);
    assert(out.EXP == EXP_OUT);
    assert(out.FRAC == FRAC_OUT);

    assert(EXP_IN >= EXP_OUT);
    assert(FRAC_IN >= FRAC_OUT);
    assert(LOCAL_EXP_IN_BIAS >= LOCAL_EXP_OUT_BIAS);
    assert(ABS_EXP_BIAS_DIFF >= 0);
  end

  logic isInf;
  logic isNan;
  logic isZero;
  logic isSpecial;
  logic isDenormal;
  logic isDenormalInNewRegime;
  logic isInfInNewRegime;

  logic signed [EXP_IN:0] signedExpAdjust;

  FloatProperties #(.EXP(EXP_IN), .FRAC(FRAC_IN))
  properties(.in, .isInf, .isNan, .isZero, .isDenormal);

  // We take {leading, new frac size, trailing bits} from original; anything
  // else goes into the sticky bit
  logic [FRAC_OUT+TRAILING_BITS-1:0] inFractionSelect;
  logic inFractionStickyBit;

  PartSelect #(.IN_WIDTH(FRAC_IN),
               .START_IDX(FRAC_IN-1),
               .OUT_WIDTH(FRAC_OUT+TRAILING_BITS))
  fracOutPartSelect(.in(in.data.fraction),
                    .out(inFractionSelect));

  PartSelectReduceOr #(.IN_WIDTH(FRAC_IN),
                       .START_IDX(FRAC_IN-1-FRAC_OUT-TRAILING_BITS))
  fracOutStickyBitSelect(.in(in.data.fraction),
                         .out(inFractionStickyBit));

  // If we are denormal in the new regime, then we need to shift
  // inFractionSelect further to produce the proper trailing and sticky bits.
  logic [1+FRAC_OUT+TRAILING_BITS-1:0] denormalFraction;
  logic [EXP_IN+1-1:0] denormalShift;
  logic denormalSticky;

  // If we were denormal before, we will be denormal afterwards, so there is no
  // leading 1.
  // When we are denormal afterwards (either we were normal before or we are
  // becoming more denormal), this shift determines our new fraction, trailing
  // and sticky bits
  ShiftRightSticky #(.IN_WIDTH(1+FRAC_OUT+TRAILING_BITS),
                     .OUT_WIDTH(1+FRAC_OUT+TRAILING_BITS),
                     .SHIFT_VAL_WIDTH(EXP_IN))
  denormalShiftSticky(.in({~isDenormal, inFractionSelect}),
                      // can skip sign bit
                      .shift(denormalShift[EXP_IN-1:0]),
                      .out(denormalFraction),
                      .sticky(denormalSticky),
                      .stickyAnd());

  // If we are saturating to max float and we are already at max float, we do
  // not wish to produce any trailing/sticky bits, as a rounding unit could
  // cause us to round up.
  logic atMaxFloat;

  always_comb begin
    isSpecial = isInf || isNan || isZero;

    // This is the new exponent (without bias) in the new regime.
    // If this is <= 0, then we become zero or denormal.
    // If this is >= max exp, then we become inf.
    signedExpAdjust = signed'((EXP_IN+1)'(in.data.exponent)) +
                      (EXP_IN+1)'(signed'(EXP_BIAS_DIFF));

    isDenormalInNewRegime = signedExpAdjust <= signed'((EXP_IN+1)'(1'b0));
    isInfInNewRegime = signedExpAdjust >= signed'((EXP_IN+1)'({EXP_OUT{1'b1}}));

    // If signedExpAdjust is <= 0, then we are denormal in the new regime. We
    // need to re-align our fraction. If we were normal previously, then as a
    // denormal value has the same exponent as the first higher normal value, we
    // need to add one to the shift.
    // However, if we were previously denormal, we will still be denormal, so we
    // don't need to account for the extra shift.
    denormalShift = -signedExpAdjust + 1'(~isDenormal);

    // $display("old_dn %b new_dn %b isInfInNew %b signedExpAdjust %p DIFF %p",
    //          isDenormal,
    //          isDenormalInNewRegime,
    //          isInfInNewRegime,
    //          signedExpAdjust,
    //          ABS_EXP_BIAS_DIFF);

    // $display("denorm shift %p frac_in %b.%b -> %b.%b exp %p frac_out %b",
    //          denormalShift,
    //          ~isDenormal, in.data.fraction,
    //          1'b1, inFractionSelect,
    //          in.data.exponent,
    //          denormalFraction);

    if (SATURATE_TO_MAX_FLOAT) begin
      atMaxFloat = (signedExpAdjust[EXP_OUT-1:0] == {{(EXP_OUT-1){1'b1}}, 1'b0})
        && &inFractionSelect[FRAC_OUT+TRAILING_BITS-1-:FRAC_OUT];
    end

    isNanOut = isNan;

    unique if (isInf) begin
      out.data.exponent = {EXP_OUT{1'b1}};
      out.data.fraction = FRAC_OUT'(1'b0);
      out.data.sign = in.data.sign;
    end else if (isNan) begin
      out.data.exponent = {EXP_OUT{1'b1}};
      // don't bother preserving the NaN bits
      out.data.fraction = {1'b1, (FRAC_OUT-1)'(1'b0)};
      out.data.sign = in.data.sign;
    end else if (isZero) begin
      out.data.exponent = EXP_OUT'(1'b0);
      out.data.fraction = FRAC_OUT'(1'b0);
      out.data.sign = in.data.sign;
    end else begin
      if (isDenormalInNewRegime) begin
        // We are zero or denormal in the new regime
        out.data.exponent = EXP_OUT'(1'b0);
        // skip leading digit
        out.data.fraction = denormalFraction[FRAC_OUT+TRAILING_BITS-1-:FRAC_OUT];
        out.data.sign = in.data.sign;
      end else if (isInfInNewRegime) begin
        if (SATURATE_TO_MAX_FLOAT) begin
          // We saturate to the maximum float value
          out.data = out.getMax(in.data.sign);
        end else begin
          // We are inf in the new regime
          out.data = out.getInf(in.data.sign);
        end
      end else begin
        // We are representable in the new regime
        out.data.exponent = signedExpAdjust[EXP_OUT-1:0];
        out.data.fraction = inFractionSelect[FRAC_OUT+TRAILING_BITS-1-:FRAC_OUT];
        out.data.sign = in.data.sign;
      end
    end

    if (isSpecial || isInfInNewRegime || (SATURATE_TO_MAX_FLOAT && atMaxFloat)) begin
      // Even in the SATURATE_TO_MAX_FLOAT case, we don't produce bits since we
      // can't round up
      trailingBitsOut = TRAILING_BITS'(1'b0);
      stickyBitOut = 1'b0;
    end else if (isDenormalInNewRegime) begin
      trailingBitsOut = denormalFraction[FRAC_OUT+TRAILING_BITS-1-FRAC_OUT-:TRAILING_BITS];
      stickyBitOut = denormalSticky | inFractionStickyBit;
    end else begin
      // We provide these trailing bits even if we are saturating to max float,
      // and let the rounding module handle the saturation as well
      // FIXME: is this the right decision?
      trailingBitsOut = inFractionSelect[TRAILING_BITS-1:0];
      stickyBitOut = inFractionStickyBit;
    end
  end
endmodule
