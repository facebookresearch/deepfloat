// Copyright (c) Facebook, Inc. and its affiliates. All Rights Reserved.
// All rights reserved.
//
// This source code is licensed under the license found in the
// LICENSE file in the root directory of this source tree.


module PositToFloat_Impl #(parameter WIDTH=8,
                           parameter ES=1,
                           parameter EXP_ADJUST_BITS=1,
                           parameter EXP_ADJUST=0)
  (PositPacked.InputIf positIn,
   input logic signed [EXP_ADJUST_BITS-1:0] expAdjust,
   output logic [31:0] floatOut,
   input clock,
   input resetn,
   input ivalid,
   input iready,
   output logic ovalid,
   output logic oready);

  localparam FLOAT_EXP = 8;
  localparam FLOAT_FRAC = 23;

  initial begin
    assert($bits(floatOut) == 1 + FLOAT_EXP + FLOAT_FRAC);
    assert(positIn.WIDTH == WIDTH);
    assert(positIn.ES == ES);
  end

  PositUnpacked #(.WIDTH(WIDTH), .ES(ES)) upPosit();
  PositUnpacked #(.WIDTH(WIDTH), .ES(ES)) upPositReg();
  logic signed [EXP_ADJUST_BITS-1:0] expAdjustReg;

  // 1. unpack posit
  PositDecode #(.WIDTH(WIDTH),
                .ES(ES))
  dec(.in(positIn),
      .out(upPosit));

  Float #(.EXP(FLOAT_EXP), .FRAC(FLOAT_FRAC)) positFloat();

  // 2. expand to float
  PositToFloat #(.POSIT_WIDTH(WIDTH),
                 .POSIT_ES(ES),
                 .FLOAT_EXP(FLOAT_EXP),
                 .FLOAT_FRAC(FLOAT_FRAC),
                 .EXP_ADJUST_BITS(EXP_ADJUST_BITS),
                 .EXP_ADJUST(EXP_ADJUST))
  p2f(.in(upPositReg),
      .expAdjust(expAdjustReg),
      .out(positFloat),
      // All of our posits for now are a subset of float, so no rounding
      // needed
      .trailingBitsOut(),
      .stickyBitOut());

  always_comb begin
    oready = 1'b1;
    ovalid = 1'b1;
  end

  always_ff @(posedge clock) begin
    if (!resetn) begin
      // 1.
      upPositReg.data <= upPosit.zero(1'b0);
      expAdjustReg <= EXP_ADJUST_BITS'(1'b0);

      // 2.
      floatOut <= positFloat.getZero(1'b0);
    end
    else begin
      // 1.
      upPositReg.data <= upPosit.data;
      expAdjustReg <= expAdjust;

      // 2.
      floatOut <= positFloat.data;
    end
  end
endmodule

module FloatToPosit_Impl #(parameter WIDTH=8,
                           parameter ES=1,
                           parameter EXP_ADJUST_BITS=1,
                           parameter EXP_ADJUST=0)
  (input [31:0] floatIn,
   input logic signed [EXP_ADJUST_BITS-1:0] expAdjust,
   PositPacked.OutputIf positOut,
   input clock,
   input resetn,
   input ivalid,
   input iready,
   output logic ovalid,
   output logic oready);

  localparam FLOAT_EXP = 8;
  localparam FLOAT_FRAC = 23;

  // Rounding is required, since (8, 23)-float is a strict superset of
  // (8, 1)-posit
  localparam TRAILING_BITS = 2;

  initial begin
    assert(positOut.WIDTH == WIDTH);
    assert(positOut.ES == ES);
    assert($bits(floatIn) == 1 + FLOAT_EXP + FLOAT_FRAC);
  end

  Float #(.EXP(8), .FRAC(23)) floatInIf();

  always_comb begin
    floatInIf.data = floatIn;
  end

  PositUnpacked #(.WIDTH(WIDTH), .ES(ES)) positUnrounded();
  logic [TRAILING_BITS-1:0] trailingBits;
  logic stickyBit;

  PositUnpacked #(.WIDTH(WIDTH), .ES(ES)) positUnroundedReg();
  logic [TRAILING_BITS-1:0] trailingBitsReg;
  logic stickyBitReg;

  // 1. Convert float to unrounded posit8
  PositFromFloat #(.POSIT_WIDTH(WIDTH),
                   .POSIT_ES(ES),
                   .FLOAT_EXP(FLOAT_EXP),
                   .FLOAT_FRAC(FLOAT_FRAC),
                   .TRAILING_BITS(TRAILING_BITS),
                   .EXP_ADJUST_BITS(EXP_ADJUST_BITS),
                   .EXP_ADJUST(EXP_ADJUST))
  f2p(.in(floatInIf),
      .expAdjust,
      .out(positUnrounded),
      .trailingBits,
      .stickyBit);

  PositUnpacked #(.WIDTH(WIDTH), .ES(ES)) positRounded();
  PositUnpacked #(.WIDTH(WIDTH), .ES(ES)) positRoundedReg();

  // 2. Round posit
  PositRoundToNearestEven #(.WIDTH(WIDTH),
                            .ES(ES))
  pr2ne(.in(positUnroundedReg),
        .trailingBits(trailingBitsReg),
        .stickyBit(stickyBitReg),
        .out(positRounded));

  PositPacked #(.WIDTH(WIDTH), .ES(ES)) positPacked();

  // 3. Pack posit
  PositEncode #(.WIDTH(WIDTH),
                .ES(ES))
  pe(.in(positRoundedReg),
     .out(positPacked));

  always_comb begin
    oready = 1'b1;
    ovalid = 1'b1;
  end

  always_ff @(posedge clock) begin
    if (!resetn) begin
      // 1
      positUnroundedReg.data <= positUnrounded.zero(1'b0);
      trailingBitsReg <= TRAILING_BITS'(1'b0);
      stickyBitReg <= 1'b0;

      // 2
      positRoundedReg.data <= positRounded.zero(1'b0);

      // 3
      positOut.data <= positOut.zeroPacked();
    end
    else begin
      // 1
      positUnroundedReg.data <= positUnrounded.data;
      trailingBitsReg <= trailingBits;
      stickyBitReg <= stickyBit;

      // 2
      positRoundedReg.data <= positRounded.data;

      // 3
      positOut.data <= positPacked.data;
    end
  end
endmodule
