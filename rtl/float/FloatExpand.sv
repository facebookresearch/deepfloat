// Copyright (c) Facebook, Inc. and its affiliates. All Rights Reserved.
// All rights reserved.
//
// This source code is licensed under the license found in the
// LICENSE file in the root directory of this source tree.

// Expands a float of one width to one of a higher width
module FloatExpand #(parameter EXP_IN=3,
                     parameter FRAC_IN=4,
                     parameter EXP_OUT=8,
                     parameter FRAC_OUT=23)
  (Float.InputIf in,
   Float.OutputIf out,
   // exported for any interested parties
   output logic isInf,
   output logic isNan,
   output logic isZero,
   output logic isDenormal);

  localparam LOCAL_EXP_IN_BIAS = FloatDef::getExpBias(EXP_IN, FRAC_IN);
  localparam LOCAL_EXP_OUT_BIAS = FloatDef::getExpBias(EXP_OUT, FRAC_OUT);
  localparam EXP_BIAS_DIFF = LOCAL_EXP_OUT_BIAS - LOCAL_EXP_IN_BIAS;

  initial begin
    assert(in.EXP == EXP_IN);
    assert(in.FRAC == FRAC_IN);
    assert(out.EXP == EXP_OUT);
    assert(out.FRAC == FRAC_OUT);
    assert(EXP_IN <= EXP_OUT);
    assert(FRAC_IN <= FRAC_OUT);
    assert(LOCAL_EXP_IN_BIAS <= LOCAL_EXP_OUT_BIAS);
  end

  // For purposes of renormalizing denormal numbers, this is the numeric space
  // that we do it in
  localparam CLZ_COMPARE_BITS = Functions::getMax($clog2(FRAC_IN+1), EXP_OUT);

  // We might be denormal coming in, but might no longer be denormal going out
  logic isDenormalIn;

  FloatProperties #(.EXP(EXP_IN), .FRAC(FRAC_IN))
  properties(.in,
             .isInf,
             .isNan,
             .isZero,
             .isDenormal(isDenormalIn));

  // The fraction padded with zeros on the least significant end
  logic [FRAC_OUT-1:0] expandedFraction;

  always_comb begin
    // Write this first, in case FRAC_OUT == FRAC_IN (and thus we have a
    // zero-sized part)
    expandedFraction[FRAC_OUT-1:0] = FRAC_OUT'(1'b0);
    expandedFraction[FRAC_OUT-1:FRAC_OUT-1-(FRAC_IN-1)] = in.data.fraction;
  end

  generate
    if (EXP_IN < EXP_OUT) begin
      //
      // Denormals in the input exponent may no longer be denormal in the output
      // exponent, so we potentially need to renormalize
      //

      logic [EXP_OUT-1:0] expandedExp;

      // Number of leading zeros in the input fraction
      logic [$clog2(FRAC_IN+1)-1:0] clzFraction;

      CountLeadingZeros #(.WIDTH(FRAC_IN))
      clz(.in(in.data.fraction), .out(clzFraction));

      always_comb begin
        out.data.sign = in.data.sign;

        // Expand the exponent and fraction for manipulation
        expandedExp = EXP_OUT'(in.data.exponent) + EXP_OUT'(EXP_BIAS_DIFF);

        // We handle the one still denormal case below
        isDenormal = 1'b0;

        if (isInf) begin
          out.data.exponent = {EXP_OUT{1'b1}};
          out.data.fraction = expandedFraction;
        end else if (isNan) begin
          out.data.exponent = {EXP_OUT{1'b1}};
          // zero padding is fine
          out.data.fraction = expandedFraction;
        end else if (isZero) begin
          out.data.exponent = EXP_OUT'(1'b0);
          out.data.fraction = expandedFraction;
        end else if (isDenormalIn) begin
          // if clz < bias diff, we become normal
          if (CLZ_COMPARE_BITS'(clzFraction) < CLZ_COMPARE_BITS'(EXP_BIAS_DIFF)) begin
            out.data.exponent = expandedExp - EXP_OUT'(clzFraction);
            // Shift the leading 1 as well
            out.data.fraction = expandedFraction << (clzFraction + 1);
          end else begin
            // still denormal
            isDenormal = 1'b1;
            out.data.exponent = {EXP_OUT{1'b0}};
            // FIXME: this is not technically correct still; while the exponent
            // could increase significantly, we need to shift by the maximum
            // amount that our new exponent supports, not the clz
            out.data.fraction = expandedFraction << clzFraction;
          end
        end else begin
          // We are either denormal with equivalent exponent, or a normal number
          out.data.exponent = expandedExp;
          out.data.fraction = expandedFraction;
        end
      end
    end else begin
      //
      // Same exponent, but potentially different fraction that needs
      // zero-padding
      //

      always_comb begin
        out.data.sign = in.data.sign;
        out.data.exponent = in.data.exponent;
        out.data.fraction = expandedFraction;
        isDenormal = isDenormalIn;
      end
    end
  endgenerate
endmodule
