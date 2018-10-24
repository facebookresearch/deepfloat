// Copyright (c) Facebook, Inc. and its affiliates. All Rights Reserved.
// All rights reserved.
//
// This source code is licensed under the license found in the
// LICENSE file in the root directory of this source tree.


module Log2LUT_5x4
  (input [4:0] in,
   output logic [4:0] out);

  always_comb begin
    case (in)
      5'b00000: out = 5'b00000;
      5'b00001: out = 5'b00001;
      5'b00010: out = 5'b00001; // overlap
      5'b00011: out = 5'b00010;
      5'b00100: out = 5'b00011;
      5'b00101: out = 5'b00011; // overlap
      5'b00110: out = 5'b00100;
      5'b00111: out = 5'b00101;
      5'b01000: out = 5'b00101; // overlap
      5'b01001: out = 5'b00110;
      5'b01010: out = 5'b00110; // overlap
      5'b01011: out = 5'b00111;
      5'b01100: out = 5'b00111; // overlap
      5'b01101: out = 5'b01000;
      5'b01110: out = 5'b01000; // overlap
      5'b01111: out = 5'b01001;
      5'b10000: out = 5'b01001; // overlap
      5'b10001: out = 5'b01010;
      5'b10010: out = 5'b01010; // overlap
      5'b10011: out = 5'b01011;
      5'b10100: out = 5'b01011; // overlap
      5'b10101: out = 5'b01100;
      5'b10110: out = 5'b01100; // overlap
      5'b10111: out = 5'b01101;
      5'b11000: out = 5'b01101; // overlap
      5'b11001: out = 5'b01101; // overlap
      5'b11010: out = 5'b01110;
      5'b11011: out = 5'b01110; // overlap
      5'b11100: out = 5'b01111;
      5'b11101: out = 5'b01111; // overlap
      5'b11110: out = 5'b01111; // overlap
      5'b11111: out = 5'b10000; // overlap + round
      default: out = 5'bxxxxx;
    endcase
  end
endmodule
