// Copyright (c) Facebook, Inc. and its affiliates. All Rights Reserved.
// All rights reserved.
//
// This source code is licensed under the license found in the
// LICENSE file in the root directory of this source tree.

// FIXME: not a real test
module PositRoundToNearestEvenTest();
  localparam WIDTH = 6;
  localparam ES = 0;
  localparam TRAILING_BITS = 2;

  PositUnpacked #(.WIDTH(WIDTH), .ES(ES)) positDef();
  PositPacked #(.WIDTH(WIDTH), .ES(ES)) in();
  PositUnpacked #(.WIDTH(WIDTH), .ES(ES)) up();
  PositUnpacked #(.WIDTH(WIDTH), .ES(ES)) upInc();
  PositUnpacked #(.WIDTH(WIDTH), .ES(ES)) upRound();

  bit [TRAILING_BITS-1:0] trailingBits;
  bit stickyBit;

  localparam LOCAL_FRACTION_BITS = PositDef::getFractionBits(WIDTH, ES);

  integer i, j, k, inc;

  PositDecode #(.WIDTH(WIDTH), .ES(ES))
  unpack(.in(in), .out(up));

  PositRoundToNearestEven #(.WIDTH(WIDTH), .ES(ES))
  round(.in(upInc), .trailingBits, .stickyBit, .out(upRound));

  initial begin
    for (i = 0; i < 2 ** WIDTH; ++i) begin
      // FIXME: only increment the frac if we are not at max frac precision
//      for (inc = 0; inc <= 1; ++inc) begin // frac increment
      for (inc = 0; inc <= 0; ++inc) begin // frac increment
        for (j = 0; j < 4; ++j) begin // trailing
          for (k = 0; k <= 1; ++k) begin // sticky
            in.data = i;
            #1;

            if (up.data.isInf || up.data.isZero || !inc) begin
              upInc.data = up.data;
            end
            else begin
              upInc.data.sign = up.data.sign;
              upInc.data.isInf = 1'b0;
              upInc.data.isZero = 1'b0;

              if (up.data.fraction == {LOCAL_FRACTION_BITS{1'b1}}) begin
                upInc.data.exponent = up.data.exponent + 1'b1;
                upInc.data.fraction = LOCAL_FRACTION_BITS'(1'b0);
              end
              else begin
                upInc.data.exponent = up.data.exponent;
                upInc.data.fraction = up.data.fraction + 1'b1;
              end
            end

            trailingBits = j;
            stickyBit = k;

            #1 $display("%d (%b): unpack [%s] %g inc %d trailing %b sticky %b round [%s] %g%s",
                        i, WIDTH'(i),
                        positDef.print(up.data), positDef.toReal(up.data),
                        inc, trailingBits, stickyBit,
                        positDef.print(upRound.data), positDef.toReal(upRound.data),
                        positDef.toReal(up.data) == positDef.toReal(upRound.data) ? "" : " *");
          end
        end
      end
    end
  end
endmodule
