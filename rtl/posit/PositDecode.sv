// Copyright (c) Facebook, Inc. and its affiliates. All Rights Reserved.
// All rights reserved.
//
// This source code is licensed under the license found in the
// LICENSE file in the root directory of this source tree.

//
// Given a posit representation in packed WIDTH-bit form, produce the
// (sign, exponent, fraction)
// unpacked representation
//
module PositDecode #(parameter WIDTH=8,
                     parameter ES=1)
  (PositPacked.InputIf in,
   PositUnpacked.OutputIf out);

  initial begin
    assert(in.WIDTH == out.WIDTH);
    assert(WIDTH == in.WIDTH);
    assert(in.ES == out.ES);
    assert(ES == in.ES);
  end

  localparam LOCAL_MAX_REGIME_FIELD_SIZE = PositDef::getMaxRegimeFieldSize(WIDTH, ES);
  localparam LOCAL_MAX_SIGNED_REGIME = PositDef::getMaxSignedRegime(WIDTH, ES);
  localparam LOCAL_UNSIGNED_REGIME_BITS = PositDef::getUnsignedRegimeBits(WIDTH, ES);
  localparam LOCAL_UNSIGNED_EXPONENT_BITS = PositDef::getUnsignedExponentBits(WIDTH, ES);
  localparam LOCAL_FRACTION_BITS = PositDef::getFractionBits(WIDTH, ES);

  // Bits after the sign, with the sign adjusted via 2s complement
  logic [LOCAL_MAX_REGIME_FIELD_SIZE-1:0] remainderBits;

  // For determining the regime, we use a leading zero counter on the xor of
  // neighboring bits in the input, to determine where the 0 -> 1 or 1 -> 0
  // transition occurs, and thus the regime
  wire [LOCAL_MAX_REGIME_FIELD_SIZE-2:0] remainderXor;

  // The count of leading zeros of the above
  logic [$clog2(LOCAL_MAX_REGIME_FIELD_SIZE)-1:0] cl0;

  // Whether the regime is positive or negative depends upon the first non-sign
  // bit in the input
  logic regimePosOrZero;

  // Are we +/- inf or zero?
  logic isSpecial;

  // Calculated regime value starting from 0
  logic [LOCAL_UNSIGNED_REGIME_BITS-1:0] unsignedRegime;

  // How far we need to shift our word for the ES and fraction bits
  logic [$clog2(LOCAL_MAX_REGIME_FIELD_SIZE)-1:0] regimeShiftMinus2;

  // remainderBits, skipping first two bits (min size of a regime excoding),
  // shifted by extra regime bits
  logic [LOCAL_MAX_REGIME_FIELD_SIZE-3:0] esAndFractionBits;

  // Our extracted fraction
  logic [LOCAL_FRACTION_BITS-1:0] fractionBits;

  // Set up input to the leading zero counter to determine the regime
  genvar i;
  generate
    for (i = LOCAL_MAX_REGIME_FIELD_SIZE - 1; i > 0; --i) begin : genXor
      assign remainderXor[i - 1] = remainderBits[i] ^ remainderBits[i - 1];
    end
  endgenerate

  CountLeadingZeros #(.WIDTH(LOCAL_MAX_REGIME_FIELD_SIZE - 1))
  clz(.in(remainderXor), .out(cl0));

  // Performs
  // esAndFractionBits = remainderBits[LOCAL_MAX_REGIME_FIELD_SIZE-3:0]
  //                     << regimeShiftMinus2;
  ShiftLeft #(.WIDTH(LOCAL_MAX_REGIME_FIELD_SIZE-2),
              // FIXME: this is not quite right, it's max regime field size - 2
              // + 1 I think, though it's the same value
              .SHIFT_VAL_WIDTH($clog2(LOCAL_MAX_REGIME_FIELD_SIZE)))
  esAndFractionBitsShift(.in(remainderBits[LOCAL_MAX_REGIME_FIELD_SIZE-3:0]),
                         .shift(regimeShiftMinus2),
                         .out(esAndFractionBits));

  always_comb begin
    // FIXME: I've changed the posit layout to not be symmetric, to have simpler decoding
    remainderBits = in.data.bits[WIDTH-2:0];

    regimePosOrZero = remainderBits[LOCAL_MAX_REGIME_FIELD_SIZE-1];

    // The special values are 000...0 and 100...0
    //    isSpecial = cl0 == (LOCAL_MAX_REGIME_FIELD_SIZE - 1) && !regimePosOrZero;
    isSpecial = !(|remainderBits);

    // signedRegime = regimePosOrZero ? LOCAL_SIGNED_REGIME_BITS'(cl0) :
    //                ~LOCAL_SIGNED_REGIME_BITS'(cl0);

    // FIXME: signed regime is actually easier to calculate, store that
    // everywhere?
    // For inf or zero, we wish the regime field to also be zero
    if (isSpecial) begin
      unsignedRegime = LOCAL_UNSIGNED_REGIME_BITS'(0);
    end
    else begin
      unsignedRegime = (regimePosOrZero ? LOCAL_UNSIGNED_REGIME_BITS'(cl0) :
                        ~LOCAL_UNSIGNED_REGIME_BITS'(cl0)) +
                       LOCAL_UNSIGNED_REGIME_BITS'(LOCAL_MAX_SIGNED_REGIME);
    end

    // Can we just do this?
    // signedRegime = regPosOrZero ? cl0 : ~cl0
    // unsignedRegime = signedRegime + LOCAL_MAX_SIGNED_REGIME

    // The number of bits to encode the regime is really
    // min(max(cl0, cl1) + 1, LOCAL_MAX_REGIME_FIELD_SIZE):
    //
    // Regime containing all 0s is either 0 or +/- inf
    // For WIDTH = 5, LOCAL_MAX_REGIME_FIELD_SIZE = 4:
    //
    //  0 or +/- inf
    //             |    min representable exponent
    //             v    v
    // encoding 0000 0001 001x 01xx 10xx 110x 1110 1111
    // sgn regime  x   -3   -2   -1    0    1    2    3
    // uns regime  x    0    1    2    3    4    5    6
    // cl0(xor)    3    2    1    0    0    1    2    3
    // regime bits 4    4    3    2    2    3    4    4
    //
    // However, we use the count of the regime bits to shift our
    // word into place to extract the ES and fraction bits.
    // Note that at the extreme positive and negative regime, we are
    // consuming all bits in the word, so we needn't take into
    // account the outer min.
    // The leading zero counter effectively produces the regime shift - 2.
    // The regime at least takes up two bits, so this is perfect.
    regimeShiftMinus2 = cl0; // the larger of the two, as one is always zero

    out.data.isInf = in.data.bits[WIDTH-1] && isSpecial;
    out.data.isZero = !in.data.bits[WIDTH-1] && isSpecial;
    out.data.sign = !isSpecial && in.data.bits[WIDTH-1];
  end

  generate
    if (ES > 0) begin : genES0
      // We have a ES to extract
      logic [ES-1:0] esBits;

      always_comb begin
        // The entire ES field may not be present (it could be truncated),
        // but the shift above will ensure that we are only reading 0s for the
        // other values
        esBits = esAndFractionBits[LOCAL_MAX_REGIME_FIELD_SIZE-3-:ES];

        out.data.exponent = {unsignedRegime, esBits};
        out.data.fraction = esAndFractionBits[LOCAL_MAX_REGIME_FIELD_SIZE-3-ES:0];
      end
    end else begin : genES
      // There is no ES to extract
      always_comb begin
        out.data.exponent = LOCAL_UNSIGNED_EXPONENT_BITS'(unsignedRegime);
        out.data.fraction = esAndFractionBits[LOCAL_MAX_REGIME_FIELD_SIZE-3:0];
      end
    end
  endgenerate
endmodule
