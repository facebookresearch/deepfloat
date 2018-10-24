// Copyright (c) Facebook, Inc. and its affiliates. All Rights Reserved.
// All rights reserved.
//
// This source code is licensed under the license found in the
// LICENSE file in the root directory of this source tree.

module Log2Mem #(parameter IN=8,
                 parameter OUT=4)
  (input [IN-1:0] in,
   output logic [OUT:0] out);

  initial begin
    // These are the only implementations we have at the moment
    assert((IN == 5 && OUT == 4) ||
           (IN == 8 && OUT == 4) ||
           (IN == 8 && OUT == 5) ||
           (IN == 8 && OUT == 7) ||
           (IN == 9 && OUT == 8));
  end

  generate
    if (IN == 5 && OUT == 4) begin
      Log2Mem_5x4 log2(.*);
    end else if (IN == 8 && OUT == 4) begin
      Log2Mem_8x4 log2(.*);
    end else if (IN == 8 && OUT == 5) begin
      Log2Mem_8x5 log2(.*);
    end else if (IN == 8 && OUT == 7) begin
      Log2Mem_8x7 log2(.*);
    end else if (IN == 9 && OUT == 8) begin
      Log2Mem_9x8 log2(.*);
    end
  endgenerate
endmodule
