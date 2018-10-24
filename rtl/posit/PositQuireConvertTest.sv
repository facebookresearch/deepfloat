// Copyright (c) Facebook, Inc. and its affiliates. All Rights Reserved.
// All rights reserved.
//
// This source code is licensed under the license found in the
// LICENSE file in the root directory of this source tree.

module PositQuireConvertTestTemplate #(parameter WIDTH=8,
                                       parameter ES=1,
                                       parameter OVERFLOW=0)
  ();
  PositUnpacked #(.WIDTH(WIDTH), .ES(ES)) positDef();

  localparam ACC_NON_FRAC = QuireDef::getNonFracBits(WIDTH, ES, OVERFLOW, 0);
  localparam ACC_FRAC = QuireDef::getFracBits(WIDTH, ES, OVERFLOW);

  localparam LOCAL_EXP_PRODUCT_BITS = PositDef::getExpProductBits(WIDTH, ES);
  localparam LOCAL_FRAC_PRODUCT_BITS = PositDef::getFracProductBits(WIDTH, ES);
  localparam LOCAL_POSIT_FRACTION_BITS = PositDef::getFractionBits(WIDTH, ES);

  PositPacked #(.WIDTH(WIDTH), .ES(ES)) packedIn();
  PositUnpacked #(.WIDTH(WIDTH), .ES(ES)) unpackedOut();

  PositDecode #(.WIDTH(WIDTH),
                .ES(ES))
  decode(.in(packedIn), .out(unpackedOut));

  logic [LOCAL_EXP_PRODUCT_BITS-1:0] outExp;
  logic [LOCAL_FRAC_PRODUCT_BITS-1:0] outFrac;
  logic outIsInf;
  logic outSign;

  PositQuireConvert #(.WIDTH(WIDTH),
                      .ES(ES),
                      .USE_ADJUST(0),
                      .ADJUST_SCALE_SIZE(1))
  pqc(.in(unpackedOut),
      .adjustScale(),
      .outIsInf,
      .outSign,
      .outIsZero(),
      .outExp,
      .outFrac);

  Kulisch #(.ACC_NON_FRAC(ACC_NON_FRAC), .ACC_FRAC(ACC_FRAC)) quireIn();
  Kulisch #(.ACC_NON_FRAC(ACC_NON_FRAC), .ACC_FRAC(ACC_FRAC)) quireOut();

  QuireAdd #(.WIDTH(WIDTH),
             .ES(ES),
             .OVERFLOW(OVERFLOW))
  qa(.fixedExpIn(outExp),
     .fixedValIn(outFrac),
     .fixedSignIn(outSign),
     .fixedInfIn(outIsInf),
     .quireIn,
     .quireOut);

  PositUnpacked #(.WIDTH(WIDTH), .ES(ES)) positOut();

  logic [1:0] trailingBits;
  logic stickyBit;

  QuireToPosit #(.WIDTH(WIDTH),
                 .ES(ES),
                 .OVERFLOW(OVERFLOW),
                 .TRAILING_BITS(2))
  qtop(.in(quireOut),
       .adjustMul(),
       .out(positOut),
       .trailingBitsOut(trailingBits),
       .stickyBitOut(stickyBit));

  PositPacked #(.WIDTH(WIDTH), .ES(ES)) packedOut();

  PositEncode #(.WIDTH(WIDTH),
                .ES(ES))
  enc(.in(positOut),
      .out(packedOut));

  integer i;

  initial begin
    for (i = 0; i < 2 ** WIDTH; ++i) begin
      quireIn.data = quireIn.zero();
      packedIn.data = i;

      #1;
      if (packedIn.data != packedOut.data) begin
        $display("%p (%s %g) -> (%s %g)",
                 i,
                 positDef.print(unpackedOut.data),
                 positDef.toReal(unpackedOut.data),
                 positDef.print(positOut.data),
                 positDef.toReal(positOut.data));
      end

      assert(packedIn.data == packedOut.data);
      assert(trailingBits == 2'b0);
      assert(stickyBit == 1'b0);
    end
  end
endmodule

module PositQuireConvertTest();
  PositQuireConvertTestTemplate #(.WIDTH(8), .ES(1), .OVERFLOW(-1)) t1();
  // PositQuireConvertTestTemplate #(.WIDTH(8), .ES(1), .OVERFLOW(0)) t2();
  // PositQuireConvertTestTemplate #(.WIDTH(8), .ES(1), .OVERFLOW(10)) t3();

  // PositQuireConvertTestTemplate #(.WIDTH(7), .ES(2), .OVERFLOW(-1)) t4();
  // PositQuireConvertTestTemplate #(.WIDTH(7), .ES(2), .OVERFLOW(0)) t5();
  // PositQuireConvertTestTemplate #(.WIDTH(7), .ES(2), .OVERFLOW(10)) t6();
endmodule
