// Copyright (c) Facebook, Inc. and its affiliates. All Rights Reserved.
// All rights reserved.
//
// This source code is licensed under the license found in the
// LICENSE file in the root directory of this source tree.

// Combinational only
module PositAdd_PackedToPacked #(parameter WIDTH=8,
                                 parameter ES=0,
                                 parameter TRAILING_BITS=2)
  (PositPacked.InputIf a,
   PositPacked.InputIf b,
   PositPacked.OutputIf out,
   output [TRAILING_BITS-1:0] trailingBits,
   output stickyBit,
   input subtract);
  PositUnpacked #(.WIDTH(WIDTH), .ES(ES)) decA();
  PositUnpacked #(.WIDTH(WIDTH), .ES(ES)) decB();
  PositUnpacked #(.WIDTH(WIDTH), .ES(ES)) decOut();
  PositUnpacked #(.WIDTH(WIDTH), .ES(ES)) roundOut();

  PositDecode #(.WIDTH(WIDTH), .ES(ES))
  decodeA(.in(a), .out(decA));

  PositDecode #(.WIDTH(WIDTH), .ES(ES))
  decodeB(.in(b), .out(decB));

  PositAdd #(.WIDTH(WIDTH), .ES(ES))
  add(.a(decA),
      .b(decB),
      .out(decOut),
      .trailingBits(trailingBits),
      .stickyBit(stickyBit),
      .subtract);

  PositRoundToNearestEven #(.WIDTH(WIDTH), .ES(ES))
  prne(.in(decOut),
       .trailingBits,
       .stickyBit,
       .out(roundOut));

  PositEncode #(.WIDTH(WIDTH), .ES(ES))
  encode(.in(roundOut), .out(out));
endmodule

module PositAddTestTemplate #(parameter WIDTH=8,
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
  bit subtract;

  PositUnpacked #(.WIDTH(WIDTH), .ES(ES)) decOut();
  PositUnpacked #(.WIDTH(WIDTH), .ES(ES)) decA();
  PositUnpacked #(.WIDTH(WIDTH), .ES(ES)) decB();

  PositAdd_PackedToPacked #(.WIDTH(WIDTH), .ES(ES))
  adder(.*);

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

  task testAdd(bit [WIDTH-1:0] i,
               bit [WIDTH-1:0] j,
               bit sub);
    a.data.bits = i;
    b.data.bits = j;
    subtract = sub;

    #1;

    // FIXME: use positDef.testVal
    if (decA.data.isInf || decB.data.isInf) begin
      // Our output should be inf
      exact = (decOut.data == decOut.inf());
    end else begin
      floatAnswer = sub ?
                    decOut.toReal(decA.data) - decOut.toReal(decB.data) :
                    decOut.toReal(decA.data) + decOut.toReal(decB.data);
      positAnswer = decOut.toReal(decOut.data);

      exact = (floatAnswer == positAnswer);
    end

    if (out.data.bits == WIDTH'(1'b0)) begin
      // The bounds are either
      // (0, smallest) or (-smallest, 0)
      bounded = floatAnswer > 0 ?
                floatAnswer < positToFloatRep[out.data.bits + 1] :
                floatAnswer > positToFloatRep[out.infPacked() + 1];
    end else if (out.data.bits == {WIDTH{1'b1}}) begin
      // The bounds are (-inf, out - 1)
      bounded = floatAnswer < positToFloatRep[out.data.bits - 1];
    end else begin
      bounded = floatAnswer >= 0 ?
                (floatAnswer > positToFloatRep[out.data.bits - 1] &&
                 floatAnswer < positToFloatRep[out.data.bits + 1]) :
                (floatAnswer < positToFloatRep[out.data.bits - 1] &&
                 floatAnswer > positToFloatRep[out.data.bits + 1]);
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
        testAdd($random, $random, 1'b0);
        testAdd($random, $random, 1'b1);
      end
    end else begin
      for (i = 0; i < 2 ** WIDTH; ++i) begin
        for (j = 0; j < 2 ** WIDTH; ++j) begin
          testAdd(i, j, 1'b0);
          testAdd(i, j, 1'b1);
        end
      end
    end
  end
endmodule

module PositAddTest();
  PositAddTestTemplate #(.WIDTH(7),
                         .ES(0),
                         .RANDOM(0))
  add7_0();

  PositAddTestTemplate #(.WIDTH(7),
                         .ES(1),
                         .RANDOM(0))
  add7_1();

  PositAddTestTemplate #(.WIDTH(16),
                         .ES(2),
                         .RANDOM(2000))
  add8_2();
endmodule
