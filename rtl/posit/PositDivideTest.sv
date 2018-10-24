// Copyright (c) Facebook, Inc. and its affiliates. All Rights Reserved.
// All rights reserved.
//
// This source code is licensed under the license found in the
// LICENSE file in the root directory of this source tree.

module PositDivideTestTemplate #(parameter WIDTH=8,
                                 parameter ES=1,
                                 parameter TRAILING_BITS=2,
                                 parameter STICKY_BITS=1,
                                 parameter RANDOM=0)
  ();
  real positToFloatRep[*];

  PositPacked #(.WIDTH(WIDTH), .ES(ES)) a();
  PositPacked #(.WIDTH(WIDTH), .ES(ES)) b();
  PositPacked #(.WIDTH(WIDTH), .ES(ES)) out();

  localparam LOCAL_FRACTION_BITS = PositDef::getFractionBits(WIDTH, ES);

  integer i;
  integer j;
  integer k;
  integer numRand;

  real floatAnswer;
  real positAnswer;
  bit exact;
  bit bounded;

  logic clock;
  logic reset;

  // clock generator
  initial begin : clockgen
    clock <= 1'b0;
    forever #5 clock = ~clock;
  end

  PositUnpacked #(.WIDTH(WIDTH), .ES(ES)) decA();
  PositUnpacked #(.WIDTH(WIDTH), .ES(ES)) decB();

  PositDecode #(.WIDTH(WIDTH), .ES(ES))
  decodeA(.in(a), .out(decA));

  PositDecode #(.WIDTH(WIDTH), .ES(ES))
  decodeB(.in(b), .out(decB));

  PositUnpacked #(.WIDTH(WIDTH), .ES(ES)) divOut();
  logic divByZero;
  logic [TRAILING_BITS-1:0] trailingBits;
  logic stickyBit;

  PositDivide #(.WIDTH(WIDTH),
                .ES(ES),
                .TRAILING_BITS(TRAILING_BITS),
                .STICKY_BITS(STICKY_BITS))
  div(.a(decA),
      .b(decB),
      .out(divOut),
      .divByZero,
      .trailingBits,
      .stickyBit,
      .clock,
      .reset);

  PositUnpacked #(.WIDTH(WIDTH), .ES(ES)) roundOut();

  PositRoundToNearestEven #(.WIDTH(WIDTH),
                            .ES(ES))
  r2ne(.in(divOut),
       .trailingBits,
       .stickyBit,
       .out(roundOut));

  PositPacked #(.WIDTH(WIDTH), .ES(ES)) roundPacked();

  PositEncode #(.WIDTH(WIDTH),
                .ES(ES))
  pe(.in(roundOut),
     .out(roundPacked));

  localparam CYCLES = 1 + // A1
                      LOCAL_FRACTION_BITS + TRAILING_BITS + STICKY_BITS + 1 + // A2
                      + LOCAL_FRACTION_BITS + // B2
                      1; // PositDivide

  task testDiv(bit [WIDTH-1:0] i,
               bit [WIDTH-1:0] j);
    a.data.bits = i;
    b.data.bits = j;

    for (k = 0; k < CYCLES; ++k) begin
      @(posedge clock);

      // Make sure the pipeline works; fill the inputs with garbage
      a.data.bits = WIDTH'(1'b0);
      b.data.bits = WIDTH'(1'b0);
    end

    // Restore the original inputs
    a.data.bits = i;
    b.data.bits = j;

    #1;

    // FIXME: use positDef.testVal
    if (decA.data.isInf || decB.data.isZero) begin
      // Our output should be inf
      exact = (roundOut.data == roundOut.inf());
    end else begin
      floatAnswer = decA.toReal(decA.data) / decB.toReal(decB.data);
      positAnswer = roundOut.toReal(roundOut.data);

      exact = (floatAnswer == positAnswer) ||
              (roundOut.data == roundOut.inf() && decB.toReal(decB.data) == 0);
    end

    if (roundPacked.data == WIDTH'(1'b0)) begin
      // The bounds are either
      // (0, smallest) or (-smallest, 0)
      bounded = floatAnswer > 0 ?
                floatAnswer < positToFloatRep[roundPacked.data + 1] :
                floatAnswer > positToFloatRep[roundPacked.infPacked() + 1];
    end else if (roundPacked.data == {WIDTH{1'b1}}) begin
      // The bounds are (-inf, roundPacked - 1)
      bounded = floatAnswer < positToFloatRep[roundPacked.data - 1];
    end else begin
      bounded = floatAnswer >= 0 ?
                (floatAnswer > positToFloatRep[roundPacked.data - 1] &&
                 floatAnswer < positToFloatRep[roundPacked.data + 1]) :
                (floatAnswer < positToFloatRep[roundPacked.data - 1] &&
                 floatAnswer > positToFloatRep[roundPacked.data + 1]);
    end

    assert(exact || bounded);
    // if (!(exact || bounded)) begin
      // $display("%s: %p %p, got %s (v %g) / %s (v %g) = %s (v %g vs %g)%s",
      //          exact ? "EXACT" : (bounded ? "BOUND" : "ERROR"),
      //          i, j,
      //          positDef.print(decA),
      //          positDef.toReal(decA),
      //          positDef.print(decB),
      //          positDef.toReal(decB),
      //          positDef.print(roundOut),
      //          positAnswer,
      //          floatAnswer,
      //          divByZero ? " DIV0" : "");
    // end
  endtask

  initial begin
    // First, collect the IEEE floating-point representation of all posits that
    // we are testing
    for (i = 0; i < 2 ** WIDTH; ++i) begin
      a.data.bits = i;
      #1 positToFloatRep[a.data.bits] = decA.toReal(decA.data);
    end

    reset = 1;
    @(posedge clock);
    reset = 0;

    if (RANDOM > 0) begin
      for (i = 0; i < RANDOM; ++i) begin
        testDiv($random, $random);
      end
    end else begin
      for (i = 0; i < 2 ** WIDTH; ++i) begin
        for (j = 0; j < 2 ** WIDTH; ++j) begin
          testDiv(i, j);
        end
      end
    end

    disable clockgen;
  end
endmodule

module PositDivideTest();
  PositDivideTestTemplate #(.WIDTH(7),
                            .ES(1),
                            .TRAILING_BITS(2),
                            .STICKY_BITS(1),
                            .RANDOM(0))
  div7_1();

  PositDivideTestTemplate #(.WIDTH(7),
                            .ES(0),
                            .TRAILING_BITS(2),
                            .STICKY_BITS(1),
                            .RANDOM(0))
  div7_0();

  PositDivideTestTemplate #(.WIDTH(16),
                            .ES(2),
                            .TRAILING_BITS(2),
                            .STICKY_BITS(1),
                            .RANDOM(2000))
  div16_2();
endmodule
