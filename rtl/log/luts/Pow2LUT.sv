// Copyright (c) Facebook, Inc. and its affiliates. All Rights Reserved.
// All rights reserved.
//
// This source code is licensed under the license found in the
// LICENSE file in the root directory of this source tree.

module Pow2LUT #(parameter IN=4,
                 parameter OUT=8)
  (input [IN-1:0] in,
   output logic [OUT-1:0] out);

  initial begin
    // These are the only implementations we have at the moment
    assert((IN == 4 && OUT == 5) ||
           (IN == 4 && OUT == 8) ||
           (IN == 4 && OUT == 11) ||
           (IN == 5 && OUT == 8) ||
           (IN == 5 && OUT == 9) ||
           (IN == 7 && OUT == 8) ||
           (IN == 8 && OUT == 9) ||
           (IN == 10 && OUT == 11) ||
           1'b0
           );
  end

  generate
    if (IN == 4 && OUT == 5) begin
      Pow2LUT_4x5 pow2(.*);
    end else if (IN == 4 && OUT == 8) begin
      Pow2LUT_4x8 pow2(.*);
    end else if (IN == 4 && OUT == 11) begin
      Pow2LUT_4x11 pow2(.*);
    end else if (IN == 5 && OUT == 8) begin
      Pow2LUT_5x8 pow2(.*);
    end else if (IN == 5 && OUT == 9) begin
      Pow2LUT_5x9 pow2(.*);
    end else if (IN == 7 && OUT == 8) begin
      Pow2LUT_7x8 pow2(.*);
    end else if (IN == 8 && OUT == 9) begin
      Pow2LUT_8x9 pow2(.*);
    end else if (IN == 10 && OUT == 11) begin
      Pow2LUT_10x11 pow2(.*);
    end
  endgenerate
endmodule
