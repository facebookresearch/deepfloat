// Copyright (c) Facebook, Inc. and its affiliates. All Rights Reserved.
// All rights reserved.
//
// This source code is licensed under the license found in the
// LICENSE file in the root directory of this source tree.

module FloatToFloatTool();
  localparam IN_EXP = 8;
  localparam IN_FRAC = 23;

  localparam OUT_EXP = 4;
  localparam OUT_FRAC = 3;

  Float #(.EXP(IN_EXP), .FRAC(IN_FRAC)) in();
  Float #(.EXP(OUT_EXP), .FRAC(OUT_FRAC)) out();
  logic [1:0] trailingBits;
  logic stickyBit;
  logic isNan;

  FloatContract #(.EXP_IN(IN_EXP),
                  .FRAC_IN(IN_FRAC),
                  .EXP_OUT(OUT_EXP),
                  .FRAC_OUT(OUT_FRAC),
                  .TRAILING_BITS(2))
  contract(.in,
           .out,
           .trailingBitsOut(trailingBits),
           .stickyBitOut(stickyBit),
           .isNanOut(isNan));

  Float #(.EXP(OUT_EXP), .FRAC(OUT_FRAC)) outRounded();

  FloatRoundToNearestEven #(.EXP(OUT_EXP),
                            .FRAC(OUT_FRAC))
  r2ne(.in(out),
       .trailingBitsIn(trailingBits),
       .stickyBitIn(stickyBit),
       .isNanIn(isNan),
       .out(outRounded));

  shortreal v;

  initial begin
    v = 0.35355;

    in.data = $shortrealtobits(v);
    #1;

    $display("%g %s -> %p (%b) %g tr %b st %b",
             v,
             in.print(in.data),
             outRounded.data, outRounded.data,
             outRounded.toReal(outRounded.data),
             trailingBits,
             stickyBit);
  end
endmodule
