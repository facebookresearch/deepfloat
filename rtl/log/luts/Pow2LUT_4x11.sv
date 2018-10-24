// Copyright (c) Facebook, Inc. and its affiliates. All Rights Reserved.
// All rights reserved.
//
// This source code is licensed under the license found in the
// LICENSE file in the root directory of this source tree.


module Pow2LUT_4x11
  (input [3:0] in,
   output logic [10:0] out);

  always_comb begin
    case (in)
      4'b0000: out = 11'b00000000000;
      4'b0001: out = 11'b00001011011; // round
      4'b0010: out = 11'b00010111001;
      4'b0011: out = 11'b00100011100;
      4'b0100: out = 11'b00110000011;
      4'b0101: out = 11'b00111101111;
      4'b0110: out = 11'b01001100000; // round
      4'b0111: out = 11'b01011010110; // round
      4'b1000: out = 11'b01101010000;
      4'b1001: out = 11'b01111010001; // round
      4'b1010: out = 11'b10001010110;
      4'b1011: out = 11'b10011100010;
      4'b1100: out = 11'b10101110100;
      4'b1101: out = 11'b11000001101; // round
      4'b1110: out = 11'b11010101100;
      4'b1111: out = 11'b11101010010;
      default: out = 11'bxxxxxxxxxxx;
    endcase
  end
endmodule
