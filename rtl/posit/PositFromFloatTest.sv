// Copyright (c) Facebook, Inc. and its affiliates. All Rights Reserved.
// All rights reserved.
//
// This source code is licensed under the license found in the
// LICENSE file in the root directory of this source tree.

module PositFromFloatTest();
  // This is a posit wide enough to fit any float32 (shortreal), but all fit
  // within a float64 (real)
  localparam WIDTH = 48;
  localparam ES = 2;

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

  PositUnpacked #(.WIDTH(WIDTH), .ES(ES)) outFTZ();
  logic [1:0] trailingBitsFTZ;
  logic stickyBitFTZ;

  PositFromFloat #(.POSIT_WIDTH(WIDTH),
                   .POSIT_ES(ES),
                   .FLOAT_EXP(FLOAT_EXP),
                   .FLOAT_FRAC(FLOAT_FRAC),
                   .TRAILING_BITS(2),
                   .FTZ_DENORMAL(1))
  f2pFTZ(.in(in),
         .expAdjust(1'b0),
         .out(outFTZ),
         .trailingBits(trailingBitsFTZ),
         .stickyBit(stickyBitFTZ));

  initial begin
    // Test NaN
    in.data = floatDef.getNan();
    #1;
    assert(positDef.isInf(out.data));

    // Test inf
    in.data = floatDef.getInf(1'b0);
    #1;
    assert(positDef.isInf(out.data));

    // Test zero
    in.data = floatDef.getZero(1'b0);
    #1;
    assert(positDef.isZero(out.data));

    for (i = 0; i < 5000; ++i) begin
      in.data.sign = $random;
      in.data.exponent = $random;
      in.data.fraction = $random;

      #1;

      // If the input float is a NaN, then the posit must be +/- inf
      if (floatDef.isNan(in.data)) begin
        assert(positDef.isInf(out.data));
      end else begin
        if (floatDef.isDenormal(in.data)) begin
          assert(trailingBitsFTZ == 2'b0);
          assert(stickyBitFTZ == 1'b0);
          assert(positDef.isZero(outFTZ.data));
          assert(!positDef.isZero(out.data));
        end else begin
          assert(positDef.toReal(outFTZ.data) == floatDef.toReal(in.data));
          assert(trailingBitsFTZ == trailingBits);
          assert(stickyBitFTZ == stickyBit);
        end

        assert(positDef.toReal(out.data) == floatDef.toReal(in.data));
      end
    end
  end
endmodule
