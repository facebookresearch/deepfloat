// Copyright (c) Facebook, Inc. and its affiliates. All Rights Reserved.
// All rights reserved.
//
// This source code is licensed under the license found in the
// LICENSE file in the root directory of this source tree.

// As PartSelect, but performs an or reduction on the result. Any trailing bits
// that are out of bounds are assumed to be 1'b0
module PartSelectReduceOr #(parameter IN_WIDTH=8,
                            parameter START_IDX=7,
                            parameter END_IDX=0)
  (input [IN_WIDTH-1:0] in,
   output logic out);
  generate
    if (START_IDX >= END_IDX &&
        START_IDX <= IN_WIDTH - 1 &&
        END_IDX >= 0) begin : ps1
      assign out = |in[START_IDX:END_IDX];
    end else begin : ps2
      assign out = 1'b0;
    end
  endgenerate
endmodule
