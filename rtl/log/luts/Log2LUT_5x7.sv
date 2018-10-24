// Copyright (c) Facebook, Inc. and its affiliates. All Rights Reserved.
// All rights reserved.
//
// This source code is licensed under the license found in the
// LICENSE file in the root directory of this source tree.


module Log2LUT_5x7
  (input [4:0] in,
   output logic [7:0] out);

  always_comb begin
    case (in)
      5'b00000: out = 8'b00000000;
      5'b00001: out = 8'b00000110;
      5'b00010: out = 8'b00001011;
      5'b00011: out = 8'b00010001;
      5'b00100: out = 8'b00010110;
      5'b00101: out = 8'b00011011;
      5'b00110: out = 8'b00100000;
      5'b00111: out = 8'b00100101;
      5'b01000: out = 8'b00101001;
      5'b01001: out = 8'b00101110;
      5'b01010: out = 8'b00110010;
      5'b01011: out = 8'b00110111;
      5'b01100: out = 8'b00111011;
      5'b01101: out = 8'b00111111;
      5'b01110: out = 8'b01000011;
      5'b01111: out = 8'b01000111;
      5'b10000: out = 8'b01001011;
      5'b10001: out = 8'b01001111;
      5'b10010: out = 8'b01010010;
      5'b10011: out = 8'b01010110;
      5'b10100: out = 8'b01011010;
      5'b10101: out = 8'b01011101;
      5'b10110: out = 8'b01100001;
      5'b10111: out = 8'b01100100;
      5'b11000: out = 8'b01100111;
      5'b11001: out = 8'b01101011;
      5'b11010: out = 8'b01101110;
      5'b11011: out = 8'b01110001;
      5'b11100: out = 8'b01110100;
      5'b11101: out = 8'b01110111;
      5'b11110: out = 8'b01111010;
      5'b11111: out = 8'b01111101;
      default: out = 8'bxxxxxxxx;
    endcase
  end
endmodule
