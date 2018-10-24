// Copyright (c) Facebook, Inc. and its affiliates. All Rights Reserved.
// All rights reserved.
//
// This source code is licensed under the license found in the
// LICENSE file in the root directory of this source tree.

// Addition as a separate module, so it is easier to trace resource usage for
// the addition
module Add #(parameter WIDTH=8)
  (input [WIDTH-1:0] a,
   input [WIDTH-1:0] b,
   output logic [WIDTH-1:0] out);

  always_comb begin
    out = a + b;
  end
endmodule
