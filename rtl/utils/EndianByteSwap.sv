// Copyright (c) Facebook, Inc. and its affiliates. All Rights Reserved.
// All rights reserved.
//
// This source code is licensed under the license found in the
// LICENSE file in the root directory of this source tree.

// Swaps the bytes to perform a big <-> little endian conversion
module EndianByteSwap #(parameter BYTES=4)
  (input [BYTES-1:0][7:0] in,
   output [BYTES-1:0][7:0] out);

   genvar i;
   generate
     for (i = BYTES - 1; i >= 0; --i) begin : genBytes
       assign out[i] = in[BYTES - 1 - i];
     end
   endgenerate
endmodule
