// Copyright (c) Facebook, Inc. and its affiliates. All Rights Reserved.
// All rights reserved.
//
// This source code is licensed under the license found in the
// LICENSE file in the root directory of this source tree.

// Handles selecting a part from a packed vector, including cases where the
// desired output width exceeds the size of the input vector, or the start index
// is before the beginning of the vector. Any trailing bits that are out of
// bounds are assumed to be 1'b0
//
// This has to be a module instead of a function because you can't have generate
// blocks in a function, and otherwise the tool will see a negative part select
module PartSelect #(parameter IN_WIDTH=8,
                    parameter START_IDX=7,
                    parameter OUT_WIDTH=8)
  (input [IN_WIDTH-1:0] in,
   output logic [OUT_WIDTH-1:0] out);
  generate
    if ((START_IDX + 1) - OUT_WIDTH >= 0) begin : ps1
      assign out = in[START_IDX-:OUT_WIDTH];
    end else if (START_IDX >= 0) begin : ps2
      assign out = {in[START_IDX:0], (OUT_WIDTH-START_IDX-1)'(1'b0)};
    end else begin : ps3
      assign out = {OUT_WIDTH{1'b0}};
    end
  endgenerate
endmodule
