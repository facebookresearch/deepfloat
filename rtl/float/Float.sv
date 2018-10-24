// Copyright (c) Facebook, Inc. and its affiliates. All Rights Reserved.
// All rights reserved.
//
// This source code is licensed under the license found in the
// LICENSE file in the root directory of this source tree.

// Arbitrary-size IEEE-style float
interface Float #(parameter EXP=8,
                  parameter FRAC=23);
  typedef struct packed {
      logic sign;
      logic [EXP-1:0] exponent;
      logic [FRAC-1:0] fraction;
   } Data;

  Data data;

  modport InputIf (input data,
`ifndef SYNTHESIS
                   import toReal,
                   import print,
`endif
                   import getZero,
                   import getSignedExponent,
                   import getInf,
                   import getMax,
                   import getNan,
                   import isDenormal,
                   import isInf,
                   import isNan,
                   import isZero);
  modport OutputIf (output data,
`ifndef SYNTHESIS
                    import toReal,
                    import print,
`endif
                    import getZero,
                    import getSignedExponent,
                    import getInf,
                    import getMax,
                    import getNan,
                    import isDenormal,
                    import isInf,
                    import isNan,
                    import isZero);

  function automatic Data getZero(logic sign);
    Data v;
    v.sign = sign;
    v.exponent = {EXP{1'b0}};
    v.fraction = FRAC'(1'b0);

    return v;
  endfunction

  function automatic Data getInf(logic sign);
    Data v;
    v.sign = sign;
    v.exponent = {EXP{1'b1}};
    v.fraction = FRAC'(1'b0);

    return v;
  endfunction

  function automatic Data getMax(logic sign);
    Data v;
    v.sign = sign;
    v.exponent = EXP'(FloatDef::getMaxUnsignedExp(EXP, FRAC));
    v.fraction = {FRAC{1'b1}};

    return v;
  endfunction

  function automatic Data getNan();
    Data v;
    v.sign = 1'b0;
    v.exponent = {EXP{1'b1}};
    v.fraction = {FRAC{1'b1}};

    return v;
  endfunction

  function automatic logic isDenormal(Data v);
    return (v.exponent == 0) &&
           (v.fraction != EXP'(1'b0));
  endfunction

  function automatic logic isInf(Data v);
    return (v.exponent == {EXP{1'b1}}) &&
           (v.fraction == EXP'(1'b0));
  endfunction

  function automatic logic isNan(Data v);
    return (v.exponent == {EXP{1'b1}}) &&
           (v.fraction != EXP'(1'b0));
  endfunction

  function automatic logic isZero(Data v);
    return (v.exponent == {EXP{1'b0}}) &&
           (v.fraction == EXP'(1'b0));
  endfunction

  // IEEE-style float contains denormals, and the exponent (without
  // renormalization) goes from -2^(EXP - 1) + 1 to +2^(EXP - 1).
  // Our signed exponent can thus contain the same number of bits
  // This function does not handle inf/nan
  function automatic logic signed [EXP-1:0] getSignedExponent(Data v);
    if (v.exponent == EXP'(1'b0)) begin
      // Denormal value
      return signed'(EXP'(1'b1)) -
        signed'(EXP'(FloatDef::getExpBias(EXP, FRAC)));
    end else begin
      return signed'(EXP'(v.exponent)) -
        signed'(EXP'(FloatDef::getExpBias(EXP, FRAC)));
    end
  endfunction

`ifndef SYNTHESIS
  // Debugging function to convert an arbitrary float to a real
  function automatic real toReal(Data v);
    localparam DOUBLE_BIAS = FloatDef::getExpBias(11, 52);

    integer clz;
    integer exp;
    bit [FRAC-1:0] normalizedFrac;

    bit [1+11+FRAC-1:0] beforeExtension;
    bit [63:0] afterExtension;

    if (EXP > 11 || FRAC > 52) begin
      return 0;
    end

    if (isInf(v)) begin
      return $bitstoreal({v.sign, {11{1'b1}}, 52'b0});
    end else if (isNan(v)) begin
      return $bitstoreal({v.sign, {11{1'b1}}, 52'b1});
    end else if (isZero(v)) begin
      return $bitstoreal({v.sign, {11{1'b0}}, 52'b0});
    end else if (isDenormal(v)) begin
      // FIXME: we're assuming that the float's denormal type is representable
      // as a normal in double precision fp
      assert(|v.fraction);

      clz = 0;
      normalizedFrac = v.fraction;
      while (normalizedFrac[FRAC-1] == 1'b0) begin
        normalizedFrac = normalizedFrac << 1;
        clz = clz + 1;
      end

      assert(clz >= 0 && clz < FRAC);

      normalizedFrac = v.fraction << (clz + 1);
      exp = FloatDef::getMinSignedNormalExp(EXP, FRAC) + DOUBLE_BIAS - (clz + 1);

      beforeExtension = {v.sign, 11'(exp), normalizedFrac};
      afterExtension = 64'b0;
      afterExtension[63:(52-FRAC)] = beforeExtension;

      return $bitstoreal(afterExtension);
    end else begin
      exp = integer'(v.exponent) + DOUBLE_BIAS - FloatDef::getExpBias(EXP, FRAC);

      beforeExtension = {v.sign, 11'(exp), v.fraction};
      afterExtension = 64'b0;
      afterExtension[63:(52-FRAC)] = beforeExtension;

      return $bitstoreal(afterExtension);
    end
  endfunction

  function automatic string print(Data v);
    integer signedExponent;
    automatic bit isDenormal = 1'b0;
    automatic bit isInf = 1'b0;
    automatic bit isNan = 1'b0;

    if (v.exponent == 0) begin
      isDenormal = 1'b1;
      signedExponent = 1 - FloatDef::getExpBias(EXP, FRAC);
    end else if (integer'(v.exponent) == 2 ** EXP - 1) begin
      if (|v.fraction) begin
        isNan = 1'b1;
      end else begin
        isInf = 1'b1;
      end
    end else begin
      signedExponent = integer'(v.exponent) - FloatDef::getExpBias(EXP, FRAC);
    end

    if (isInf) begin
      return $sformatf("[%sinf]",
                       v.sign ? "-" : "+");
    end else if (isNan) begin
      return $sformatf("[%snan %b]",
                       v.sign ? "-" : "+",
                       v.fraction);
    end else if (isDenormal) begin
      // We could be zero
      if (v.fraction == 0) begin
        return $sformatf("[%szero]",
                         v.sign ? "-" : "+");
      end else begin
        return $sformatf("[%sexp %p denorm (%p) frac %b]",
                         v.sign ? "-" : "+",
                         signedExponent,
                         v.exponent,
                         v.fraction);
      end
    end else begin
      return $sformatf("[%sexp %p (%p) frac %b]",
                       v.sign ? "-" : "+",
                       signedExponent,
                       v.exponent,
                       v.fraction);
    end
  endfunction
`endif
endinterface
