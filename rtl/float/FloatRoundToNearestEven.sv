// Copyright (c) Facebook, Inc. and its affiliates. All Rights Reserved.
// All rights reserved.
//
// This source code is licensed under the license found in the
// LICENSE file in the root directory of this source tree.

// Receives 2 trailing bits from the source, plus the sticky bit
module FloatRoundToNearestEven #(parameter EXP=8,
                                 parameter FRAC=23)
  (Float.InputIf in,
   input [1:0] trailingBitsIn,
   input stickyBitIn,
   input isNanIn,
   Float.OutputIf out);

  initial begin
    assert(in.EXP == EXP);
    assert(in.FRAC == FRAC);
    assert(in.EXP == out.EXP);
    assert(in.FRAC == out.FRAC);
  end

  localparam FIRST_FRACTION_BIT = FRAC - 1;
  localparam LAST_FRACTION_BIT = 0;
  // These are provided in the trailing bits of the calculation
  localparam GUARD_BIT = 1;
  localparam ROUND_BIT = 0;

  logic roundDown;

  RoundToNearestEven r2ne(.keepBit(in.data.fraction[0]),
                          .trailingBits(trailingBitsIn),
                          .stickyBit(stickyBitIn),
                          .roundDown);

  logic [EXP+FRAC-1:0] expAndFraction;
  logic [EXP+FRAC-1:0] expAndFractionIncrement;

  always_comb begin
    expAndFraction = {in.data.exponent, in.data.fraction};
    expAndFractionIncrement = expAndFraction + !roundDown;

    out.data.sign = in.data.sign;
    // If the input was inf or NaN (we only set the leading 1 bit in the NaN
    // field), then the exponent field won't be rounded up, so this is safe
    out.data.exponent = expAndFractionIncrement[EXP+FRAC-1:FRAC];

    if (isNanIn) begin
      // The input may be +/-inf or NaN, just pass the fraction field through
      out.data.fraction = in.data.fraction;
    end else if (&out.data.exponent) begin
      // We rounded up/down to +/- inf
      out.data.fraction = FRAC'(1'b0);
    end else begin
      out.data.fraction = expAndFractionIncrement[FRAC-1:0];
    end
  end
endmodule
