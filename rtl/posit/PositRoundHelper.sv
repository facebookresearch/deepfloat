// Copyright (c) Facebook, Inc. and its affiliates. All Rights Reserved.
// All rights reserved.
//
// This source code is licensed under the license found in the
// LICENSE file in the root directory of this source tree.

// Round helper for posits that performs the proper fraction/ES truncation based
// on exponent, so we can determine the bits that need rounding (for arithmetic
// or geometric rounding)
module PositRoundHelper #(parameter WIDTH=8,
                          parameter ES=1,
                          parameter TRAILING_BITS=2)
  (PositUnpacked.InputIf in,
   input [TRAILING_BITS-1:0] inTrailingBits,
   input inStickyBit,
   // The adjusted (ES, fraction) with possible space for ES overflow
   // FIXME: remove ES overflow bit
   // This is (0, ES, fraction) right shifted by excessRegimeBits
   output logic [1 + ES + PositDef::getFractionBits(WIDTH, ES) + TRAILING_BITS-1:0] postShift,
   // We assume the regime always takes two bits in the encoding. This determines
   // how many more bits we need to shift. This is also the number of bits that
   // postShift has been shifted right
   output logic [PositDef::getUnsignedRegimeBits(WIDTH, ES)-2:0] excessRegimeBits,

   // The resulting sticky bit from the shift
   output logic outStickyBit);

  localparam LOCAL_UNSIGNED_EXPONENT_BITS = PositDef::getUnsignedExponentBits(WIDTH, ES);
  localparam LOCAL_UNSIGNED_REGIME_BITS = PositDef::getUnsignedRegimeBits(WIDTH,
  ES);
  localparam LOCAL_SIGNED_REGIME_BITS = PositDef::getSignedRegimeBits(WIDTH,
  ES);
  localparam LOCAL_FRACTION_BITS = PositDef::getFractionBits(WIDTH, ES);

   initial begin
    assert(in.WIDTH == WIDTH);
    assert(in.ES == ES);
  end

  localparam SHIFT_ROUND_SIZE = 1 + // overflow bit
                                ES +
                                LOCAL_FRACTION_BITS;

  logic [LOCAL_UNSIGNED_REGIME_BITS-1:0] unsignedRegime;
  logic signed [LOCAL_SIGNED_REGIME_BITS-1:0] signedRegime;
  logic [SHIFT_ROUND_SIZE+TRAILING_BITS-1:0] preShift;
  logic postShiftSticky;

  //
  // General algorithm:
  // We have a fixed bit width exponent / fraction which may or may not overflow
  // in a posit representation.
  //
  // If the exponent is within bounds, it is still possible that some (or all)
  // of the fraction bits will be truncated, or some (or all) of the ES bits
  // will be truncated.
  //
  // Based on the exponent, we determine whether or not overflow will occur, and
  // we determine how many of the [ES, fraction] bits will go away.
  // No truncation happens if the regime takes 2 bits, which is the minimum.
  // Any additional regime bit results in truncation.
  // excessRegimeBits is the number of bits that we need to truncate and shift
  // by.
  //

  ShiftRightSticky #(.IN_WIDTH(SHIFT_ROUND_SIZE+TRAILING_BITS),
                     .OUT_WIDTH(SHIFT_ROUND_SIZE+TRAILING_BITS),
                     .SHIFT_VAL_WIDTH(LOCAL_UNSIGNED_REGIME_BITS-1))
  srs(.in(preShift),
      .shift(excessRegimeBits),
      .out(postShift),
      .sticky(postShiftSticky),
      .stickyAnd());

  generate
    if (ES == 0) begin
      assign preShift = {1'b0, in.data.fraction, inTrailingBits};
    end
    else begin
      assign preShift = {1'b0, in.data.exponent[ES-1:0], in.data.fraction, inTrailingBits};
    end
  endgenerate

  initial begin
    assert(LOCAL_UNSIGNED_EXPONENT_BITS - ES == LOCAL_UNSIGNED_REGIME_BITS);
  end

  always_comb begin
    unsignedRegime = in.unsignedRegime(in.data);
    signedRegime = in.signedRegime(in.data);

    // The FRACTION_BITS is based on the maximum possible fraction size, that is
    // N - 3. Any regime encoding with more than 2 bits will truncate the
    // fraction and/or ES.

    // Example:
    // encoding 0000 0001 001x 01xx 10xx 110x 1110 1111
    // sgn regime  x   -3   -2   -1    0    1    2    3
    // uns regime  x    0    1    2    3    4    5    6
    // regime bits 4    4    3    2    2    3    4    4
    // exc bits    x    2    1    0    0    1    2    3(*)
    // FIXME: (*) not true for max regime. Does this matter?

    excessRegimeBits = signedRegime >= 0 ?
                       unsigned'(signedRegime[LOCAL_SIGNED_REGIME_BITS-2:0]) :
                       // Subtract 1 from the signed regime; as 2s complement is
                       // the inverse plus one, just avoid the plus one
                       unsigned'(~signedRegime[LOCAL_SIGNED_REGIME_BITS-2:0]);

    // Join the sticky bits
    outStickyBit = inStickyBit | postShiftSticky;
  end
endmodule
