// Copyright (c) Facebook, Inc. and its affiliates. All Rights Reserved.
// All rights reserved.
//
// This source code is licensed under the license found in the
// LICENSE file in the root directory of this source tree.

module PositMultiply_PackedToPacked #(parameter WIDTH=8,
                                      parameter ES=1,
                                      parameter TRAILING_BITS=2)
  (PositPacked.InputIf a,
   PositPacked.InputIf b,
   PositPacked.OutputIf out,
   output [TRAILING_BITS-1:0] trailingBits,
   output stickyBit);

  PositUnpacked #(.WIDTH(WIDTH), .ES(ES)) decA();
  PositUnpacked #(.WIDTH(WIDTH), .ES(ES)) decB();
  PositUnpacked #(.WIDTH(WIDTH), .ES(ES)) decOut();
  PositUnpacked #(.WIDTH(WIDTH), .ES(ES)) roundOut();

  PositDecode #(.WIDTH(WIDTH), .ES(ES))
  decodeA(.in(a), .out(decA));

  PositDecode #(.WIDTH(WIDTH), .ES(ES))
  decodeB(.in(b), .out(decB));

  PositMultiply #(.WIDTH(WIDTH), .ES(ES))
  add(.a(decA),
      .b(decB),
      .out(decOut),
      .trailingBits(trailingBits),
      .stickyBit(stickyBit));

  PositRoundToNearestEven #(.WIDTH(WIDTH), .ES(ES))
  prne(.in(decOut),
       .trailingBits,
       .stickyBit,
       .out(roundOut));

  PositEncode #(.WIDTH(WIDTH), .ES(ES))
  encode(.in(roundOut), .out(out));
endmodule

module PositMulTestTemplate #(parameter WIDTH=8,
                              parameter ES=1,
                              parameter RANDOM=0)
  ();
  localparam TRAILING_BITS = 2;

  real positToFloatRep[*];

  PositPacked #(.WIDTH(WIDTH), .ES(ES)) a();
  PositPacked #(.WIDTH(WIDTH), .ES(ES)) b();
  PositPacked #(.WIDTH(WIDTH), .ES(ES)) out();

  bit [TRAILING_BITS-1:0] trailingBits;
  bit stickyBit;

  PositUnpacked #(.WIDTH(WIDTH), .ES(ES)) decOut();
  PositUnpacked #(.WIDTH(WIDTH), .ES(ES)) decA();
  PositUnpacked #(.WIDTH(WIDTH), .ES(ES)) decB();

  PositMultiply_PackedToPacked #(.WIDTH(WIDTH), .ES(ES))
  mod(.*);

  PositDecode #(.WIDTH(WIDTH), .ES(ES))
  decodeA(.in(a),
          .out(decA));

  PositDecode #(.WIDTH(WIDTH), .ES(ES))
  decodeB(.in(b),
          .out(decB));

  PositDecode #(.WIDTH(WIDTH), .ES(ES))
  decodeOut(.in(out),
            .out(decOut));

  integer i;
  integer j;

  real floatAnswer;
  real positAnswer;
  bit exact;
  bit bounded;

  task testMul(bit [WIDTH-1:0] i,
               bit [WIDTH-1:0] j);
    a.data.bits = i;
    b.data.bits = j;

    #1;

    // FIXME: use positDef.testVal
    if (decA.data.isInf || decB.data.isInf) begin
      // Our output should be inf
      exact = (decOut.data == decOut.inf());
    end else begin
      floatAnswer = decOut.toReal(decA.data) * decOut.toReal(decB.data);
      positAnswer = decOut.toReal(decOut.data);

      exact = (floatAnswer == positAnswer);
    end

    if (out.data == WIDTH'(1'b0)) begin
      // The bounds are either
      // (0, smallest) or (-smallest, 0)
      bounded = floatAnswer > 0 ?
                floatAnswer < positToFloatRep[out.data + 1] :
                floatAnswer > positToFloatRep[out.infPacked() + 1];
    end else if (out.data == {WIDTH{1'b1}}) begin
      // The bounds are (-inf, out - 1)
      bounded = floatAnswer < positToFloatRep[out.data - 1];
    end else begin
      bounded = floatAnswer >= 0 ?
                (floatAnswer > positToFloatRep[out.data - 1] &&
                 floatAnswer < positToFloatRep[out.data + 1]) :
                (floatAnswer < positToFloatRep[out.data - 1] &&
                 floatAnswer > positToFloatRep[out.data + 1]);
    end

    assert(exact || bounded);
  endtask

  initial begin
    // First, collect the IEEE floating-point representation of all posits that
    // we are testing
    for (i = 0; i < 2 ** WIDTH; ++i) begin
      a.data.bits = i;
      #1 positToFloatRep[a.data.bits] = decA.toReal(decA.data);
    end

    // Test all pairs of addends
    if (RANDOM > 0) begin
      for (i = 0; i < RANDOM; ++i) begin
        testMul($random, $random);
      end
    end else begin
      for (i = 0; i < 2 ** WIDTH; ++i) begin
        for (j = 0; j < 2 ** WIDTH; ++j) begin
          testMul(i, j);
        end
      end
    end
  end
endmodule

module PositMultiplyTest();
  PositMulTestTemplate #(.WIDTH(8),
                         .ES(1),
                         .RANDOM(0))
  add8_1();

  PositMulTestTemplate #(.WIDTH(7),
                         .ES(1),
                         .RANDOM(0))
  add7_1();

  PositMulTestTemplate #(.WIDTH(16),
                         .ES(2),
                         .RANDOM(2000))
  add16_2();
endmodule
