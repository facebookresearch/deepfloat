// Copyright (c) Facebook, Inc. and its affiliates. All Rights Reserved.
// All rights reserved.
//
// This source code is licensed under the license found in the
// LICENSE file in the root directory of this source tree.

// Performs posit rounding via r2ne or stochastic
// The output is registered
module PositRound #(parameter WIDTH=8,
                    parameter ES=1,
                    // must be >= 2 to support r2ne
                    parameter TRAILING_BITS=8)
  (PositUnpacked.InputIf in,
   input [TRAILING_BITS-1:0] trailingBits,
   input stickyBit,
   input roundStochastic,
   input clock,
   input reset,
   PositUnpacked.OutputIf out);

  initial begin
    assert(in.WIDTH == out.WIDTH);
    assert(in.WIDTH == WIDTH);
    assert(in.ES == out.ES);
    assert(in.ES == ES);
    assert(TRAILING_BITS >= 2);
  end

  // For r2ne
  PositUnpacked #(.WIDTH(WIDTH), .ES(ES)) r2neOut();
  logic trailingSticky;

  // If TRAILING_BITS > 2, then we have to reduce the trailing bits to be part
  // of the sticky bit
  PartSelectReduceOr #(.IN_WIDTH(TRAILING_BITS),
                       .START_IDX(TRAILING_BITS-3))
  psro(.in(trailingBits),
       .out(trailingSticky));

  PositRoundToNearestEven #(.WIDTH(WIDTH),
                            .ES(ES))
  prne(.in,
       // this is guaranteed to be in bounds
       .trailingBits(trailingBits[TRAILING_BITS-1-:2]),
       .stickyBit(trailingSticky | stickyBit),
       .out(r2neOut));

  // For stochastic rounding
  PositUnpacked #(.WIDTH(WIDTH), .ES(ES)) rstoOut();
  logic [(TRAILING_BITS+1)-1:0] randomBits;

  LFSR #(.N(TRAILING_BITS+1))
  lfsr(.init((TRAILING_BITS+1)'(1'b1)),
       .out(randomBits),
       .reset,
       .clock);

  PositRoundStochastic #(.WIDTH(WIDTH),
                         .ES(ES),
                         .TRAILING_BITS(TRAILING_BITS))
  prs(.in,
      .trailingBits,
      .stickyBit,
      .randomBits,
      .out(rstoOut));

  always_ff @(posedge clock) begin
    if (reset) begin
      out.data <= in.zero(1'b0);
    end else begin
      out.data <= roundStochastic ? rstoOut.data : r2neOut.data;
    end
  end
endmodule
