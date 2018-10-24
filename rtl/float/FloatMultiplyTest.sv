// Copyright (c) Facebook, Inc. and its affiliates. All Rights Reserved.
// All rights reserved.
//
// This source code is licensed under the license found in the
// LICENSE file in the root directory of this source tree.

// FloatMultiply + RoundToNearestEven
module FloatMultiply_RoundToNearestEven #(parameter EXP_IN_A=8,
                                          parameter FRAC_IN_A=23,
                                          parameter EXP_IN_B=8,
                                          parameter FRAC_IN_B=23,
                                          parameter EXP_OUT=8,
                                          parameter FRAC_OUT=23)
  (Float.InputIf inA,
   Float.InputIf inB,
   Float.OutputIf out,
   input reset,
   input clock);

  localparam TRAILING_BITS = 2;

  Float #(.EXP(EXP_OUT), .FRAC(FRAC_OUT)) outPreRound();
  Float #(.EXP(EXP_OUT), .FRAC(FRAC_OUT)) outPostRound();
  logic [TRAILING_BITS-1:0] trailingBits;
  logic stickyBit;
  logic isNan;

  FloatMultiply #(.EXP_IN_A(EXP_IN_A),
                  .FRAC_IN_A(FRAC_IN_A),
                  .EXP_IN_B(EXP_IN_B),
                  .FRAC_IN_B(FRAC_IN_B),
                  .EXP_OUT(EXP_OUT),
                  .FRAC_OUT(FRAC_OUT),
                  .TRAILING_BITS(TRAILING_BITS))
  mult(.inA,
      .inB,
      .out(outPreRound),
      .trailingBits,
      .stickyBit,
      .isNan,
      .reset,
      .clock);

  FloatRoundToNearestEven #(.EXP(EXP_OUT),
                            .FRAC(FRAC_OUT))
  round(.in(outPreRound),
        .trailingBitsIn(trailingBits),
        .stickyBitIn(stickyBit),
        .isNanIn(isNan),
        .out(outPostRound));

  always_ff @(posedge clock) begin
    if (reset) begin
      out.data <= out.getZero(1'b0);
    end else begin
      out.data <= outPostRound.data;
    end
  end
endmodule

module FloatMultiplyTest();
  parameter EXP = 11;
  parameter FRAC = 52;
  parameter CLOCK_PERIOD = 10;

  Float #(.EXP(EXP), .FRAC(FRAC)) inA();
  Float #(.EXP(EXP), .FRAC(FRAC)) inB();
  Float #(.EXP(EXP), .FRAC(FRAC)) out();

  logic reset;
  logic clock;

  bit randomSignA;
  bit [EXP-1:0] randomExponentA;
  bit [FRAC-1:0] randomFractionA;

  bit randomSignB;
  bit [EXP-1:0] randomExponentB;
  bit [FRAC-1:0] randomFractionB;

  integer randomExponentDiff;
  integer i;

  real nan;
  real posInf;

  FloatMultiply_RoundToNearestEven #(.EXP_IN_A(EXP),
                                     .FRAC_IN_A(FRAC),
                                     .EXP_IN_B(EXP),
                                     .FRAC_IN_B(FRAC),
                                     .EXP_OUT(EXP),
                                     .FRAC_OUT(FRAC))
  mult(.*);

  Float #(.EXP(EXP), .FRAC(FRAC)) testAStruct();
  Float #(.EXP(EXP), .FRAC(FRAC)) testBStruct();
  Float #(.EXP(EXP), .FRAC(FRAC)) testCStruct();

  task automatic testFloatImpl(input real testA,
                               input real testB);
    automatic real testC;

    automatic logic [FRAC-1:0] largestFrac;
    automatic logic [FRAC-1:0] smallestFrac;

    testC = testA * testB;
    testAStruct.data = $realtobits(testA);
    testBStruct.data = $realtobits(testB);
    testCStruct.data = $realtobits(testC);

    inA.data = $realtobits(testA);
    inB.data = $realtobits(testB);

    repeat(4) begin
      @(posedge clock);
      // feed random bits to test pipeline
      inA.data = $random;
      inB.data = $random;
    end

    #1; // no program block in vsim, wait before inspection

    if (!(out.data === testCStruct.data)) begin
      // If we should be NaN, then we don't care about the sign or the contents
      if (out.data.exponent == {EXP{1'b1}} && |out.data.fraction &&
          testCStruct.data.exponent == {EXP{1'b1}} && |testCStruct.data.fraction) begin
        return;
      end

      assert(out.data === testCStruct.data);
      $display("**** ERROR ****");
      $display("%p %s x %p %s =\nshould be %g %s\nvs %g %s",
               testA,
               testAStruct.print(testAStruct.data),
               testB,
               testBStruct.print(testBStruct.data),
               testC,
               testCStruct.print(testCStruct.data),
               $bitstoreal(out.data),
               out.data.sign, out.data.exponent, out.data.fraction);

      $finish;
    end
  endtask

  task automatic testFloat(input real testA,
                           input real testB);
    testFloatImpl(testA, testB);
  endtask

  task automatic testFloatBits(input bit signA,
                               input bit [EXP-1:0] expA,
                               input bit [FRAC-1:0] fracA,
                               input bit signB,
                               input bit [EXP-1:0] expB,
                               input bit [FRAC-1:0] fracB);
    testFloat($bitstoreal({signA, expA, fracA}),
              $bitstoreal({signB, expB, fracB}));
  endtask

  // clock generator
  initial begin : clockgen
    clock = 0;
    forever #(CLOCK_PERIOD / 2) begin
      clock = !clock;
    end
  end

  // reset controller
  initial begin
    reset = 1;
    @(posedge clock);
    reset = 0;
  end

  initial begin
    nan = $bitstoreal({1'b0, {EXP{1'b1}}, {1'b1, {(FRAC-1){1'b0}}}});
    posInf = $bitstoreal({1'b0, {EXP{1'b1}}, {FRAC{1'b0}}});

    // Some simple cases
    testFloat(0.25, 0.25);
    testFloat(0.25, 0);
    testFloat(0, 0);

    testFloat(nan, nan);
    testFloat(nan, 0.25);
    testFloat(nan, 0);
    testFloat(posInf, posInf);
    testFloat(posInf, nan);
    testFloat(posInf, 0.25);
    testFloat(posInf, 0);

    testFloat(0.00666, 0.00333);
    testFloat(0.25, $bitstoreal(64'b1));

    testFloat(1.3e25, -6.7e21);

    // Smallest denormal + smallest denormal
    testFloat($bitstoreal(64'b1), $bitstoreal(64'b1));

    // Smallest normal plus largest denormal
    testFloatBits(0, 1, 0, 0, 0, {FRAC{1'b1}});

    // Largest denormals
    testFloatBits(0, 0, {FRAC{1'b1}}, 0, 0, {FRAC{1'b1}});
    testFloatBits(0, 0, {FRAC{1'b1}}, 0, 0, 1'b1);

    // Largest normal
    testFloatBits(0, {EXP{1'b1}} - 1, {FRAC{1'b1}}, 0, 0, 0);
    testFloatBits(0, {EXP{1'b1}} - 1, {FRAC{1'b1}},
                  0, {EXP{1'b1}} - 1, 1'b1);

    // random everything
    for (i = 0; i < 25; ++i) begin
      randomSignA = $random;
      randomExponentA = $random;
      randomFractionA = $random;

      if (randomExponentA == {EXP{1'b1}}) begin
        randomExponentA = 0;
      end

      randomSignB = $random;
      randomExponentB = $random;
      randomFractionB = $random;

      if (randomExponentB == {EXP{1'b1}}) begin
        randomExponentB = 0;
      end

      testFloatBits(randomSignA, randomExponentA, randomFractionA,
                    randomSignB, randomExponentB, randomFractionB);
    end

    // constrained exponent difference
    for (i = 0; i < 2000; ++i) begin
      randomSignA = $random;
      randomExponentA = $random;
      randomFractionA = $random;

      if (randomExponentA == {EXP{1'b1}}) begin
        randomExponentA = 0;
      end

      randomExponentDiff = {$random} % (FRAC + 3);

      randomSignB = $random;
      randomExponentB = {$random} % 2 == 0 ?
                        randomExponentA - randomExponentDiff :
                        randomExponentA + randomExponentDiff;
      randomFractionB = $random;

      if (randomExponentB == {EXP{1'b1}}) begin
        randomExponentB = 0;
      end

      testFloatBits(randomSignA, randomExponentA, randomFractionA,
                    randomSignB, randomExponentB, randomFractionB);
    end

    // one denormal
    for (i = 0; i < 25; ++i) begin
      randomSignA = $random;
      randomExponentA = 0;
      randomFractionA = $random;

      randomExponentDiff = {$random} % (FRAC + 3);

      randomSignB = $random;
      randomExponentB = {$random} % 2 == 0 ?
                        randomExponentA - randomExponentDiff :
                        randomExponentA + randomExponentDiff;
      randomFractionB = $random;

      if (randomExponentB == {EXP{1'b1}}) begin
        randomExponentB = 0;
      end

      testFloatBits(randomSignA, randomExponentA, randomFractionA,
                    randomSignB, randomExponentB, randomFractionB);
    end

    // two denormals
    for (i = 0; i < 25; ++i) begin
      randomSignA = $random;
      randomExponentA = 0;
      randomFractionA = $random;

      randomSignB = $random;
      randomExponentB = 0;
      randomFractionB = $random;

      testFloatBits(randomSignA, randomExponentA, randomFractionA,
                    randomSignB, randomExponentB, randomFractionB);
    end

    disable clockgen;
  end
endmodule

module FloatMultiplyExtendTest();
  parameter EXP_IN = 8;
  parameter EXP_OUT = 11;
  parameter FRAC_IN = 23;
  parameter FRAC_OUT = 52;
  parameter CLOCK_PERIOD = 10;

  // Only generate bits for the first part of the fraction such that the result
  // fits into FRAC_IN
  parameter RAND_FRAC = 11;

  Float #(.EXP(EXP_IN), .FRAC(FRAC_IN)) inA();
  Float #(.EXP(EXP_IN), .FRAC(FRAC_IN)) inB();
  Float #(.EXP(EXP_OUT), .FRAC(FRAC_IN)) outPreExpand();
  Float #(.EXP(EXP_OUT), .FRAC(FRAC_OUT)) outPostExpand();

  Float #(.EXP(EXP_IN), .FRAC(FRAC_IN)) inDef();
  Float #(.EXP(EXP_OUT), .FRAC(FRAC_IN)) outDef();
  Float #(.EXP(EXP_OUT), .FRAC(FRAC_OUT)) doubleDef();

  logic reset;
  logic clock;

  bit randomSignA;
  bit [EXP_IN-1:0] randomExponentA;
  bit [RAND_FRAC-1:0] randomFractionA;

  bit randomSignB;
  bit [EXP_IN-1:0] randomExponentB;
  bit [RAND_FRAC-1:0] randomFractionB;
  integer i;

  FloatMultiply_RoundToNearestEven #(.EXP_IN_A(EXP_IN),
                                     .FRAC_IN_A(FRAC_IN),
                                     .EXP_IN_B(EXP_IN),
                                     .FRAC_IN_B(FRAC_IN),
                                     .EXP_OUT(EXP_OUT),
                                     .FRAC_OUT(FRAC_OUT))
  mult(.inA,
       .inB,
       .out(outPostExpand),
       .reset,
       .clock);

  task automatic testFloatImpl(input shortreal testA,
                               input shortreal testB);
    automatic real realA = testA;
    automatic real realB = testB;
    automatic real testC = realA * realB;

    inA.data = $shortrealtobits(testA);
    inB.data = $shortrealtobits(testB);

    repeat(4) begin
      @(posedge clock);
      // feed random bits to test pipeline
      inA.data = $random;
      inB.data = $random;
    end

    #1; // no program block in vsim, wait before inspection

    // Inspect expanded form

    if ($bitstoreal(outPostExpand.data) != testC) begin
      $display("%g x %g = %g\n%s x %s = %s\nvs %s (%g)",
               realA, realB, testC,
               doubleDef.print($realtobits(realA)),
               doubleDef.print($realtobits(realB)),
               doubleDef.print($realtobits(testC)),
               doubleDef.print(outPostExpand.data),
               $bitstoreal(outPostExpand.data));

      assert($bitstoreal(outPostExpand.data) == testC);
      $finish;
    end
  endtask

  task automatic testFloat(input shortreal testA,
                           input shortreal testB);
    testFloatImpl(testA, testB);
  endtask

  task automatic testFloatBits(input bit signA,
                               input bit [EXP_IN-1:0] expA,
                               input bit [FRAC_IN-1:0] fracA,
                               input bit signB,
                               input bit [EXP_IN-1:0] expB,
                               input bit [FRAC_IN-1:0] fracB);
    testFloat($bitstoshortreal({signA, expA, fracA}),
              $bitstoshortreal({signB, expB, fracB}));
  endtask

  // clock generator
  initial begin : clockgen
    clock = 0;
    forever #(CLOCK_PERIOD / 2) begin
      clock = !clock;
    end
  end

  // reset controller
  initial begin
    reset = 1;
    #1 reset = 0; // async
  end

  initial begin
    testFloatBits(1'b0, 8'd62, {3'b1, 20'b0},
                  1'b0, 8'd63, {3'b1, 20'b0});

    for (i = 0; i < 1000; ++i) begin
      randomSignA = $random;
      randomExponentA = $random;
      randomFractionA = $random;

      if (randomExponentA == {EXP_IN{1'b1}}) begin
        randomExponentA = 0;
      end

      randomSignB = $random;
      randomExponentB = $random;
      randomFractionB = $random;

      if (randomExponentB == {EXP_IN{1'b1}}) begin
        randomExponentB = 0;
      end

      testFloatBits(randomSignA, randomExponentA,
                    {randomFractionA, {(FRAC_IN-RAND_FRAC){1'b0}}},
                    randomSignB, randomExponentB,
                    {randomFractionA, {(FRAC_IN-RAND_FRAC){1'b0}}});
    end

    disable clockgen;
  end
endmodule
