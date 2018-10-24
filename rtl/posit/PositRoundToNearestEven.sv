// Copyright (c) Facebook, Inc. and its affiliates. All Rights Reserved.
// All rights reserved.
//
// This source code is licensed under the license found in the
// LICENSE file in the root directory of this source tree.

// In the case that zero is passed, the keep bit is by definition zero, but the
// trailing and sticky bits may be non-zero, in which case we may round up to
// the minimum posit.
module PositRoundToNearestEven #(parameter WIDTH=8,
                                 parameter ES=1)
  (PositUnpacked.InputIf in,
   input [1:0] trailingBits,
   input stickyBit,
   PositUnpacked.OutputIf out);

  initial begin
    assert(in.WIDTH == out.WIDTH);
    assert(in.WIDTH == WIDTH);
    assert(in.ES == out.ES);
    assert(in.ES == ES);
  end

  localparam TRAILING_BITS = 2;

  localparam LOCAL_MAX_UNSIGNED_REGIME = PositDef::getMaxUnsignedRegime(WIDTH,
                                                                        ES);
  localparam LOCAL_UNSIGNED_EXPONENT_BITS = PositDef::getUnsignedExponentBits(WIDTH,
                                                                              ES);
  localparam LOCAL_MAX_UNSIGNED_EXPONENT = PositDef::getMaxUnsignedExponent(WIDTH,
                                                                            ES);
  localparam LOCAL_UNSIGNED_REGIME_BITS = PositDef::getUnsignedRegimeBits(WIDTH,
                                                                          ES);
  localparam LOCAL_FRACTION_BITS = PositDef::getFractionBits(WIDTH, ES);

  localparam SHIFT_ROUND_SIZE = 1 + // overflow bit
                                ES +
                                LOCAL_FRACTION_BITS;

  // Output from the round helper
  logic [SHIFT_ROUND_SIZE+TRAILING_BITS-1:0] postShift;
  logic [LOCAL_UNSIGNED_REGIME_BITS-1-1:0] excessRegimeBits;
  logic roundStickyBit;

  PositRoundHelper #(.WIDTH(WIDTH),
                     .ES(ES),
                     .TRAILING_BITS(TRAILING_BITS))
  roundHelper(.in,
              .inTrailingBits(trailingBits),
              .inStickyBit(stickyBit),
              .postShift,
              .excessRegimeBits,
              .outStickyBit(roundStickyBit));

  // Round logic
  logic roundDown;

  RoundToNearestEven r2ne(.keepBit(postShift[2]),
                          .trailingBits(postShift[1:0]),
                          .stickyBit(roundStickyBit),
                          .roundDown);

  logic zeroRoundUp;
  logic overflow;
  logic [LOCAL_UNSIGNED_REGIME_BITS-1:0] roundUnsignedRegime;
  logic [SHIFT_ROUND_SIZE-1:0] postShiftRound;
  logic [LOCAL_UNSIGNED_EXPONENT_BITS-1:0] postRoundExponent;

  // The (es, fraction) realigned
  logic [SHIFT_ROUND_SIZE-1:0] reShift;

  ShiftLeft #(.WIDTH(SHIFT_ROUND_SIZE),
              .SHIFT_VAL_WIDTH(LOCAL_UNSIGNED_REGIME_BITS-1))
  sl(.in(postShiftRound),
     .shift(excessRegimeBits),
     .out(reShift));

  // Handle ES = 0 case where there are no ES bits
  generate
    if (ES == 0) begin
      assign postRoundExponent = {roundUnsignedRegime};
    end
    else begin
      assign postRoundExponent = {roundUnsignedRegime, reShift[SHIFT_ROUND_SIZE-2-:ES]};
    end
  endgenerate

  always_comb begin
    postShiftRound = postShift[SHIFT_ROUND_SIZE+TRAILING_BITS-1:TRAILING_BITS] +
                     !roundDown;

    // Increment the regime if there was a carry in the round increment above
    roundUnsignedRegime = in.unsignedRegime(in.data) + reShift[SHIFT_ROUND_SIZE-1];
    overflow = roundUnsignedRegime >= LOCAL_MAX_UNSIGNED_REGIME;

    // If we have a zero, we may still round up in these cases, as the keep
    // bit is by definition 0:
    // x | 1 0 1 : round up
    // x | 1 1 0 : round up
    // x | 1 1 1 : round up
    zeroRoundUp = in.data.isZero &&
                  // We use the original input trailing and sticky bits
                  (trailingBits[1] && (trailingBits[0] || stickyBit));

    out.data.sign = in.data.sign;
    out.data.isZero = in.data.isZero && !zeroRoundUp;
    out.data.isInf = in.data.isInf;
    out.data.exponent = (in.data.isZero || in.data.isInf) ?
                        LOCAL_UNSIGNED_EXPONENT_BITS'(1'b0) :
                        (overflow ?
                         LOCAL_UNSIGNED_EXPONENT_BITS'(LOCAL_MAX_UNSIGNED_EXPONENT) :
                         postRoundExponent);
    out.data.fraction = (overflow || in.data.isZero || in.data.isInf) ?
                        LOCAL_FRACTION_BITS'(1'b0) :
                        reShift[LOCAL_FRACTION_BITS-1:0];
  end
endmodule
