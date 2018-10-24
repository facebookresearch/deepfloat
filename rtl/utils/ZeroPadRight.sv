// Copyright (c) Facebook, Inc. and its affiliates. All Rights Reserved.
// All rights reserved.
//
// This source code is licensed under the license found in the
// LICENSE file in the root directory of this source tree.


// Pads an input with zeros on the right, handles cases where no padding is
// required too (thus, this can't be done with the Verilog concatenation
// operator as it would result in zero-sized fields)
module ZeroPadRight #(parameter IN_WIDTH=8,
                      parameter OUT_WIDTH=8)
  (input [IN_WIDTH-1:0] in,
   output [OUT_WIDTH-1:0] out);
  localparam DIFF = OUT_WIDTH - IN_WIDTH < 0 ?
                    0 :
                    OUT_WIDTH - IN_WIDTH;

  generate
    if (IN_WIDTH > OUT_WIDTH) begin : zpr1
      // Take left most bits
      // FIXME: does this make sense?
      assign out = in[IN_WIDTH-1-:OUT_WIDTH];
    end else if (IN_WIDTH == OUT_WIDTH) begin : zpr2
      assign out = in;
    end else begin : zpr3
      assign out = {in, DIFF'(1'b0)};
    end
  endgenerate
endmodule
