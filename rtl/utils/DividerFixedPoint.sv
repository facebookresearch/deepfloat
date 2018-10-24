// Copyright (c) Facebook, Inc. and its affiliates. All Rights Reserved.
// All rights reserved.
//
// This source code is licensed under the license found in the
// LICENSE file in the root directory of this source tree.

// A fully-pipelined divider for signed or unsigned fixed-point numbers
// Takes A1 + A2 + B2 cycles if unsigned, A1 + A2 + B2 + 1 cycles if signed
// out = a1.a2 / b1.b2
// Synchronous reset
module DividerFixedPoint #(parameter A1=4,
                           parameter A2=4,
                           parameter B1=4,
                           parameter B2=4,
                           parameter SIGNED=1)
  (input [A1+A2-1:0] a,
   input [B1+B2-1:0] b,
   input clock,
   input reset,
   output logic [A1+A2-1:0] out,
   output logic divByZero);

  // We express the fixed-point division as an integer division by appending
  // zeros to a: (A1.A2, B2 zeros) / (B1.B2)
  logic [A1+A2+B2-1:0] aPadded;

  // Append B2 zeros on the rhs of a; this also handles the case of appending
  // no zeros if B2 == 0
  ZeroPadRight #(.IN_WIDTH(A1+A2),
                 .OUT_WIDTH(A1+A2+B2))
  zpr(.in(a),
      .out(aPadded));

  logic [A1+A2+B2-1:0] divOut;

  Divider #(.A(A1+A2+B2),
            .B(B1+B2),
            .SIGNED(SIGNED))
  div(.a(aPadded),
      .b,
      .out(divOut),
      .divByZero,
      .clock,
      .reset);

  always_comb begin
    // The result is in the A1 + A2 LSBs of the integer divider
    out = divOut[A1+A2-1:0];
  end
endmodule
