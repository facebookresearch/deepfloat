// Copyright (c) Facebook, Inc. and its affiliates. All Rights Reserved.
// All rights reserved.
//
// This source code is licensed under the license found in the
// LICENSE file in the root directory of this source tree.

module Pow2Mem #(parameter IN=4,
                 parameter OUT=8)
  (input [IN-1:0] in,
   output logic [OUT-1:0] out);

  initial begin
    // These are the only implementations we have at the moment
    assert((IN == 4 && OUT == 5) ||
           (IN == 4 && OUT == 8) ||
           (IN == 5 && OUT == 8) ||
           (IN == 7 && OUT == 8) ||
           (IN == 8 && OUT == 9));
  end

  generate
    if (IN == 4 && OUT == 5) begin
      Pow2Mem_4x5 pow2(.*);
    end else if (IN == 4 && OUT == 8) begin
      Pow2Mem_4x8 pow2(.*);
    end else if (IN == 5 && OUT == 8) begin
      Pow2Mem_5x8 pow2(.*);
    end else if (IN == 7 && OUT == 8) begin
      Pow2Mem_7x8 pow2(.*);
    end else if (IN == 8 && OUT == 9) begin
      Pow2Mem_8x9 pow2(.*);
    end
  endgenerate
endmodule
