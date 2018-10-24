// Copyright (c) Facebook, Inc. and its affiliates. All Rights Reserved.
// All rights reserved.
//
// This source code is licensed under the license found in the
// LICENSE file in the root directory of this source tree.

// Preserves the value in `in` for STAGES cycles
module PipelineRegister #(parameter WIDTH=8,
                          parameter STAGES=2)
  (input [WIDTH-1:0] in,
   input [WIDTH-1:0] init,
   output logic [WIDTH-1:0] out,
   input reset,
   input clock);

  logic [STAGES-1:0][WIDTH-1:0] regs;
  integer i;

  always_comb begin
    out = regs[STAGES-1];
  end

  always_ff @(posedge clock) begin
    if (reset) begin
      for (i = 0; i < STAGES; ++i) begin
        regs <= init;
      end
    end else begin
      regs[0] <= in;
      regs[STAGES-1:1] <= regs[STAGES-2:0];
    end
  end
endmodule
