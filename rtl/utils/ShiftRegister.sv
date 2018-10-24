// Copyright (c) Facebook, Inc. and its affiliates. All Rights Reserved.
// All rights reserved.
//
// This source code is licensed under the license found in the
// LICENSE file in the root directory of this source tree.

module ShiftRegisterFullLoad #(parameter WIDTH=8,
                               parameter DEPTH=4)
   (output logic [WIDTH-1:0] out,
    // We load the entire shift register at once
    input [DEPTH-1:0][WIDTH-1:0] init,
    input load,
    input enable,
    input reset,
    input clock);

  logic [DEPTH-1:0][WIDTH-1:0] regs;
  logic [DEPTH-1:0][WIDTH-1:0] newRegs;

  always_comb begin
    out = regs[0];
    newRegs = {WIDTH'(1'b0), regs[DEPTH-1:1]};
  end

  always_ff @(posedge clock) begin
    if (reset || load) begin
      regs <= reset ? (WIDTH*DEPTH)'(1'b0) : init;
    end else if (enable) begin
      regs <= newRegs;
    end
  end
endmodule
