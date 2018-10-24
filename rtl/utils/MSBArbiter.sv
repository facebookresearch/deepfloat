// Copyright (c) Facebook, Inc. and its affiliates. All Rights Reserved.
// All rights reserved.
//
// This source code is licensed under the license found in the
// LICENSE file in the root directory of this source tree.

// Finds first position of leading 1 bit
// 4'b1111 => 4'b0001
// 4'b0111 => 4'b0010
// ...
module MSBArbiter #(parameter WIDTH=8)
   (input [WIDTH-1:0] in,
    output [WIDTH-1:0] out);

   genvar i;
   generate
      for (i = WIDTH - 1; i >= 0; --i) begin : gen1
         if (i == WIDTH - 1) begin
            assign out[WIDTH - 1 - i] = in[i];
         end
         else begin
            assign out[WIDTH - 1 - i] = ~(|in[WIDTH-1:i+1]) & in[i];
         end
      end
   endgenerate
endmodule
