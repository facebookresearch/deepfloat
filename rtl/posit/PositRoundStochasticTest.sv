// Copyright (c) Facebook, Inc. and its affiliates. All Rights Reserved.
// All rights reserved.
//
// This source code is licensed under the license found in the
// LICENSE file in the root directory of this source tree.

// FIXME: not a real test
module PositRoundStochasticTest();
  localparam WIDTH = 8;
  localparam ES = 1;
  localparam TRAILING_BITS = 8;

  PositUnpacked #(.WIDTH(WIDTH), .ES(ES)) positDef();
  PositPacked #(.WIDTH(WIDTH), .ES(ES)) in();
  PositUnpacked #(.WIDTH(WIDTH), .ES(ES)) up();
  PositUnpacked #(.WIDTH(WIDTH), .ES(ES)) upRound();

  bit [TRAILING_BITS-1:0] trailingBits;
  bit stickyBit;
  bit [TRAILING_BITS+1-1:0] randomBits;

  integer i;

  PositDecode #(.WIDTH(WIDTH), .ES(ES))
  unpack(.in(in), .out(up));

  PositRoundStochastic #(.WIDTH(WIDTH), .ES(ES), .TRAILING_BITS(TRAILING_BITS))
  round(.in(up), .trailingBits, .stickyBit, .randomBits, .out(upRound));

  PositPacked #(.WIDTH(WIDTH), .ES(ES)) pRound();

  PositEncode #(.WIDTH(WIDTH), .ES(ES))
  repack(.in(upRound), .out(pRound));

  logic clock;
  logic reset;

  // clock generator
  initial begin : clockgen
    clock <= 1'b0;
    forever #5 clock = ~clock;
  end

  integer count;

  initial begin
    count = 0;

    for (i = 0; i < 1000; ++i) begin
      in.data = 64;
      trailingBits = {1'b0, 1'b1, 6'b0};
      stickyBit = 1'b0;
      randomBits = $random;

      @(posedge clock);
      #1;

      // $display("%d (%b): unpack [%s] %g tr/s %b:%b rand %b round [%s] %g%s",
      //          i, WIDTH'(i),
      //          positDef.print(up.data), positDef.toReal(up.data),
      //          trailingBits, stickyBit, randomBits,
      //          positDef.print(upRound.data), positDef.toReal(upRound.data),
      //          positDef.toReal(up.data) == positDef.toReal(upRound.data) ? "" : " *");

      if (pRound.data == 8'd65) begin
        ++count;
      end
    end

    // should be about 250
    assert(count > 200 && count < 300);

    disable clockgen;
  end
endmodule
