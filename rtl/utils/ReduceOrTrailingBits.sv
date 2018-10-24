// Copyright (c) Facebook, Inc. and its affiliates. All Rights Reserved.
// All rights reserved.
//
// This source code is licensed under the license found in the
// LICENSE file in the root directory of this source tree.

// Returns a bitwise or of the N least significant bits
module ReduceOrTrailingBits #(parameter WIDTH=8,
                              parameter N_WIDTH=$clog2(WIDTH)+1)
   (input [WIDTH-1:0] in,
    input [N_WIDTH-1:0] n,
    output logic out);

   always_comb begin
      out = |(in & (((WIDTH+1)'(1'b1) << n) - 1'b1));
   end
endmodule
