// Copyright (c) Facebook, Inc. and its affiliates. All Rights Reserved.
// All rights reserved.
//
// This source code is licensed under the license found in the
// LICENSE file in the root directory of this source tree.

module FloatToPositTool();
  localparam WIDTH = 8;
  localparam ES = 0;

  localparam FLOAT_EXP = 8;
  localparam FLOAT_FRAC = 23;

  Float #(.EXP(FLOAT_EXP), .FRAC(FLOAT_FRAC)) floatDef();
  PositUnpacked #(.WIDTH(WIDTH), .ES(ES)) positDef();

  Float #(.EXP(FLOAT_EXP), .FRAC(FLOAT_FRAC)) in();
  integer i;

  PositUnpacked #(.WIDTH(WIDTH), .ES(ES)) out();
  logic [1:0] trailingBits;
  logic stickyBit;

  PositFromFloat #(.POSIT_WIDTH(WIDTH),
                   .POSIT_ES(ES),
                   .FLOAT_EXP(FLOAT_EXP),
                   .FLOAT_FRAC(FLOAT_FRAC),
                   .TRAILING_BITS(2))
  f2p(.in(in),
      .expAdjust(1'b0),
      .out(out),
      .trailingBits,
      .stickyBit);

  PositUnpacked #(.WIDTH(WIDTH), .ES(ES)) rounded();

  PositRoundToNearestEven #(.WIDTH(WIDTH),
                            .ES(ES))
  r2ne(.in(out),
       .trailingBits,
       .stickyBit,
       .out(rounded));

  PositPacked #(.WIDTH(WIDTH), .ES(ES)) roundedPacked();

  PositEncode #(.WIDTH(WIDTH),
                .ES(ES))
  enc(.in(rounded),
      .out(roundedPacked));

  PositUnpacked #(.WIDTH(WIDTH), .ES(ES)) roundedUnpacked();

  PositDecode #(.WIDTH(WIDTH),
                .ES(ES))
  dec(.in(roundedPacked),
      .out(roundedUnpacked));

  shortreal v;

  initial begin
    v = 0.35355;

    in.data = $shortrealtobits(v);
    #1;

    $display("%g -> %p (%b) %g %g",
             v, roundedPacked.data.bits, roundedPacked.data.bits,
             rounded.toReal(rounded.data),
             roundedUnpacked.toReal(rounded.data));
  end
endmodule
