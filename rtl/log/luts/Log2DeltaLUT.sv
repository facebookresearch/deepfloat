// Copyright (c) Facebook, Inc. and its affiliates. All Rights Reserved.
// All rights reserved.
//
// This source code is licensed under the license found in the
// LICENSE file in the root directory of this source tree.

module Log2DeltaLUT #(parameter IN=11,
                      parameter OUT=10)
  (input [IN-1:0] in,
   output logic [OUT:0] out);

  initial begin
    // These are the only implementations we have at the moment
    assert((IN == 5) && (OUT == 7) ||
           (IN == 8) && (OUT == 7) ||
           (IN == 11 && OUT == 10));
  end

  logic [OUT-1-3:0] outDelta;
  logic inZero;

  // Expand in as a fixed point fraction with 0s on the right
  logic [OUT-1:0] curRightPad;

  ZeroPadRight #(.IN_WIDTH(IN),
                 .OUT_WIDTH(OUT))
  zpr(.in,
      .out(curRightPad));

  // The MSB of out is a carry bit, we need to pad with that as well
  logic [OUT:0] cur;

  ZeroPadLeft #(.IN_WIDTH(OUT),
                 .OUT_WIDTH(OUT+1))
  zpl(.in(curRightPad),
      .out(cur));

  always_comb begin
    out = cur + {4'b0, outDelta};
  end

  generate
    if (IN == 5 && OUT == 7) begin
      Log2DeltaLUT_5x7 log2(.in, .out(outDelta));
    end else if (IN == 8 && OUT == 7) begin
      Log2DeltaLUT_8x7 log2(.in, .out(outDelta));
    end else if (IN == 11 && OUT == 10) begin
      Log2DeltaLUT_11x10 log2(.in, .out(outDelta));
    end
  endgenerate
endmodule
