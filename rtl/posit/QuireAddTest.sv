// Copyright (c) Facebook, Inc. and its affiliates. All Rights Reserved.
// All rights reserved.
//
// This source code is licensed under the license found in the
// LICENSE file in the root directory of this source tree.

module QuireAddTestTemplate #(parameter WIDTH=8,
                              parameter ES=1,
                              parameter OVERFLOW=0)
  ();
  PositUnpacked #(.WIDTH(WIDTH), .ES(ES)) positDef();

  localparam LOCAL_EXP_PRODUCT_BITS = PositDef::getExpProductBits(WIDTH, ES);
  localparam LOCAL_FRAC_PRODUCT_BITS = PositDef::getFracProductBits(WIDTH, ES);

  localparam ACC_NON_FRAC = QuireDef::getNonFracBits(WIDTH, ES, OVERFLOW, 0);
  localparam ACC_FRAC = QuireDef::getFracBits(WIDTH, ES, OVERFLOW);

  localparam LOCAL_MAX_SIGNED_EXPONENT = PositDef::getMaxSignedExponent(WIDTH,
                                                                        ES);
  localparam LOCAL_MAX_UNSIGNED_EXPONENT = PositDef::getMaxUnsignedExponent(WIDTH,
                                                                            ES);

  Kulisch #(.ACC_NON_FRAC(ACC_NON_FRAC), .ACC_FRAC(ACC_FRAC)) quireIn();
  Kulisch #(.ACC_NON_FRAC(ACC_NON_FRAC), .ACC_FRAC(ACC_FRAC)) quireOut();

  logic [LOCAL_EXP_PRODUCT_BITS-1:0] fixedExp;
  logic [LOCAL_FRAC_PRODUCT_BITS-1:0] fixedFrac;
  logic fixedSignIn;
  logic fixedInfIn;

  QuireAdd #(.WIDTH(WIDTH),
             .ES(ES),
             .OVERFLOW(OVERFLOW))
  add(.fixedExpIn(fixedExp),
      .fixedValIn(fixedFrac),
      .fixedSignIn(fixedSignIn),
      .fixedInfIn(fixedInfIn),
      .quireIn(quireIn),
      .quireOut(quireOut));

  PositUnpacked #(.WIDTH(WIDTH), .ES(ES)) pqOut();
  logic [1:0] trailingBits;
  logic stickyBit;

  QuireToPosit #(.WIDTH(WIDTH),
                 .ES(ES),
                 .OVERFLOW(OVERFLOW),
                 .TRAILING_BITS(2))
  q2p(.in(quireOut),
      .adjustMul(),
      .out(pqOut),
      .trailingBitsOut(trailingBits),
      .stickyBitOut(stickyBit));

  PositUnpacked #(.WIDTH(WIDTH), .ES(ES)) r2neOut();

  PositRoundToNearestEven #(.WIDTH(WIDTH),
                            .ES(ES))
  r2ne(.in(pqOut),
       .out(r2neOut),
       .trailingBits,
       .stickyBit);

  initial begin
    // This is the product of two 1 posits
    fixedExp = LOCAL_MAX_SIGNED_EXPONENT * 2;
    // with leading overflow mul bit 01.0000...
    fixedFrac = {1'b0, 1'b1, (LOCAL_FRAC_PRODUCT_BITS-2)'(1'b0)};
    fixedSignIn = 0;
    fixedInfIn = 0;

    quireIn.data = quireIn.zero();

    // This should be the posit 1
    #1 assert(r2neOut.data == positDef.one(1'b0));

    // This should be the posit 2
    quireIn.data = quireOut.data; // add +1 again
    #1 assert(positDef.toReal(r2neOut.data) == 2.0);

    quireIn.data = quireOut.data;
    fixedExp = fixedExp + 1; // add +2

    // This should be the posit 4
    #1 assert(positDef.toReal(r2neOut.data) == 4.0);

    // Subtract 0.5
    fixedExp = LOCAL_MAX_SIGNED_EXPONENT * 2 - 1;
    fixedSignIn = 1'b1;
    quireIn.data = quireOut.data;

    // This should be the posit 3.5
    #1 assert(positDef.toReal(r2neOut.data) == 3.5);

    // Subtract the largest possible posit product
    fixedExp = LOCAL_MAX_SIGNED_EXPONENT * 4;
    fixedSignIn = 1'b1;
    quireIn.data = quireOut.data;

    // This should be the maximum negative posit (saturation)
    #1 assert(r2neOut.data == positDef.getMax(1'b1));

    // Add infinity
    fixedInfIn = 1'b1;
    quireIn.data = quireOut.data;

    #1 assert(r2neOut.data == positDef.inf());
  end
endmodule

module QuireAddTest();
  QuireAddTestTemplate #(.WIDTH(8), .ES(1))
  test8_1_64();
  QuireAddTestTemplate #(.WIDTH(8), .ES(0))
  test8_0_8();
  QuireAddTestTemplate #(.WIDTH(8), .ES(2))
  test8_2_1();

  QuireAddTestTemplate #(.WIDTH(10), .ES(2))
  test10_2_4();
  QuireAddTestTemplate #(.WIDTH(9), .ES(0))
  test9_0_16();
endmodule
