// Copyright (c) Facebook, Inc. and its affiliates. All Rights Reserved.
// All rights reserved.
//
// This source code is licensed under the license found in the
// LICENSE file in the root directory of this source tree.

//
// Given a posit representation in unpacked
// (sign, exponent, fraction)
// form, produce the WIDTH-bit packed representation
//

`define USE_SHIFTER

//
// An encoder that uses a barrel shifter
//
`ifdef USE_SHIFTER

module PositEncode #(parameter WIDTH=8,
                     parameter ES=1)
  (PositUnpacked.InputIf in,
   PositPacked.OutputIf out);

  initial begin
    assert(in.WIDTH == out.WIDTH);
    assert(WIDTH == in.WIDTH);
    assert(in.ES == out.ES);
    assert(ES == in.ES);
  end

  localparam LOCAL_MAX_REGIME_FIELD_SIZE = PositDef::getMaxRegimeFieldSize(WIDTH, ES);
  localparam LOCAL_MAX_SIGNED_REGIME = PositDef::getMaxSignedRegime(WIDTH, ES);
  localparam LOCAL_UNSIGNED_REGIME_BITS = PositDef::getUnsignedRegimeBits(WIDTH, ES);
  localparam LOCAL_SIGNED_REGIME_BITS = PositDef::getSignedRegimeBits(WIDTH, ES);
  localparam LOCAL_ES_BITS = PositDef::getESBits(WIDTH, ES);

  logic signed [LOCAL_SIGNED_REGIME_BITS-1:0] signedRegime;
  logic [LOCAL_SIGNED_REGIME_BITS-2:0] shiftBits;
  logic posRegime;

  logic signed [LOCAL_MAX_REGIME_FIELD_SIZE-1:0] esAndFraction;
  logic signed [LOCAL_MAX_REGIME_FIELD_SIZE-1:0] esAndFractionShifted;

  // arithmetic right shift, to extend the leading 1 if present
  // esAndFractionShifted = esAndFraction >>> shiftBits;
  ShiftRightArithmetic #(.WIDTH(LOCAL_MAX_REGIME_FIELD_SIZE),
                         .SHIFT_VAL_WIDTH(LOCAL_SIGNED_REGIME_BITS-1))
  sr(.in(esAndFraction),
     .shift(shiftBits),
     .out(esAndFractionShifted));

  generate
    if (ES > 0) begin
      assign esAndFraction = {posRegime ? 2'b10 : 2'b01,
                              in.data.exponent[ES-1:0],
                              in.data.fraction};
    end
    else begin
      assign esAndFraction = {posRegime ? 2'b10 : 2'b01,
                              in.data.fraction};
    end
  endgenerate

  always_comb begin
    signedRegime = in.signedRegime(in.data);
    posRegime = signedRegime >= 0;

    // Example:
    // encoding 0000 0001 001x 01xx 10xx 110x 1110 1111
    // sgn regime  x   -3   -2   -1    0    1    2    3
    // uns regime  x    0    1    2    3    4    5    6
    // regime bits 4    4    3    2    2    3    4    4

    // Equivalent of posRegime ? signedRegime : -signedRegime - 1
    // Our shift width only needs to encode the maximum positive regime
    shiftBits = posRegime ?
                unsigned'(signedRegime[LOCAL_SIGNED_REGIME_BITS-2:0]) :
                // Subtract 1 from the signed regime; as 2s complement is
                // the inverse plus one
                unsigned'(~signedRegime[LOCAL_SIGNED_REGIME_BITS-2:0]);

    unique if (in.data.isZero) begin
      out.data = out.zeroPacked();
    end
    else if (in.data.isInf) begin
      out.data = out.infPacked();
    end
    else begin
      out.data.bits[WIDTH-1] = in.data.sign;
      out.data.bits[WIDTH-2:0] = esAndFractionShifted;
    end
  end
endmodule

`endif // USE_SHIFTER

//
// An encoder that explicitly constructs a connection table
//
`ifdef USE_EXPLICIT

module PositEncode #(parameter WIDTH=8,
                     parameter ES=1)
  (PositUnpacked.InputIf in,
   PositPacked.OutputIf out);

  // Quartus doesn't support parameterized class typedefs
  localparam LOCAL_MAX_UNSIGNED_REGIME = in.MAX_UNSIGNED_REGIME;
  localparam LOCAL_MAX_SIGNED_REGIME = in.MAX_SIGNED_REGIME;
  localparam LOCAL_MAX_REGIME_FIELD_SIZE = in.MAX_REGIME_FIELD_SIZE;
  localparam LOCAL_UNSIGNED_REGIME_BITS = in.UNSIGNED_REGIME_BITS;
  localparam LOCAL_ES_BITS = in.ES_BITS;
  localparam LOCAL_FRACTION_BITS = in.FRACTION_BITS;

  // Does the unsigned regime value represent a signed regime less than 0?
  function automatic bit isRegimeNegative(input integer unsignedRegime);
    return (unsignedRegime < LOCAL_MAX_SIGNED_REGIME);
  endfunction

  // Based on the unsigned regime value, returns the width in bits of the regime
  // encoding
  function automatic integer getRegimeFieldSize(input integer unsignedRegime);
    integer posBits;

    if (isRegimeNegative(unsignedRegime)) begin
      // The regime is negative
      return (LOCAL_MAX_SIGNED_REGIME - unsignedRegime) + 1;
    end
    else begin
      // The regime is zero or positive
      posBits = unsignedRegime - LOCAL_MAX_SIGNED_REGIME + 2;
      return getMin(posBits, LOCAL_MAX_REGIME_FIELD_SIZE);
    end
  endfunction

  // How wide in bits is the ES + fraction field for a given regime?
  function automatic integer getRemainderFieldSize(input integer unsignedRegime);
    return Functions::getMax(WIDTH - 1 - getRegimeFieldSize(unsignedRegime), 0);
  endfunction

  // How wide in bits is the ES field for a given regime?
  function automatic integer getExponentFieldSize(input integer unsignedRegime);
    integer rem;
    rem = getRemainderFieldSize(unsignedRegime);

    if (rem > ES) begin
      return ES;
    end

    return getMin(rem, ES);
  endfunction

  // How wide in bits is the fraction field for a given regime?
  function automatic integer getFractionFieldSize(input integer unsignedRegime);
    integer rem;
    rem = getRemainderFieldSize(unsignedRegime);

    return Functions::getMax(rem - ES, 0);
  endfunction

  wire [0:LOCAL_MAX_UNSIGNED_REGIME][WIDTH-2:0] outs;
  wire [LOCAL_UNSIGNED_REGIME_BITS-1:0] unsignedRegime;
  wire [LOCAL_ES_BITS-1:0] es;

  assign unsignedRegime = in.data.exponent >> ES;
  assign es = in.data.exponent[LOCAL_ES_BITS-1:0];

  genvar r;
  genvar j;

  generate
    // Generate the encoding for each regime
    for (r = 0; r <= LOCAL_MAX_UNSIGNED_REGIME; ++r) begin : eachR
      //
      // Pack regime encoding
      //
      for (j = 0; j < getRegimeFieldSize(r) - 1; ++j) begin : eachRegime
        if (isRegimeNegative(r)) begin
          assign outs[r][WIDTH-2-j] = 1'b0;
        end
        else begin
          assign outs[r][WIDTH-2-j] = 1'b1;
        end
      end

      // terminal bit for regime encoding
      assign outs[r][WIDTH-1-getRegimeFieldSize(r)] =
        (isRegimeNegative(r) || r == LOCAL_MAX_UNSIGNED_REGIME);

      //
      // Pack exponent scale
      //
      for (j = 0; j < getExponentFieldSize(r); ++j) begin : eachES
        // take MSBs from ES
        assign outs[r][WIDTH-1-getRegimeFieldSize(r)-1-j] =
           es[LOCAL_ES_BITS-1-j];
      end

      //
      // Pack fraction
      //
      for (j = 0; j < getFractionFieldSize(r); ++j) begin : eachFrac
        assign outs[r][getFractionFieldSize(r)-1-j] =
         in.data.fraction[LOCAL_FRACTION_BITS-1-j];
      end
    end
  endgenerate

  always_comb begin
    unique if (in.data.isZero) begin
      out.data = out.zeroPacked();
    end
    else if (in.data.isInf) begin
      out.data = out.infPacked();
    end
    else begin
      out.data.bits[WIDTH-1] = in.data.sign;

      out.data.bits[WIDTH-2:0] = // I've changed the posit layout to not be
                                 // symmetric, to have simpler encoding
                                 outs[unsignedRegime];
    end
  end
endmodule

`endif // USE_EXPLICIT
