// Copyright (c) Facebook, Inc. and its affiliates. All Rights Reserved.
// All rights reserved.
//
// This source code is licensed under the license found in the
// LICENSE file in the root directory of this source tree.

module PaperPositPE #(parameter WIDTH=16,
                      parameter ES=1,
                      parameter OVERFLOW=0,
                      parameter FRAC_REDUCE=0)
   (PositUnpacked.InputIf aIn,
    PositUnpacked.InputIf bIn,
    PositUnpacked.OutputIf aOut,
    PositUnpacked.OutputIf bOut,
    Kulisch.OutputIf cOut,
    input reset,
    input clock);

  localparam EXP_PRODUCT_BITS = PositDef::getExpProductBits(WIDTH, ES);
  localparam FRAC_PRODUCT_BITS = PositDef::getFracProductBits(WIDTH, ES);

  localparam ACC_NON_FRAC = QuireDef::getNonFracBits(WIDTH, ES, OVERFLOW, FRAC_REDUCE);
  localparam ACC_FRAC = QuireDef::getFracBits(WIDTH, ES, OVERFLOW);

  logic [EXP_PRODUCT_BITS-1:0] abExp;
  logic [FRAC_PRODUCT_BITS-1:0] abFrac;

  logic abSign;
  logic abIsInf;

  PositMultiplyForQuire #(.WIDTH(WIDTH),
                          .ES(ES),
                          .USE_ADJUST(0),
                          .ADJUST_SCALE_SIZE(1))
  mult(.a(aIn),
       .b(bIn),
       .adjustScale(1'b0),
       .abIsInf,
       .abIsZero(),
       .abSign,
       .abExp,
       .abFrac);

  Kulisch #(.ACC_NON_FRAC(ACC_NON_FRAC), .ACC_FRAC(ACC_FRAC)) qPostAdd();
  Kulisch #(.ACC_NON_FRAC(ACC_NON_FRAC), .ACC_FRAC(ACC_FRAC)) qReg();

  QuireAdd #(.WIDTH(WIDTH),
             .ES(ES),
             .OVERFLOW(OVERFLOW),
             .FRAC_REDUCE(FRAC_REDUCE))
  adder(.fixedExpIn(abExp),
        .fixedValIn(abFrac),
        .fixedSignIn(abSign),
        .fixedInfIn(abIsInf),
        .quireIn(qReg),
        .quireOut(qPostAdd));

  always_comb begin
    cOut.data = qReg.data;
  end

  always_ff @(posedge clock) begin
    if (reset) begin
      aOut.data <= aOut.zero(1'b0);
      bOut.data <= bOut.zero(1'b0);
      qReg.data <= cOut.zero();
    end else begin
      aOut.data <= aIn.data;
      bOut.data <= bIn.data;
      qReg.data <= qPostAdd.data;
    end
  end
endmodule
