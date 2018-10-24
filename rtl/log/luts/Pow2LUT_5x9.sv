// Copyright (c) Facebook, Inc. and its affiliates. All Rights Reserved.
// All rights reserved.
//
// This source code is licensed under the license found in the
// LICENSE file in the root directory of this source tree.


module Pow2LUT_5x9
  (input [4:0] in,
   output logic [8:0] out);

  always_comb begin
    case (in)
      5'b00000: out = 9'b000000000;
      5'b00001: out = 9'b000001011;
      5'b00010: out = 9'b000010111; // round
      5'b00011: out = 9'b000100010;
      5'b00100: out = 9'b000101110;
      5'b00101: out = 9'b000111011; // round
      5'b00110: out = 9'b001000111;
      5'b00111: out = 9'b001010100; // round
      5'b01000: out = 9'b001100001; // round
      5'b01001: out = 9'b001101110;
      5'b01010: out = 9'b001111100; // round
      5'b01011: out = 9'b010001010; // round
      5'b01100: out = 9'b010011000; // round
      5'b01101: out = 9'b010100111; // round
      5'b01110: out = 9'b010110101;
      5'b01111: out = 9'b011000101; // round
      5'b10000: out = 9'b011010100;
      5'b10001: out = 9'b011100100; // round
      5'b10010: out = 9'b011110100;
      5'b10011: out = 9'b100000101; // round
      5'b10100: out = 9'b100010110; // round
      5'b10101: out = 9'b100100111; // round
      5'b10110: out = 9'b100111001; // round
      5'b10111: out = 9'b101001011; // round
      5'b11000: out = 9'b101011101;
      5'b11001: out = 9'b101110000; // round
      5'b11010: out = 9'b110000011;
      5'b11011: out = 9'b110010111; // round
      5'b11100: out = 9'b110101011;
      5'b11101: out = 9'b111000000; // round
      5'b11110: out = 9'b111010101; // round
      5'b11111: out = 9'b111101010;
      default: out = 9'bxxxxxxxxx;
    endcase
  end
endmodule
