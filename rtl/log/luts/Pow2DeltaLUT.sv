// Copyright (c) Facebook, Inc. and its affiliates. All Rights Reserved.
// All rights reserved.
//
// This source code is licensed under the license found in the
// LICENSE file in the root directory of this source tree.

module Pow2DeltaLUT #(parameter IN=4,
                      parameter OUT=8)
  (input [IN-1:0] in,
   output logic [OUT-1:0] out);

  initial begin
    // These are the only implementations we have at the moment
    assert((IN == 4 && OUT == 5) ||
           (IN == 4 && OUT == 8) ||
           (IN == 10 && OUT == 11));
  end

  logic [OUT-1-3:0] outDelta;
  logic inZero;

  // Expand in as a fixed point fraction with 0s on the right
  logic [OUT-1:0] cur;

  ZeroPadRight #(.IN_WIDTH(IN),
                 .OUT_WIDTH(OUT))
  zpr(.in,
      .out(cur));

  always_comb begin
    inZero = ~(|in);
    out = cur + {inZero ? 3'b0 : 3'b111, outDelta};
  end

  generate
    if (IN == 4 && OUT == 5) begin
      Pow2DeltaLUT_4x5 pow2(.in, .out(outDelta));
    end else if (IN == 4 && OUT == 8) begin
      Pow2DeltaLUT_4x8 pow2(.in, .out(outDelta));
    end else if (IN == 10 && OUT == 11) begin
      Pow2DeltaLUT_10x11 pow2(.in, .out(outDelta));
    end
  endgenerate
endmodule
