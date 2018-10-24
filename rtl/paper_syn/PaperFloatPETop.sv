// Copyright (c) Facebook, Inc. and its affiliates. All Rights Reserved.
// All rights reserved.
//
// This source code is licensed under the license found in the
// LICENSE file in the root directory of this source tree.

module PaperFloatPETop #(parameter EXP=5,
                         parameter FRAC=10)
  (input logic [1+EXP+FRAC-1:0] aIn,
   input logic [1+EXP+FRAC-1:0] bIn,
   output logic [1+EXP+FRAC-1:0] cOut,
   input reset,
   input clock);

  localparam WIDTH = 1 + EXP + FRAC;

  // Register inputs for timing
  logic [WIDTH-1:0] aInReg;
  logic [WIDTH-1:0] bInReg;
  logic [WIDTH-1:0] cNew;
//  logic [WIDTH-1:0] cOutReg;

  PaperFloatPE #(.EXP(EXP),
                 .FRAC(FRAC))
  pe(.aIn(aInReg),
     .bIn(bInReg),
     .cIn(cOut),
     .cOut(cNew));

  always_ff @(posedge clock) begin
    if (reset) begin
      aInReg <= WIDTH'(1'b0);
      bInReg <= WIDTH'(1'b0);
//      cOutReg <= WIDTH'(1'b0);
      cOut <= WIDTH'(1'b0);
    end else begin
      aInReg <= aIn;
      bInReg <= bIn;
      // does not meet timing in 1 clock; retime with 2
      // cOutReg <= cNew;
      // cOut <= cOutReg;
      cOut <= cNew;
    end
  end
endmodule
