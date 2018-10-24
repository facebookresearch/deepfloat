// Copyright (c) Facebook, Inc. and its affiliates. All Rights Reserved.
// All rights reserved.
//
// This source code is licensed under the license found in the
// LICENSE file in the root directory of this source tree.


module Pow2LUT_4x8
  (input [3:0] in,
   output logic [7:0] out);

  always_comb begin
    case (in)
      4'b0000: out = 8'b00000000;
      4'b0001: out = 8'b00001011;
      4'b0010: out = 8'b00010111;
      4'b0011: out = 8'b00100100; // round
      4'b0100: out = 8'b00110000;
      4'b0101: out = 8'b00111110; // round
      4'b0110: out = 8'b01001100; // round
      4'b0111: out = 8'b01011011; // round
      4'b1000: out = 8'b01101010;
      4'b1001: out = 8'b01111010;
      4'b1010: out = 8'b10001011; // round
      4'b1011: out = 8'b10011100;
      4'b1100: out = 8'b10101111; // round
      4'b1101: out = 8'b11000010; // round
      4'b1110: out = 8'b11010110; // round
      4'b1111: out = 8'b11101010;
      default: out = 8'bxxxxxxxx;
    endcase
  end
endmodule
