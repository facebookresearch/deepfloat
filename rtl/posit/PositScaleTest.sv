// Copyright (c) Facebook, Inc. and its affiliates. All Rights Reserved.
// All rights reserved.
//
// This source code is licensed under the license found in the
// LICENSE file in the root directory of this source tree.

// This tests scale conversion for posits; in order to represent ranges
// with precision centered around ..., 0.25, 0.5, 1, 2.0, 4.0, ...
// instead of just 1
module PositScaleTest();
  // A posit large enough to encapsulate any real
  localparam WIDTH = 48;
  localparam ES = 2;

  PositUnpacked #(.WIDTH(WIDTH), .ES(ES)) positDef();
  Float #(.EXP(8), .FRAC(23)) floatDef();
  Float #(.EXP(11), .FRAC(52)) doubleDef();

  // Convert float -> posit -> float with scale

  Float #(.EXP(8), .FRAC(23)) floatIn();
  PositUnpacked #(.WIDTH(WIDTH), .ES(ES)) positOut();

  logic signed [3:0] expAdjustIn;

  PositFromFloat #(.POSIT_WIDTH(WIDTH),
                   .POSIT_ES(ES),
                   .FLOAT_EXP(8),
                   .FLOAT_FRAC(23),
                   .EXP_ADJUST_BITS(4),
                   .EXP_ADJUST(1))
  f2p(.in(floatIn),
      .expAdjust(expAdjustIn),
      .out(positOut),
      .trailingBits(),
      .stickyBit());

  Float #(.EXP(11), .FRAC(52)) floatOut();
  logic signed [3:0] expAdjustOut;

  PositToFloat #(.POSIT_WIDTH(WIDTH),
                 .POSIT_ES(ES),
                 .FLOAT_EXP(11),
                 .FLOAT_FRAC(52),
                 .EXP_ADJUST_BITS(4),
                 .EXP_ADJUST(1))
  p2f(.in(positOut),
      .expAdjust(expAdjustOut),
      .out(floatOut),
      .trailingBitsOut(),
      .stickyBitOut());

  integer i;
  bit test;

  task compare(real scale);
    // NaNs become +inf, and zero/inf lose their sign when converted through a
    // posit
    if (floatDef.isNan(floatIn.data) ||
        floatDef.isInf(floatIn.data)) begin
      assert(doubleDef.isInf(floatOut.data));
    end else if (floatDef.isZero(floatIn.data)) begin
      assert(doubleDef.isZero(floatOut.data));
    end else begin
      test = $bitstoreal(floatOut.data) == scale * real'($bitstoshortreal(floatIn.data));

      if (!test) begin
        $display("%s (%g) vs %s (%g) scale %g",
                 floatDef.print(floatIn.data),
                 floatDef.toReal(floatIn.data),
                 doubleDef.print(floatOut.data),
                 doubleDef.toReal(floatOut.data),
                 scale);
        assert(test);
      end
    end
  endtask

  real scale;

  initial begin
    for (i = 0; i < 1000; ++i) begin
      // Take a random float32
      floatIn.data = $random;

      expAdjustIn = 4'sd0;
      expAdjustOut = 4'sd0;
      #1;
      compare(1.0);

      expAdjustIn = 4'sd1;
      expAdjustOut = 4'sd1;
      #1;
      compare(1.0);

      expAdjustIn = 4'sd2;
      expAdjustOut = 4'sd2;
      #1;
      compare(1.0);

      expAdjustIn = -4'sd1;
      expAdjustOut = -4'sd1;
      #1;
      compare(1.0);

      expAdjustIn = -4'sd2;
      expAdjustOut = -4'sd2;
      #1;
      compare(1.0);

      expAdjustIn = $random;
      expAdjustOut = expAdjustIn;
      #1;
      compare(1.0);

      expAdjustIn = $random;
      expAdjustOut = 4'sd0;
      scale = 2.0 ** (integer'(expAdjustIn));
      #1;
      compare(scale);

      expAdjustIn = 4'sd1;
      expAdjustOut = 4'sd0;
      #1;
      compare(2.0);

      expAdjustIn = 4'sd2;
      expAdjustOut = 4'sd0;
      #1;
      compare(4.0);

      expAdjustIn = -4'sd1;
      expAdjustOut = 4'sd0;
      #1;
      compare(0.5);

      expAdjustIn = -4'sd2;
      expAdjustOut = 4'sd0;
      #1;
      compare(0.25);
    end
  end
endmodule
