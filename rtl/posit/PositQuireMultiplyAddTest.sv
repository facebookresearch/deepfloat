// Copyright (c) Facebook, Inc. and its affiliates. All Rights Reserved.
// All rights reserved.
//
// This source code is licensed under the license found in the
// LICENSE file in the root directory of this source tree.

// c += a * b
module PositQuireMultiplyAdd_UnpackedToQuire #(parameter WIDTH=8,
                                               parameter ES=1,
                                               parameter OVERFLOW=0)
  (PositUnpacked.InputIf a,
   PositUnpacked.InputIf b,
   Kulisch.InputIf c,
   Kulisch.OutputIf out);

  // Size of the product a * b
  localparam EXP_PRODUCT_BITS = PositDef::getExpProductBits(WIDTH, ES);
  localparam FRAC_PRODUCT_BITS = PositDef::getFracProductBits(WIDTH, ES);

  logic [EXP_PRODUCT_BITS-1:0] abExp;
  logic [FRAC_PRODUCT_BITS-1:0] abFrac;

  logic abSign;
  logic abIsInf;
  logic abIsZero;

  PositMultiplyForQuire #(.WIDTH(WIDTH),
                          .ES(ES),
                          .USE_ADJUST(0))
  mult(.a,
       .b,
       .adjustScale(),
       .abIsInf,
       .abIsZero,
       .abSign,
       .abExp,
       .abFrac);

  QuireAdd #(.WIDTH(WIDTH),
             .ES(ES),
             .OVERFLOW(OVERFLOW))
  adder(.fixedExpIn(abExp),
        .fixedValIn(abFrac),
        .fixedSignIn(abSign),
        .fixedInfIn(abIsInf),
        .quireIn(c),
        .quireOut(out));
endmodule

module PositQuireMultiplyAddTest();
  localparam WIDTH = 8;
  localparam ES = 1;
  localparam OVERFLOW = 0;

  localparam ACC_NON_FRAC = QuireDef::getNonFracBits(WIDTH, ES, OVERFLOW, 0);
  localparam ACC_FRAC = QuireDef::getFracBits(WIDTH, ES, OVERFLOW);

  Kulisch #(.ACC_NON_FRAC(ACC_NON_FRAC), .ACC_FRAC(ACC_FRAC)) quireIn();
  Kulisch #(.ACC_NON_FRAC(ACC_NON_FRAC), .ACC_FRAC(ACC_FRAC)) quireOut();
  PositUnpacked #(.WIDTH(WIDTH), .ES(ES)) positOut();

  PositUnpacked #(.WIDTH(WIDTH), .ES(ES)) a();
  PositUnpacked #(.WIDTH(WIDTH), .ES(ES)) b();

  PositPacked #(.WIDTH(WIDTH), .ES(ES)) packedIn();
  PositUnpacked #(.WIDTH(WIDTH), .ES(ES)) unpackedOut();

  PositDecode #(.WIDTH(WIDTH),
                .ES(ES))
  decode(.in(packedIn), .out(unpackedOut));

  PositQuireMultiplyAdd_UnpackedToQuire #(.WIDTH(WIDTH),
                                          .ES(ES),
                                          .OVERFLOW(OVERFLOW))
  madd(.a,
       .b,
       .c(quireIn),
       .out(quireOut));

  logic [1:0] trailingBits;
  logic stickyBit;

  QuireToPosit #(.WIDTH(WIDTH),
                 .ES(ES),
                 .OVERFLOW(OVERFLOW),
                 .TRAILING_BITS(2))
  qtop(.in(quireOut),
       .out(positOut),
       .adjustMul(1'b0),
       .trailingBitsOut(trailingBits),
       .stickyBitOut(stickyBit));

  Kulisch #(.ACC_NON_FRAC(ACC_NON_FRAC), .ACC_FRAC(ACC_FRAC)) qIn();
  Kulisch #(.ACC_NON_FRAC(ACC_NON_FRAC), .ACC_FRAC(ACC_FRAC)) qOut();

  PositUnpacked #(.WIDTH(WIDTH), .ES(ES)) vIn();
  PositUnpacked #(.WIDTH(WIDTH), .ES(ES)) result();

  task automatic testOverflow();
    if (OVERFLOW > 0 || OVERFLOW == -1) begin
      integer i;

      qIn.data = qIn.zero();
      qOut.data = qOut.zero();

      // We should be able to accumulate 2^(OVERFLOW+1)-1 sums
      for (i = 0; i < 2**(OVERFLOW+1)-1; ++i) begin
        a.data = a.getMax(1'b0);
        b.data = b.one(1'b0);
        quireIn.data = qIn.data;
        #1;

        qOut.data = quireOut.data;
        qIn.data = qOut.data;
      end

      // We should not have overflowed yet
      assert(!qOut.data.isOverflow);

      // This should cause the quire to overflow
      a.data = a.getMax(1'b0);
      b.data = b.one(1'b0);
      quireIn.data = qIn.data;
      #1;
      qOut.data = quireOut.data;

      assert(qOut.data.isOverflow);
      assert(!qOut.data.overflowSign);
    end
  endtask

  task testUnderflow();
    integer i;
    automatic bit sign = 1'b1;

    qIn.data = qIn.zero();
    qOut.data = qOut.zero();

    // We should be able to accumulate 2^max signed exp - 1 sums
    for (i = 0; i < 2 ** PositDef::getMaxSignedExponent(WIDTH, ES) - 1; ++i) begin
      a.data = a.getMin(sign);
      b.data = b.getMin(1'b0);
      quireIn.data = qIn.data;
      #1;
      result.data = positOut.data;
      qOut.data = quireOut.data;

      assert(positOut.isZero(positOut.data));
      qIn.data = qOut.data;
    end

    // One more should push us over
    a.data = a.getMin(sign);
    b.data = b.getMin(1'b0);
    quireIn.data = qIn.data;
    #1;
    qOut.data = quireOut.data;

    assert(positOut.data == positOut.getMin(sign));
  endtask

  // 1.0 x P = P for all posits
  task testOne();
    integer i;

    for (i = 0; i < 2 ** WIDTH; ++i) begin
      qIn.data = qIn.zero();
      qOut.data = qOut.zero();

      packedIn.data = i;
      #1;

      a.data = a.one(1'b0);
      b.data = unpackedOut.data;
      quireIn.data = qIn.data;
      #1;
      result.data = positOut.data;
      qOut.data = quireOut.data;

      if (!(unpackedOut.data == result.data)) begin
        $display("%p quire %s\n%s vs %s",
                 i,
                 quireOut.print(quireOut.data),
                 unpackedOut.print(unpackedOut.data),
                 result.print(result.data));

        assert(unpackedOut.data == result.data);
      end
    end
  endtask

  // 1.0 x P - 1.0 x P = 0 for all posits except inf
  task testSumToZero();
    integer i;

    for (i = 0; i < 2 ** WIDTH; ++i) begin
      qIn.data = qIn.zero();
      qOut.data = qOut.zero();

      packedIn.data = i;
      #1;

      vIn.data = unpackedOut.data;

      if (!vIn.isInf(vIn.data)) begin
        a.data = a.one(1'b0);
        b.data = vIn.data;
        quireIn.data = qIn.data;
        #1;
        result.data = positOut.data;
        qOut.data = quireOut.data;

        if (vIn.data != result.data) begin
          assert(vIn.data == result.data);
          $display("%p qu %s\npos a %s\npos %s\n",
                   i,
                   quireOut.print(quireOut.data),
                   vIn.print(vIn.data),
                   positOut.print(positOut.data));

        end

        qIn.data = qOut.data;

        if (!vIn.isZero(vIn.data)) begin
          vIn.data.sign = ~vIn.data.sign;
        end

        a.data = a.one(1'b0);
        b.data = vIn.data;
        quireIn.data = qIn.data;
        #1;
        result.data = positOut.data;
        qOut.data = quireOut.data;

        if (result.zero(1'b0) != result.data) begin
          $display("%p qu %s pos %s\n",
                   i,
                   quireOut.print(quireOut.data),
                   positOut.print(positOut.data));
          assert(result.zero(1'b0) == result.data);
        end
      end
    end
  endtask

  initial begin
    packedIn.data = packedIn.zeroPacked();
    quireIn.data = quireIn.zero();
    a.data = a.zero(1'b0);
    b.data = b.zero(1'b0);

    testUnderflow();
    testOverflow();
    testOne();
    testSumToZero();
  end
endmodule
