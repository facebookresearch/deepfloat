// Copyright (c) Facebook, Inc. and its affiliates. All Rights Reserved.
// All rights reserved.
//
// This source code is licensed under the license found in the
// LICENSE file in the root directory of this source tree.

// FIXME: not a complete test
module FloatContractTest();
  localparam TRAILING_BITS = 2;

  Float #(.EXP(4), .FRAC(23)) smallIn();
  Float #(.EXP(3), .FRAC(23)) tinyOut();

  logic [TRAILING_BITS-1:0] trailingBitsTiny;
  logic stickyBitTiny;
  logic isNanOutTiny;

  Float #(.EXP(11), .FRAC(52)) doubleIn();
  Float #(.EXP(8), .FRAC(23)) floatOut();

  logic [TRAILING_BITS-1:0] trailingBitsFloat;
  logic stickyBitFloat;
  logic isNanOutFloat;

  Float #(.EXP(3), .FRAC(23)) tinyDef();
  Float #(.EXP(4), .FRAC(23)) smallDef();
  Float #(.EXP(8), .FRAC(23)) floatDef();
  Float #(.EXP(11), .FRAC(52)) doubleDef();

  FloatContract #(.EXP_IN(4), .FRAC_IN(23),
                  .EXP_OUT(3), .FRAC_OUT(23))
  smallToTiny(.in(smallIn),
              .out(tinyOut),
              .trailingBitsOut(trailingBitsTiny),
              .stickyBitOut(stickyBitTiny),
              .isNanOut(isNanOutTiny));

  FloatContract #(.EXP_IN(11), .FRAC_IN(52),
                  .EXP_OUT(8), .FRAC_OUT(23))
  doubleToFloat(.in(doubleIn),
                .out(floatOut),
                .trailingBitsOut(trailingBitsFloat),
                .stickyBitOut(stickyBitFloat),
                .isNanOut(isNanOutFloat));

  initial begin
    // inf -> inf
    smallIn.data = {1'b1, 4'b1111, 23'b0};
    #1;

    assert(smallDef.isInf(smallIn.data));
    assert(tinyDef.isInf(tinyOut.data));
    assert(tinyOut.data.sign);

    // nan -> nan
    smallIn.data = {1'b0, 4'b1111, 23'b1};
    #1;

    assert(smallDef.isNan(smallIn.data));
    assert(tinyDef.isNan(tinyOut.data));

    // denormal -> zero
    smallIn.data = {1'b0, 4'b0, {17'b0, 6'b100110}};
    #1;

    assert(smallDef.isDenormal(smallIn.data));
    assert(tinyDef.isDenormal(tinyOut.data));
    assert(tinyOut.data.fraction == 23'b10);
    assert(trailingBitsTiny == 2'b01);
    assert(!isNanOutTiny);

    // normal -> denormal
    smallIn.data = {1'b0, 4'b1, {1'b1, 22'b0}};
    #1;

    assert(!smallDef.isDenormal(smallIn.data));
    assert(tinyDef.isDenormal(tinyOut.data));
    assert(tinyOut.data.fraction == {3'b0, 2'b11, 18'b0});
    assert(!isNanOutTiny);

    // normal -> normal
    smallIn.data = {1'b1, 4'd6, {2'b0, 1'b1, 20'b0}};
    #1;

    assert(!smallDef.isDenormal(smallIn.data));
    assert(!tinyDef.isDenormal(tinyOut.data));
    assert(smallIn.data.fraction == tinyOut.data.fraction);
    assert(tinyOut.data.exponent == 2);

    // double -> float
    doubleIn.data = {1'b1, 11'd1026, {3'b101, 49'b0}};
    #1;

    assert($bitstoreal(doubleIn.data) == $bitstoshortreal(floatOut.data));

    doubleIn.data = {1'b0, 11'd1026, {23'b0, 2'b01, 1'b1, 26'b0}};
    #1;

    assert(trailingBitsFloat == 2'b01);
    assert(stickyBitFloat == 1'b1);

    doubleIn.data = {1'b0, 11'd1026, {23'b0, 2'b10, 27'b0}};
    #1;

    assert(trailingBitsFloat == 2'b10);
    assert(stickyBitFloat == 1'b0);

    // Denormal in new regime
    doubleIn.data = {1'b0, 11'd2, {1'b1, 51'b1}};
    #1;

    assert(trailingBitsFloat == 2'b00);
    assert(stickyBitFloat == 1'b1);

    // Slightly denormal in new regime
    // FIXME
  end
endmodule
