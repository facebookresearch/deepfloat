// Copyright (c) Facebook, Inc. and its affiliates. All Rights Reserved.
// All rights reserved.
//
// This source code is licensed under the license found in the
// LICENSE file in the root directory of this source tree.

module QuireToPositTestTemplate #(parameter WIDTH=8,
                                  parameter ES=1,
                                  parameter OVERFLOW=0,
                                  parameter USE_ADJUST=0)
  ();

  localparam ACC_NON_FRAC = QuireDef::getNonFracBits(WIDTH, ES, OVERFLOW, 0);
  localparam ACC_FRAC = QuireDef::getFracBits(WIDTH, ES, OVERFLOW);

  Kulisch #(.ACC_NON_FRAC(ACC_NON_FRAC), .ACC_FRAC(ACC_FRAC)) quireIn();
  Kulisch #(.ACC_NON_FRAC(ACC_NON_FRAC), .ACC_FRAC(ACC_FRAC)) quireOut();

  PositPacked #(.WIDTH(WIDTH), .ES(ES)) packedIn();
  PositUnpacked #(.WIDTH(WIDTH), .ES(ES)) unpackedOut();

  localparam LOCAL_POSIT_PRODUCT_EXP_BITS = PositDef::getExpProductBits(WIDTH,
                                                                        ES);
  localparam LOCAL_POSIT_PRODUCT_FRAC_BITS = PositDef::getFracProductBits(WIDTH,
                                                                          ES);
  localparam LOCAL_POSIT_FRACTION_BITS = PositDef::getFractionBits(WIDTH, ES);

  PositDecode #(.WIDTH(WIDTH),
                .ES(ES))
  decode(.in(packedIn), .out(unpackedOut));

  logic [LOCAL_POSIT_PRODUCT_EXP_BITS-1:0] outExp;
  logic [LOCAL_POSIT_PRODUCT_FRAC_BITS-1:0] outFrac;
  logic outIsInf;
  logic outSign;

  PositQuireConvert #(.WIDTH(WIDTH),
                      .ES(ES),
                      .USE_ADJUST(0))
  pqc(.in(unpackedOut),
      .adjustScale(),
      .outIsInf,
      .outSign,
      .outIsZero(),
      .outExp,
      .outFrac);

  QuireAdd #(.WIDTH(WIDTH),
             .ES(ES),
             .OVERFLOW(OVERFLOW))
  qa(.fixedExpIn(outExp),
     .fixedValIn(outFrac),
     .fixedSignIn(outSign),
     .fixedInfIn(outIsInf),
     .quireIn,
     .quireOut);

  localparam ADJUST_MUL_SIZE = 4;
  logic signed [ADJUST_MUL_SIZE-1:0] adjustMul;
  PositUnpacked #(.WIDTH(WIDTH), .ES(ES)) positOut();

  QuireToPosit #(.WIDTH(WIDTH),
                 .ES(ES),
                 .OVERFLOW(OVERFLOW),
                 .TRAILING_BITS(2),
                 .USE_ADJUST(USE_ADJUST),
                 .ADJUST_MUL_SIZE(ADJUST_MUL_SIZE))
  qtop(.in(quireOut),
       .adjustMul,
       .out(positOut),
       .trailingBitsOut(),
       .stickyBitOut());

  PositPacked #(.WIDTH(WIDTH), .ES(ES)) packedOut();

  PositEncode #(.WIDTH(WIDTH),
                .ES(ES))
  enc(.in(positOut),
      .out(packedOut));

  integer i;
  real positToFloatRep[*];
  real adjValue;

  // Test to determine whether or not a mathematical operation rounds or
  // calculates a posit within the correct bounds
  task automatic testVal(input real r,
                         input real positToFloatRep[*]);
    bit exact;
    bit bounded;

    if (positOut.data.isInf) begin
      // Our output should be inf
      exact = (positOut.data == positOut.inf());
    end else begin
      exact = (r == positOut.toReal(positOut.data));
    end

    if (packedOut.data == WIDTH'(1'b0)) begin
      // The bounds are either
      // (0, smallest) or (-smallest, 0)
      bounded = r > 0 ?
                r < positToFloatRep[packedOut.data + 1] :
                r > positToFloatRep[packedOut.infPacked() + 1];
    end else if (packedOut.data == {WIDTH{1'b1}}) begin
      // The bounds are (-inf, out - 1)
      bounded = r < positToFloatRep[packedOut.data - 1];
    end else begin
      bounded = r >= 0 ?
                (r > positToFloatRep[packedOut.data - 1] &&
                 r < positToFloatRep[packedOut.data + 1]) :
                (r < positToFloatRep[packedOut.data - 1] &&
                 r > positToFloatRep[packedOut.data + 1]);
    end

    if (!(exact || bounded)) begin
      $display("(%p, %p): error for %b (unp %s %g) vs %g)",
               WIDTH, ES,
               packedOut.data,
               positOut.print(positOut.data),
               positOut.toReal(positOut.data),
               r);
    end
    assert(exact || bounded);

  endtask

  initial begin
    // First, collect the IEEE floating-point representation of all posits that
    // we are testing
    for (i = 0; i < 2 ** WIDTH; ++i) begin
      packedIn.data = i;
      #1 positToFloatRep[i] = unpackedOut.toReal(unpackedOut.data);
    end

    for (i = 0; i < 2 ** WIDTH; ++i) begin
      quireIn.data = quireIn.zero();
      packedIn.data = i;

      if (USE_ADJUST) begin
        // Test positive adjustments
        adjustMul = ADJUST_MUL_SIZE'($urandom_range(2**(ADJUST_MUL_SIZE-1)-1, 0));
        adjValue = 2.0 ** real'(adjustMul);
        #1;
        testVal(unpackedOut.toReal(unpackedOut.data) * adjValue,
                positToFloatRep);

        // Test negative adjustments
        adjustMul = ADJUST_MUL_SIZE'(-$urandom_range(2**(ADJUST_MUL_SIZE-1), 0));
        adjValue = 2.0 ** real'(adjustMul);
        #1;
        testVal(unpackedOut.toReal(unpackedOut.data) * adjValue,
                positToFloatRep);

        // Test no adjustments
        adjustMul = ADJUST_MUL_SIZE'(1'b0);
        adjValue = 1.0;
        #1;
        testVal(unpackedOut.toReal(unpackedOut.data) * adjValue,
                positToFloatRep);

      end else begin
        // No adjustments
        adjustMul = $random;
        #1;
        testVal(unpackedOut.toReal(unpackedOut.data),
                positToFloatRep);
      end
    end
  end
endmodule

module QuireToPositOverflowTestTemplate #(parameter WIDTH=8,
                                          parameter ES=1,
                                          parameter OVERFLOW=0)
  ();
  localparam LOCAL_POSIT_PRODUCT_EXP_BITS = PositDef::getExpProductBits(WIDTH,
                                                                        ES);
  localparam LOCAL_POSIT_PRODUCT_FRAC_BITS = PositDef::getFracProductBits(WIDTH,
                                                                          ES);
  localparam LOCAL_POSIT_FRACTION_BITS = PositDef::getFractionBits(WIDTH, ES);

  PositUnpacked #(.WIDTH(WIDTH), .ES(ES)) positA();
  PositUnpacked #(.WIDTH(WIDTH), .ES(ES)) positB();

  logic [LOCAL_POSIT_PRODUCT_EXP_BITS-1:0] abExp;
  logic [LOCAL_POSIT_PRODUCT_FRAC_BITS-1:0] abFrac;
  logic abIsInf;
  logic abSign;

  PositMultiplyForQuire #(.WIDTH(WIDTH),
                          .ES(ES),
                          .USE_ADJUST(0))
  pmq(.a(positA),
      .b(positB),
      .adjustScale(),
      .abIsInf,
      .abIsZero(),
      .abSign,
      .abExp,
      .abFrac);

  localparam ACC_NON_FRAC = QuireDef::getNonFracBits(WIDTH, ES, OVERFLOW, 0);
  localparam ACC_FRAC = QuireDef::getFracBits(WIDTH, ES, OVERFLOW);

  Kulisch #(.ACC_NON_FRAC(ACC_NON_FRAC), .ACC_FRAC(ACC_FRAC)) quireIn();
  Kulisch #(.ACC_NON_FRAC(ACC_NON_FRAC), .ACC_FRAC(ACC_FRAC)) quireOut();

  QuireAdd #(.WIDTH(WIDTH),
             .ES(ES),
             .OVERFLOW(OVERFLOW))
  qa(.fixedExpIn(abExp),
     .fixedValIn(abFrac),
     .fixedSignIn(abSign),
     .fixedInfIn(abIsInf),
     .quireIn,
     .quireOut);

  PositUnpacked #(.WIDTH(WIDTH), .ES(ES)) positOut();
  logic [1:0] trailingBits;
  logic stickyBit;

  QuireToPosit #(.WIDTH(WIDTH),
                 .ES(ES),
                 .OVERFLOW(OVERFLOW),
                 .TRAILING_BITS(2),
                 .USE_ADJUST(0))
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

  initial begin
    // test zero
    positA.data = positA.zero(1'b0);
    positB.data = positB.zero(1'b0);
    quireIn.data = quireIn.zero();
    #1;

    assert(positOut.data == positOut.zero(1'b0));
    assert(trailingBits == 2'b0);
    assert(stickyBit == 1'b0);

    // test inf
    positA.data = positA.inf();
    positB.data = positB.inf();
    quireIn.data = quireIn.zero();
    #1;

    assert(positOut.data == positOut.inf());
    assert(trailingBits == 2'b0);
    assert(stickyBit == 1'b0);

    positA.data = positA.zero(1'b1);
    positB.data = positB.inf();
    quireIn.data = quireIn.zero();
    #1;

    assert(positOut.data == positOut.inf());
    assert(trailingBits == 2'b0);
    assert(stickyBit == 1'b0);

    positA.data = positA.getMax(1'b0);
    positB.data = positB.one(1'b0);
    positB.data.fraction = positB.data.fraction + 1'b1;
    positB.data.exponent = positB.data.exponent + 1'b1;
    quireIn.data = quireIn.zero();
    #1;

    assert(positOut.data == positOut.getMax(1'b0));
    assert(trailingBits == 2'b0);
    assert(stickyBit == 1'b0);

    positA.data = positA.getMin(1'b0);
    positB.data = positB.one(1'b0);
    positB.data.exponent = positB.data.exponent - 1'b1;
    quireIn.data = quireIn.zero();
    #1;

    assert(positOut.data == positOut.zero(1'b0));
    assert(trailingBits == 2'b10);
    assert(stickyBit == 1'b0);

    positA.data = positA.getMin(1'b0);
    positB.data = positB.one(1'b0);
    positB.data.exponent = positB.data.exponent - 2'd2;
    quireIn.data = quireIn.zero();
    #1;

    assert(positOut.data == positOut.zero(1'b0));
    assert(trailingBits == 2'b01);
    assert(stickyBit == 1'b0);

    positA.data = positA.getMin(1'b0);
    positB.data = positB.one(1'b0);
    positB.data.exponent = positB.data.exponent - 2'd3;
    quireIn.data = quireIn.zero();
    #1;

    assert(positOut.data == positOut.zero(1'b0));
    assert(trailingBits == 2'b0);
    assert(stickyBit == 1'b1);
  end
endmodule

module QuireToPositStickyBits #(parameter WIDTH=8,
                                parameter ES=1,
                                parameter OVERFLOW=0)
  ();

  localparam ACC_NON_FRAC = QuireDef::getNonFracBits(WIDTH, ES, OVERFLOW, 0);
  localparam ACC_FRAC = QuireDef::getFracBits(WIDTH, ES, OVERFLOW);

  Kulisch #(.ACC_NON_FRAC(ACC_NON_FRAC), .ACC_FRAC(ACC_FRAC)) quireIn();

  // Standard r2ne trailing bits
  PositUnpacked #(.WIDTH(WIDTH), .ES(ES)) positOut2();
  PositUnpacked #(.WIDTH(WIDTH), .ES(ES)) positOutRound2();
  logic [1:0] trailingBits2;
  logic stickyBit2;

  QuireToPosit #(.WIDTH(WIDTH),
                 .ES(ES),
                 .OVERFLOW(OVERFLOW),
                 .TRAILING_BITS(2),
                 .USE_ADJUST(0),
                 .ADJUST_MUL_SIZE(1))
  qtop2(.in(quireIn),
       .adjustMul(1'b0),
       .out(positOut2),
       .trailingBitsOut(trailingBits2),
       .stickyBitOut(stickyBit2));

  PositRoundToNearestEven #(.WIDTH(WIDTH),
                            .ES(ES))
  r2ne2(.in(positOut2),
        .trailingBits(trailingBits2),
        .stickyBit(stickyBit2),
        .out(positOutRound2));

  // Extended r2ne trailing bits
  PositUnpacked #(.WIDTH(WIDTH), .ES(ES)) positOut8();
  PositUnpacked #(.WIDTH(WIDTH), .ES(ES)) positOutRound8();
  logic [7:0] trailingBits8;
  logic stickyBit8;

  QuireToPosit #(.WIDTH(WIDTH),
                 .ES(ES),
                 .OVERFLOW(OVERFLOW),
                 .TRAILING_BITS(8),
                 .USE_ADJUST(0),
                 .ADJUST_MUL_SIZE(1))
  qtop8(.in(quireIn),
        .adjustMul(1'b0),
        .out(positOut8),
        .trailingBitsOut(trailingBits8),
        .stickyBitOut(stickyBit8));

  logic [1:0] trailingBitsNew8;
  logic stickyBitNew8;

  always_comb begin
    trailingBitsNew8 = trailingBits8[7:6];
    stickyBitNew8 = |trailingBits8[5:0] | stickyBit8;
  end

  PositRoundToNearestEven #(.WIDTH(WIDTH),
                            .ES(ES))
  r2ne8(.in(positOut8),
        .trailingBits(trailingBitsNew8),
        .stickyBit(stickyBitNew8),
        .out(positOutRound8));

  integer i;

  initial begin
    quireIn.data = quireIn.zero();
    for (i = 0; i < 10000; ++i) begin
      quireIn.data.bits = $random;
      #1;

      assert(positOutRound2.data == positOutRound8.data);
      assert(trailingBits2 == trailingBitsNew8);
      assert(stickyBit2 == stickyBitNew8);
    end
  end
endmodule

module QuireToPositTest();
  QuireToPositStickyBits #(.WIDTH(8), .ES(1), .OVERFLOW(0))
  sticky();

  QuireToPositTestTemplate #(.WIDTH(8), .ES(1), .OVERFLOW(0), .USE_ADJUST(0))
  t1();
  QuireToPositTestTemplate #(.WIDTH(8), .ES(1), .OVERFLOW(-1), .USE_ADJUST(0))
  t2();
  QuireToPositTestTemplate #(.WIDTH(8), .ES(1), .OVERFLOW(5), .USE_ADJUST(0))
  t3();

  QuireToPositTestTemplate #(.WIDTH(8), .ES(1), .OVERFLOW(0), .USE_ADJUST(1))
  t4();
  QuireToPositTestTemplate #(.WIDTH(8), .ES(1), .OVERFLOW(-1), .USE_ADJUST(1))
  t5();
  QuireToPositTestTemplate #(.WIDTH(8), .ES(1), .OVERFLOW(5), .USE_ADJUST(1))
  t6();

  QuireToPositTestTemplate #(.WIDTH(10), .ES(2), .OVERFLOW(0), .USE_ADJUST(1))
  t7();

  QuireToPositOverflowTestTemplate #(.WIDTH(8), .ES(1), .OVERFLOW(0))
  t8();
endmodule
