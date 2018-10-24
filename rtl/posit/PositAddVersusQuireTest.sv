// Copyright (c) Facebook, Inc. and its affiliates. All Rights Reserved.
// All rights reserved.
//
// This source code is licensed under the license found in the
// LICENSE file in the root directory of this source tree.

// Convert a posit to a quire
module PositToQuire #(parameter WIDTH=8,
                      parameter ES=1,
                      parameter OVERFLOW=0)
  (PositUnpacked.InputIf in,
   Kulisch.OutputIf out);

  localparam ACC_NON_FRAC = QuireDef::getNonFracBits(WIDTH, ES, OVERFLOW, 0);
  localparam ACC_FRAC = QuireDef::getFracBits(WIDTH, ES, OVERFLOW);

  localparam LOCAL_EXP_PRODUCT_BITS = PositDef::getExpProductBits(WIDTH, ES);
  localparam LOCAL_FRAC_PRODUCT_BITS = PositDef::getFracProductBits(WIDTH, ES);

  logic [LOCAL_EXP_PRODUCT_BITS-1:0] outExp;
  logic [LOCAL_FRAC_PRODUCT_BITS-1:0] outFrac;
  logic outIsInf;
  logic outSign;

  PositQuireConvert #(.WIDTH(WIDTH),
                      .ES(ES),
                      .USE_ADJUST(0),
                      .ADJUST_SCALE_SIZE(1))
  pqc(.in,
      .adjustScale(),
      .outIsInf,
      .outSign,
      .outIsZero(),
      .outExp,
      .outFrac);

  Kulisch #(.ACC_NON_FRAC(ACC_NON_FRAC), .ACC_FRAC(ACC_FRAC)) zeroQuire();

  always_comb begin
    zeroQuire.data = zeroQuire.zero();
  end

  QuireAdd #(.WIDTH(WIDTH),
             .ES(ES),
             .OVERFLOW(OVERFLOW))
  qa(.fixedExpIn(outExp),
     .fixedValIn(outFrac),
     .fixedSignIn(outSign),
     .fixedInfIn(outIsInf),
     .quireIn(zeroQuire),
     .quireOut(out));
endmodule

module AddViaQuire #(parameter WIDTH=8,
                     parameter ES=1,
                     parameter OVERFLOW=0)
  (PositUnpacked.InputIf a,
   PositUnpacked.InputIf b,
   PositUnpacked.OutputIf out);

  localparam ACC_NON_FRAC = QuireDef::getNonFracBits(WIDTH, ES, OVERFLOW, 0);
  localparam ACC_FRAC = QuireDef::getFracBits(WIDTH, ES, OVERFLOW);

  Kulisch #(.ACC_NON_FRAC(ACC_NON_FRAC), .ACC_FRAC(ACC_FRAC)) quireA();

  PositToQuire #(.WIDTH(WIDTH), .ES(ES), .OVERFLOW(OVERFLOW))
  p2qa(.in(a), .out(quireA));

  Kulisch #(.ACC_NON_FRAC(ACC_NON_FRAC), .ACC_FRAC(ACC_FRAC)) quireB();

  PositToQuire #(.WIDTH(WIDTH), .ES(ES), .OVERFLOW(OVERFLOW))
  p2qb(.in(b), .out(quireB));

  Kulisch #(.ACC_NON_FRAC(ACC_NON_FRAC), .ACC_FRAC(ACC_FRAC)) quireOut();

  KulischAccumulatorAdd #(.ACC_NON_FRAC(ACC_NON_FRAC),
                          .ACC_FRAC(ACC_FRAC))
  qadd(.a(quireA),
       .b(quireB),
       .out(quireOut));

  PositUnpacked #(.WIDTH(WIDTH), .ES(ES)) pOut();
  logic [1:0] trailingBits;
  logic stickyBit;

  QuireToPosit #(.WIDTH(WIDTH),
                 .ES(ES),
                 .OVERFLOW(OVERFLOW),
                 .TRAILING_BITS(2),
                 .USE_ADJUST(0))
  q2p(.in(quireOut),
      .adjustMul(),
      .out(pOut),
      .trailingBitsOut(trailingBits),
      .stickyBitOut(stickyBit));

  PositRoundToNearestEven #(.WIDTH(WIDTH), .ES(ES))
  prne(.in(pOut),
       .trailingBits,
       .stickyBit,
       .out);
endmodule

module AddViaPosit #(parameter WIDTH=8,
                     parameter ES=1)
  (PositUnpacked.InputIf a,
   PositUnpacked.InputIf b,
   input subtract,
   PositUnpacked.OutputIf out);

  PositUnpacked #(.WIDTH(WIDTH), .ES(ES)) addOut();
  bit [1:0] trailingBits;
  bit stickyBit;

  PositAdd #(.WIDTH(WIDTH), .ES(ES))
  add(.a,
      .b,
      .out(addOut),
      .trailingBits(trailingBits),
      .stickyBit(stickyBit),
      .subtract);

  PositRoundToNearestEven #(.WIDTH(WIDTH), .ES(ES))
  prne(.in(addOut),
       .trailingBits,
       .stickyBit,
       .out);
endmodule

// Compare PositAdd versus adding through the quire; we should produce
// the same value
module PositAddVersusQuireTemplate #(parameter WIDTH=6,
                                     parameter ES=1,
                                     parameter OVERFLOW=0)
  ();
  localparam TRAILING_BITS = 2;

  PositPacked #(.WIDTH(WIDTH), .ES(ES)) a();
  PositUnpacked #(.WIDTH(WIDTH), .ES(ES)) decA();

  PositDecode #(.WIDTH(WIDTH), .ES(ES))
  decodeA(.in(a), .out(decA));

  PositPacked #(.WIDTH(WIDTH), .ES(ES)) b();
  PositUnpacked #(.WIDTH(WIDTH), .ES(ES)) decB();

  PositDecode #(.WIDTH(WIDTH), .ES(ES))
  decodeB(.in(b), .out(decB));

  PositUnpacked #(.WIDTH(WIDTH), .ES(ES)) quireAddOut();

  AddViaQuire #(.WIDTH(WIDTH),
                .ES(ES),
                .OVERFLOW(OVERFLOW))
  avq(.a(decA),
      .b(decB),
      .out(quireAddOut));

  PositUnpacked #(.WIDTH(WIDTH), .ES(ES)) positAddOut();

  AddViaPosit #(.WIDTH(WIDTH),
                .ES(ES))
  avp(.a(decA),
      .b(decB),
      .subtract(1'b0),
      .out(positAddOut));

  integer i;
  integer j;

  initial begin
    for (i = 0; i < 2 ** WIDTH; ++i) begin
      a.data = i;
      for (j = 0; j < 2 ** WIDTH; ++j) begin
        b.data = j;
        #1;

        assert(quireAddOut.data == positAddOut.data);

        if (quireAddOut.data != positAddOut.data) begin
          $display("%p %p: %s (%g) + %s (%g) => quire %s (%g) vs posit %s (%g)",
                   i, j,
                   positAddOut.print(decA.data),
                   positAddOut.toReal(decA.data),
                   positAddOut.print(decB.data),
                   positAddOut.toReal(decB.data),
                   positAddOut.print(quireAddOut.data),
                   positAddOut.toReal(quireAddOut.data),
                   positAddOut.print(positAddOut.data),
                   positAddOut.toReal(positAddOut.data));
        end
      end
    end
  end
endmodule

module PositAddVersusQuireTest();
  PositAddVersusQuireTemplate #(.WIDTH(6), .ES(0), .OVERFLOW(0)) t1();
  PositAddVersusQuireTemplate #(.WIDTH(8), .ES(1), .OVERFLOW(0)) t2();
  PositAddVersusQuireTemplate #(.WIDTH(6), .ES(0), .OVERFLOW(-1)) t3();
  PositAddVersusQuireTemplate #(.WIDTH(6), .ES(1), .OVERFLOW(10)) t4();
endmodule
