// Copyright (c) Facebook, Inc. and its affiliates. All Rights Reserved.
// All rights reserved.
//
// This source code is licensed under the license found in the
// LICENSE file in the root directory of this source tree.

module PositToFloatTest();
  localparam WIDTH = 32;
  localparam ES = 2;

  PositUnpacked #(.WIDTH(WIDTH), .ES(ES)) positDef();
  Float #(.EXP(11), .FRAC(52)) floatOutDef();

  PositPacked #(.WIDTH(WIDTH), .ES(ES)) in();
  PositUnpacked #(.WIDTH(WIDTH), .ES(ES)) out();

  Float #(.EXP(11), .FRAC(52)) floatOutPreRound();
  Float #(.EXP(11), .FRAC(52)) floatOut();

  logic [1:0] trailingBits;
  logic stickyBit;

  integer i;

  PositDecode #(.WIDTH(WIDTH),
                .ES(ES))
  unpack(.*);

  PositToFloat #(.POSIT_WIDTH(WIDTH),
                 .POSIT_ES(ES),
                 .FLOAT_EXP(11),
                 .FLOAT_FRAC(52),
                 .TRAILING_BITS(2),
                 .SATURATE_TO_MAX_FLOAT(0))
  p2f(.in(out),
      .expAdjust(1'b0),
      .out(floatOutPreRound),
      .trailingBitsOut(trailingBits),
      .stickyBitOut(stickyBit));

  FloatRoundToNearestEven #(.EXP(11),
                            .FRAC(52))
  r2ne(.in(floatOutPreRound),
       .trailingBitsIn(trailingBits),
       .stickyBitIn(stickyBit),
       .isNanIn(1'b0),
       .out(floatOut));

  initial begin
    for (i = 0; i < 1000; ++i) begin
      in.data = $random;
      #1;

      assert($bitstoreal(floatOut.data) == positDef.toReal(out.data));
    end
  end
endmodule
