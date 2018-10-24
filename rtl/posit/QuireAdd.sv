// Copyright (c) Facebook, Inc. and its affiliates. All Rights Reserved.
// All rights reserved.
//
// This source code is licensed under the license found in the
// LICENSE file in the root directory of this source tree.

// in += a
// Product of 1.ff and 1.ff is mm.ffff
// FIXME: get rid of this, is no longer needed after the refactoring to
// Kulisch
module QuireAdd #(parameter WIDTH=8,
                  parameter ES=1,
                  parameter OVERFLOW=-1,
                  parameter FRAC_REDUCE=0)
  (input logic [PositDef::getExpProductBits(WIDTH, ES)-1:0] fixedExpIn,
   // In the form mm.ffff
   input logic [1:-(PositDef::getFractionBits(WIDTH, ES) * 2)] fixedValIn,
   input logic fixedSignIn,
   input logic fixedInfIn,
   Kulisch.InputIf quireIn,
   Kulisch.OutputIf quireOut);

  localparam ACC_NON_FRAC = QuireDef::getNonFracBits(WIDTH, ES,
                                                     OVERFLOW, FRAC_REDUCE);
  localparam ACC_FRAC = QuireDef::getFracBits(WIDTH, ES, OVERFLOW);

  initial begin
    assert(quireIn.ACC_NON_FRAC == ACC_NON_FRAC);
    assert(quireIn.ACC_FRAC == ACC_FRAC);

    assert(quireOut.ACC_NON_FRAC == ACC_NON_FRAC);
    assert(quireOut.ACC_FRAC == ACC_FRAC);
  end

  // FRAC is  mm.ffff
  // This is      smm.ffff with a sign and in 2s complement form
  logic [2:-(PositDef::getFractionBits(WIDTH, ES) * 2)] fixedValInSigned;

  always_comb begin
    fixedValInSigned = {fixedSignIn, fixedSignIn ? -fixedValIn : fixedValIn};
  end

  // Convert the fixed input to the Kulisch form
  Kulisch #(.ACC_NON_FRAC(ACC_NON_FRAC), .ACC_FRAC(ACC_FRAC)) accValIn();

  KulischConvertFixed #(.FRAC(PositDef::getFractionBits(WIDTH, ES) * 2),
                        .EXP(PositDef::getExpProductBits(WIDTH, ES)),
                        .ACC_NON_FRAC(ACC_NON_FRAC),
                        .ACC_FRAC(ACC_FRAC))
  cf(.expIn(fixedExpIn),
     .fixedIn(fixedValInSigned),
     .fixedInfIn,
     .out(accValIn));

  KulischAccumulatorAdd #(.ACC_NON_FRAC(ACC_NON_FRAC),
                          .ACC_FRAC(ACC_FRAC))
  add(.a(quireIn),
      .b(accValIn),
      .out(quireOut));
endmodule
