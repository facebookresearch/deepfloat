// Copyright (c) Facebook, Inc. and its affiliates. All Rights Reserved.
// All rights reserved.
//
// This source code is licensed under the license found in the
// LICENSE file in the root directory of this source tree.


module Pow2LUT_5x8
  (input [4:0] in,
   output logic [7:0] out);

  always_comb begin
    case (in)
      5'b00000: out = 8'b00000000;
      5'b00001: out = 8'b00000110; // round
      5'b00010: out = 8'b00001011;
      5'b00011: out = 8'b00010001;
      5'b00100: out = 8'b00010111;
      5'b00101: out = 8'b00011101;
      5'b00110: out = 8'b00100100; // round
      5'b00111: out = 8'b00101010; // round
      5'b01000: out = 8'b00110000;
      5'b01001: out = 8'b00110111;
      5'b01010: out = 8'b00111110; // round
      5'b01011: out = 8'b01000101; // round
      5'b01100: out = 8'b01001100; // round
      5'b01101: out = 8'b01010011;
      5'b01110: out = 8'b01011011; // round
      5'b01111: out = 8'b01100010;
      5'b10000: out = 8'b01101010;
      5'b10001: out = 8'b01110010; // round
      5'b10010: out = 8'b01111010;
      5'b10011: out = 8'b10000010;
      5'b10100: out = 8'b10001011; // round
      5'b10101: out = 8'b10010011;
      5'b10110: out = 8'b10011100;
      5'b10111: out = 8'b10100101;
      5'b11000: out = 8'b10101111; // round
      5'b11001: out = 8'b10111000; // round
      5'b11010: out = 8'b11000010; // round
      5'b11011: out = 8'b11001011;
      5'b11100: out = 8'b11010110; // round
      5'b11101: out = 8'b11100000; // round
      5'b11110: out = 8'b11101010;
      5'b11111: out = 8'b11110101;
      default: out = 8'bxxxxxxxx;
    endcase
  end
endmodule
