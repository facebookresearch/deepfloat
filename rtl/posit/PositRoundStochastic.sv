// Copyright (c) Facebook, Inc. and its affiliates. All Rights Reserved.
// All rights reserved.
//
// This source code is licensed under the license found in the
// LICENSE file in the root directory of this source tree.

module PositRoundStochastic #(parameter WIDTH=8,
                              parameter ES=1,
                              parameter TRAILING_BITS=8)
  (PositUnpacked.InputIf in,
   input [TRAILING_BITS-1:0] trailingBits,
   input stickyBit,
   // We provide as many bits as we have trailing bits + the sticky bit to
   // determine rounding
   // FIXME: do we want to parameterize this separately?
   input [TRAILING_BITS+1-1:0] randomBits,
   PositUnpacked.OutputIf out);

  initial begin
    assert(in.WIDTH == out.WIDTH);
    assert(in.WIDTH == WIDTH);
    assert(in.ES == out.ES);
    assert(in.ES == ES);
  end

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

  // To determine whether or not we round up, we determine if a carry is
  // generated (would a comparator be faster? for which processes?)
  // carry + trailing + sticky
  localparam CARRY_BITS = 1 + TRAILING_BITS + 1;

  logic [CARRY_BITS-1:0] checkRound;

  // Whether or not we round up (generated based on the carry above)
  logic roundUp;
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
    // To determine whether or not we round up, we check for a carry with our
    // random bits
    // This is the same round up flag for the input zero case as well
    checkRound = {1'b0, postShift[TRAILING_BITS-1:0], roundStickyBit} +
                 {1'b0, randomBits};
    roundUp = checkRound[CARRY_BITS-1];

    postShiftRound = postShift[SHIFT_ROUND_SIZE+TRAILING_BITS-1:TRAILING_BITS] +
                     roundUp;

    // Increment the regime if there was a carry in the round increment above
    roundUnsignedRegime = in.unsignedRegime(in.data) + reShift[SHIFT_ROUND_SIZE-1];
    overflow = roundUnsignedRegime >= LOCAL_MAX_UNSIGNED_REGIME;

    out.data.sign = in.data.sign;
    // Zero can round up to the minimum value
    out.data.isZero = in.data.isZero && !roundUp;
    out.data.isInf = in.data.isInf;
    // Zero can round up to the minimum value, which still results in a biased
    // exponent of 0
    out.data.exponent = (in.data.isZero || in.data.isInf) ?
                        LOCAL_UNSIGNED_EXPONENT_BITS'(1'b0) :
                        (overflow ?
                         LOCAL_UNSIGNED_EXPONENT_BITS'(LOCAL_MAX_UNSIGNED_EXPONENT) :
                         postRoundExponent);
    // Zero can round up to the minimum value, which still results in a zero
    // fraction (there's an implicit leading 1)
    out.data.fraction = (overflow || in.data.isZero || in.data.isInf) ?
                        LOCAL_FRACTION_BITS'(1'b0) :
                        reShift[LOCAL_FRACTION_BITS-1:0];
  end
endmodule
