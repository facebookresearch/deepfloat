// Copyright (c) Facebook, Inc. and its affiliates. All Rights Reserved.
// All rights reserved.
//
// This source code is licensed under the license found in the
// LICENSE file in the root directory of this source tree.


module Pow2LUT_4x5
  (input [3:0] in,
   output logic [4:0] out);

  always_comb begin
    case (in)
      4'b0000: out = 5'b00000;
      4'b0001: out = 5'b00001;
      4'b0010: out = 5'b00011; // round
      4'b0011: out = 5'b00100;
      4'b0100: out = 5'b00110;
      4'b0101: out = 5'b01000; // round
      4'b0110: out = 5'b01001;
      4'b0111: out = 5'b01011;
      4'b1000: out = 5'b01101;
      4'b1001: out = 5'b01111;
      4'b1010: out = 5'b10001;
      4'b1011: out = 5'b10100; // round
      4'b1100: out = 5'b10110; // round
      4'b1101: out = 5'b11000;
      4'b1110: out = 5'b11011; // round
      4'b1111: out = 5'b11101;
      default: out = 5'bxxxxx;
    endcase
  end
endmodule
