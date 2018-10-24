// Copyright (c) Facebook, Inc. and its affiliates. All Rights Reserved.
// All rights reserved.
//
// This source code is licensed under the license found in the
// LICENSE file in the root directory of this source tree.


module Pow2DeltaLUT_4x5
  (input [3:0] in,
   output logic [1:0] out);

  always_comb begin
    case (in)
      4'b0000: out = 2'b00;
      4'b0001: out = 2'b11;
      4'b0010: out = 2'b11;
      4'b0011: out = 2'b10;
      4'b0100: out = 2'b10;
      4'b0101: out = 2'b10;
      4'b0110: out = 2'b01;
      4'b0111: out = 2'b01;
      4'b1000: out = 2'b01;
      4'b1001: out = 2'b01;
      4'b1010: out = 2'b01;
      4'b1011: out = 2'b10;
      4'b1100: out = 2'b10;
      4'b1101: out = 2'b10;
      4'b1110: out = 2'b11;
      4'b1111: out = 2'b11;
      default: out = 2'bxx;
    endcase
  end
endmodule
