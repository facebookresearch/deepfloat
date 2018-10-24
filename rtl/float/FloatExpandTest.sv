// Copyright (c) Facebook, Inc. and its affiliates. All Rights Reserved.
// All rights reserved.
//
// This source code is licensed under the license found in the
// LICENSE file in the root directory of this source tree.

module FloatExpandTest();

  Float #(.EXP(3), .FRAC(23)) tinyIn();
  Float #(.EXP(4), .FRAC(23)) smallOut();

  Float #(.EXP(4), .FRAC(23)) smallIn();
  Float #(.EXP(8), .FRAC(23)) floatOut();

  Float #(.EXP(8), .FRAC(23)) floatIn();
  Float #(.EXP(11), .FRAC(52)) doubleOut();

  Float #(.EXP(8), .FRAC(23)) sameIn();
  Float #(.EXP(8), .FRAC(23)) sameOut();

  Float #(.EXP(3), .FRAC(23)) tinyDef();
  Float #(.EXP(4), .FRAC(23)) smallDef();
  Float #(.EXP(8), .FRAC(23)) floatDef();
  Float #(.EXP(11), .FRAC(52)) doubleDef();

  logic smallIsInf;
  logic smallIsNan;
  logic smallIsDenormal;

  FloatExpand #(.EXP_IN(3), .FRAC_IN(23),
                .EXP_OUT(4), .FRAC_OUT(23))
  tinyToSmall(.in(tinyIn),
              .out(smallOut),
              .isInf(smallIsInf),
              .isNan(smallIsNan),
              .isZero(),
              .isDenormal(smallIsDenormal));

  FloatExpand #(.EXP_IN(4), .FRAC_IN(23),
                .EXP_OUT(8), .FRAC_OUT(23))
  smallToFloat(.in(smallIn), .out(floatOut),
              .isInf(), .isNan(), .isZero(), .isDenormal());

  FloatExpand #(.EXP_IN(8), .FRAC_IN(23),
                .EXP_OUT(11), .FRAC_OUT(52))
  floatToDouble(.in(floatIn), .out(doubleOut),
              .isInf(), .isNan(), .isZero(), .isDenormal());

  FloatExpand #(.EXP_IN(8), .FRAC_IN(23),
                .EXP_OUT(8), .FRAC_OUT(23))
  sameToSame(.in(sameIn), .out(sameOut),
              .isInf(), .isNan(), .isZero(), .isDenormal());

  initial begin
    // denormal -> denormal
    tinyIn.data = {1'b0, 3'b0, {4'b0, 1'b1, 18'b0}};
    #1;
    assert(smallOut.data.exponent == 0);
    assert(smallOut.data.fraction == {1'b1, 22'b0});
    assert(!smallIsInf && !smallIsNan && smallIsDenormal);

    // denormal -> normal
    tinyIn.data = {1'b0, 3'b0, {3'b0, 1'b1, 19'b0}};
    #1;
    assert(smallOut.data.exponent == 1);
    assert(smallOut.data.fraction == 23'b0);
    assert(!smallIsInf && !smallIsNan && !smallIsDenormal);

    // inf -> inf
    tinyIn.data = {1'b1, 3'b111, 23'b0};
    #1;
    assert(smallOut.data.sign == 1'b1);
    assert(smallOut.data.exponent == 4'b1111);
    assert(smallOut.data.fraction == 23'b0);
    assert(smallIsInf && !smallIsNan && !smallIsDenormal);

    // nan -> nan
    tinyIn.data = {1'b1, 3'b111, {1'b1, 22'b0}};
    #1;
    assert(smallOut.data.sign == 1'b1);
    assert(smallOut.data.exponent == 4'b1111);
    assert(smallOut.data.fraction == {1'b1, 22'b0});
    assert(!smallIsInf && smallIsNan && !smallIsDenormal);

    // denormal -> normal
    floatIn.data = {1'b0, 8'b0, {20'b0, 3'b101}};
    #1;
    assert($bitstoshortreal(floatIn.data) == $bitstoreal(doubleOut.data));

    // normal -> normal
    floatIn.data = {1'b1, 8'd128, {3'b0, {5{1'b1}}, 15'b0}};
    #1;
    assert($bitstoshortreal(floatIn.data) == $bitstoreal(doubleOut.data));

    // same -> same
    sameIn.data = {1'b1, 8'd128, {3'b0, {5{1'b1}}, 15'b0}};
    #1;
    assert($bitstoshortreal(sameIn.data) == $bitstoshortreal(sameOut.data));
  end
endmodule
