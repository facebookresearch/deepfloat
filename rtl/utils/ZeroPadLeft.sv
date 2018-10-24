// Copyright (c) Facebook, Inc. and its affiliates. All Rights Reserved.
// All rights reserved.
//
// This source code is licensed under the license found in the
// LICENSE file in the root directory of this source tree.


// Pads an input with zeros on the left, handles cases where no padding is
// required too (thus, this can't be done with the Verilog concatenation
// operator as it would result in zero-sized fields)
module ZeroPadLeft #(parameter IN_WIDTH=8,
                     parameter OUT_WIDTH=8)
  (input [IN_WIDTH-1:0] in,
   output [OUT_WIDTH-1:0] out);
  localparam DIFF = OUT_WIDTH - IN_WIDTH < 0 ?
                    0 :
                    OUT_WIDTH - IN_WIDTH;

  generate
    if (IN_WIDTH > OUT_WIDTH) begin : zpl1
      // Take right most bits
      // FIXME: does this make sense?
      assign out = in[OUT_WIDTH-1:0];
    end else if (IN_WIDTH == OUT_WIDTH) begin : zpl2
      assign out = in;
    end else begin : zpl3
      assign out = {DIFF'(1'b0), in};
    end
  endgenerate
endmodule
