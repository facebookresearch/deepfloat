// Copyright (c) Facebook, Inc. and its affiliates. All Rights Reserved.
// All rights reserved.
//
// This source code is licensed under the license found in the
// LICENSE file in the root directory of this source tree.

// Arbitrary-size posit, packed into WIDTH bits
interface PositUnpacked #(parameter WIDTH=8,
                          parameter ES=1);
  // Unpacked form of a posit
  typedef struct packed {
    // Are we a zero?
    logic isZero;

    // Are we +/- inf?
    logic isInf;

    // Even for zero values, we keep this, as it preserves rounding direction
    // information
    logic sign;

    // 0 is zero or +/- inf
    logic [PositDef::getUnsignedExponentBits(WIDTH, ES)-1:0] exponent;

    // The binary fraction for the number; there is always an assumed leading 1
    // i.e., 1.bbb..., where the bbb... is fraction
    logic [PositDef::getFractionBits(WIDTH, ES)-1:0] fraction;
  } Unpacked;

  Unpacked data;

  modport InputIf (input data,
`ifndef SYNTHESIS
                   import toShortReal,
                   import toReal,
                   import print,
`endif
                   import unsignedRegime,
                   import signedRegime,
                   import signedExponent,
                   import normal,
                   import zero,
                   import one,
                   import inf,
                   import getMax,
                   import getMin,
                   import isZero,
                   import isInf);
  modport OutputIf (output data,
`ifndef SYNTHESIS
                   import toShortReal,
                   import toReal,
                   import print,
`endif
                    import unsignedRegime,
                    import signedRegime,
                    import signedExponent,
                    import normal,
                    import zero,
                    import one,
                    import inf,
                    import getMax,
                    import getMin,
                    import isZero,
                    import isInf);

  //
  // Utility functions
  //

  // Returns the unsigned regime for a posit
  function automatic
    logic [PositDef::getUnsignedRegimeBits(WIDTH, ES)-1:0] unsignedRegime(Unpacked v);
    return v.exponent[PositDef::getUnsignedExponentBits(WIDTH, ES)-1:ES];
  endfunction

  // Returns the signed regime for a posit
  function automatic
    logic signed [PositDef::getSignedRegimeBits(WIDTH, ES)-1:0] signedRegime(Unpacked v);
    localparam BITS = PositDef::getUnsignedRegimeBits(WIDTH, ES);

    // FIXME: this was broken before?
    return signed'(v.exponent[PositDef::getUnsignedExponentBits(WIDTH, ES)-1:ES] -
                   BITS'(PositDef::getMaxSignedRegime(WIDTH, ES)));
  endfunction

  // Returns the signed exponent for a posit
  function automatic
    logic signed [PositDef::getSignedExponentBits(WIDTH, ES)-1:0]
      signedExponent(Unpacked v);
    localparam BIAS = PositDef::getExponentBias(WIDTH, ES);
    localparam BITS = PositDef::getSignedExponentBits(WIDTH, ES);

    return signed'(v.exponent) - signed'(BITS'(BIAS));
  endfunction

  // Initializes a normal posit with the given exponent and fraction
  function automatic
    Unpacked normal(logic sign,
                    logic [PositDef::getUnsignedExponentBits(WIDTH, ES)-1:0] exp,
                    logic [PositDef::getFractionBits(WIDTH, ES)-1:0] frac);
    Unpacked v;
    v.sign = sign;
    v.isZero = 1'b0;
    v.isInf = 1'b0;
    v.exponent = exp;
    v.fraction = frac;

    return v;
  endfunction

  // Returns a posit with value 0
  function automatic Unpacked zero(logic sign);
    localparam EXP_BITS = PositDef::getUnsignedExponentBits(WIDTH, ES);
    localparam FRAC_BITS = PositDef::getFractionBits(WIDTH, ES);

    Unpacked v;
    v.sign = sign;
    v.isZero = 1'b1;
    v.isInf = 1'b0;
    v.exponent = EXP_BITS'(1'b0);
    v.fraction = FRAC_BITS'(1'b0);

    return v;
  endfunction

  // Returns a posit with value 1
  function automatic Unpacked one(logic sign);
    localparam EXP_BITS = PositDef::getUnsignedExponentBits(WIDTH, ES);
    localparam FRAC_BITS = PositDef::getFractionBits(WIDTH, ES);

    Unpacked v;
    v.sign = sign;
    v.isZero = 1'b0;
    v.isInf = 1'b0;
    v.exponent = unsigned'(EXP_BITS'(PositDef::getMaxSignedExponent(WIDTH, ES)));
    v.fraction = FRAC_BITS'(1'b0);

    return v;
  endfunction

  // Returns a posit with value +/- inf
  // FIXME: should take sign flag
  function automatic Unpacked inf();
    localparam EXP_BITS = PositDef::getUnsignedExponentBits(WIDTH, ES);
    localparam FRAC_BITS = PositDef::getFractionBits(WIDTH, ES);

    Unpacked v;
    v.sign = 1'b0;
    v.isZero = 1'b0;
    v.isInf = 1'b1;
    v.exponent = EXP_BITS'(1'b0);
    v.fraction = FRAC_BITS'(1'b0);

    return v;
  endfunction

  // Returns the largest (pos) or smallest (neg) posit with the given sign
  function automatic Unpacked getMax(logic sign);
    localparam EXP_BITS = PositDef::getUnsignedExponentBits(WIDTH, ES);
    localparam FRAC_BITS = PositDef::getFractionBits(WIDTH, ES);

    Unpacked v;
    v.sign = sign;
    v.isZero = 1'b0;
    v.isInf = 1'b0;
    v.exponent = unsigned'(EXP_BITS'(PositDef::getMaxUnsignedExponent(WIDTH, ES)));
    v.fraction = FRAC_BITS'(1'b0);

    return v;
  endfunction

  // Returns the posit next to zero with the given sign
  function automatic Unpacked getMin(logic sign);
    localparam EXP_BITS = PositDef::getUnsignedExponentBits(WIDTH, ES);
    localparam FRAC_BITS = PositDef::getFractionBits(WIDTH, ES);

    Unpacked v;
    v.sign = sign;
    v.isZero = 1'b0;
    v.isInf = 1'b0;

    v.exponent = unsigned'(EXP_BITS'(PositDef::getMinUnsignedExponent(WIDTH, ES)));
    v.fraction = FRAC_BITS'(1'b0);

    return v;
  endfunction

  function automatic logic isZero(Unpacked v);
    return v.isZero;
  endfunction

  function automatic logic isInf(Unpacked v);
    return v.isInf;
  endfunction

`ifndef SYNTHESIS
  // Debugging function to convert to shortreal
  function shortreal toShortReal(Unpacked v);
    localparam FLOAT_EXP = 8;
    localparam FLOAT_FRAC = 23;
    localparam FLOAT_EXP_BIAS = (2 ** (FLOAT_EXP - 1)) - 1;

    logic [FLOAT_EXP-1:0] fexp;
    logic [FLOAT_FRAC-1:0] ffrac;

    // FIXME: we don't convert to denormal values at present
    if (PositDef::getMinSignedExponent(WIDTH, ES) < -FLOAT_EXP_BIAS + 1 ||
        PositDef::getMaxSignedExponent(WIDTH, ES) > FLOAT_EXP_BIAS) begin
      $error("posit exponent range out of bounds");
    end

    if (PositDef::getFractionBits(WIDTH, ES) > FLOAT_FRAC) begin
      $error("posit fraction range out of bounds");
    end

    if (v.isInf) begin
      return $bitstoshortreal({1'b0, {FLOAT_EXP{1'b1}}, {FLOAT_FRAC{1'b0}}});
    end
    else if (v.isZero) begin
      if (v.sign) begin
        return -0;
      end
      else begin
        return 0;
      end
    end
    else begin
      ffrac = v.fraction <<
              (FLOAT_FRAC - PositDef::getFractionBits(WIDTH, ES));
      fexp = FLOAT_EXP'(integer'(v.exponent) +
                        FLOAT_EXP_BIAS -
                        PositDef::getExponentBias(WIDTH, ES));

      return $bitstoshortreal({v.sign, fexp, ffrac});
    end
  endfunction

  // Debugging function to convert to real
  function real toReal(Unpacked v);
    localparam FLOAT_EXP = 11;
    localparam FLOAT_FRAC = 52;
    localparam FLOAT_EXP_BIAS = (2 ** (FLOAT_EXP - 1)) - 1;

    logic [FLOAT_EXP-1:0] fexp;
    logic [FLOAT_FRAC-1:0] ffrac;

    // FIXME: we don't convert to denormal values at present
    if (PositDef::getMinSignedExponent(WIDTH, ES) < -FLOAT_EXP_BIAS + 1 ||
        PositDef::getMaxSignedExponent(WIDTH, ES) > FLOAT_EXP_BIAS) begin
      $error("posit exponent range out of bounds");
    end

    if (PositDef::getFractionBits(WIDTH, ES) > FLOAT_FRAC) begin
      $error("posit fraction range out of bounds");
    end

    if (v.isInf) begin
      return $bitstoreal({1'b0, {FLOAT_EXP{1'b1}}, {FLOAT_FRAC{1'b0}}});
    end
    else if (v.isZero) begin
      if (v.sign) begin
        return -0;
      end
      else begin
        return 0;
      end
    end
    else begin
      ffrac = v.fraction <<
              (FLOAT_FRAC - PositDef::getFractionBits(WIDTH, ES));
      fexp = FLOAT_EXP'(integer'(v.exponent) +
                        FLOAT_EXP_BIAS -
                        PositDef::getExponentBias(WIDTH, ES));

      return $bitstoreal({v.sign, fexp, ffrac});
    end
  endfunction

  function string print(Unpacked v);
    if (v.isInf) begin
      return $sformatf("+/- inf (fields %s %p %b)",
                       v.sign ? "-" : "+", v.exponent, v.fraction);
    end
    else if (v.isZero) begin
      return $sformatf("0 (fields %s %p %b)",
                       v.sign ? "-" : "+", v.exponent, v.fraction);
    end
    else begin
      return $sformatf("%s e %p (eus %p) f %b",
                       v.sign ? "-" : "+",
                       integer'(v.exponent) -
                       PositDef::getExponentBias(WIDTH, ES),
                       v.exponent,
                       v.fraction);
    end
  endfunction
`endif
endinterface
