// Copyright (c) Facebook, Inc. and its affiliates. All Rights Reserved.
// All rights reserved.
//
// This source code is licensed under the license found in the
// LICENSE file in the root directory of this source tree.

// Left shift as a separate module, so it is easier to trace resource usage for
// this shift
module ShiftLeft #(parameter WIDTH=8,
                   parameter SHIFT_VAL_WIDTH=$clog2(WIDTH+1))
  (input [WIDTH-1:0] in,
   input [SHIFT_VAL_WIDTH-1:0] shift,
   output logic [WIDTH-1:0] out);

  always_comb begin
    out = in << shift;
  end
endmodule
