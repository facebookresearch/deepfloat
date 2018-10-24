// Copyright (c) Facebook, Inc. and its affiliates. All Rights Reserved.
// All rights reserved.
//
// This source code is licensed under the license found in the
// LICENSE file in the root directory of this source tree.

module DividerComb #(parameter A=16,
                     parameter B=8)
  (input logic [A-1:0] a,
   input logic [B-1:0] b,
   output logic [A-1:0] out);

  initial begin
    assert(A >= B);
  end

  localparam SUM = A + B;

  // Each round we shift `a` a single step left towards the MSB
  logic [SUM-1:0] aShifted[A:0];
  logic [SUM-1:0] aNewShifted[A:0];
  logic [B:0] diff[A-1:0];

  // Each cycle we write a new bit into divOut, so only a triangular portion of
  // this is valid
  // cycle 0: divOut[A-1]:   [A-1]
  // cycle 1: divOut[A-2]:   [A-1] [A-2]
  // cycle N: divOut[A-1-N]: [A-1] [A-2] ... [A-1-N]
  logic [A-1:0] divOut[A:0];

  integer i;
  integer j;

  always_comb begin
    // We start with a in the shifter for division
    aShifted[A] = SUM'(a);
    divOut[A] = (A)'(1'b0);

    // The digit we are calculating
    for (i = A - 1; i >= 0; --i) begin
      // Copy partial result from previous iteration
      for (j = A - 1; j > i; --j) begin
        divOut[i][j] = divOut[i+1][j];
      end

      // Subtract b from our remainder of a, with space to determine the carry
      // (i.e., if we go negative)
      diff[i] = aShifted[i+1][A+B-1-:B+1] - {1'b0, b};

      // If the subtraction above didn't go negative, then this digit is a 1
      // (i.e., we contain a multiple of b)
      divOut[i][i] = !diff[i][B];

      aNewShifted[i] = aShifted[i+1];

      if (!diff[i][B]) begin
        aNewShifted[i][A+B-1-:B+1] = diff[i];
      end

      // shift left
      aShifted[i] = {aNewShifted[i][A+B-2:0], 1'b0};
    end

    out = divOut[0];
  end
endmodule

module DividerSignedComb #(parameter A=16,
                           parameter B=8)
  (input signed [A-1:0] a,
   input signed [B-1:0] b,
   output logic signed [A-1:0] out);

  logic [A-1:0] aPositive;
  logic [B-1:0] bPositive;

  logic [A-1:0] divOut;
  logic isNegative;

  DividerComb #(.A(A), .B(B))
  div(.a(aPositive),
      .b(bPositive),
      .out(divOut));

  always_comb begin
    aPositive = a[A-1] ? -a : a;
    bPositive = b[B-1] ? -b : b;

    isNegative = a[A-1] ^ b[B-1];
    out = isNegative ? -divOut : divOut;
  end
endmodule

// A fully-pipelined divider for unsigned integers
// Takes A cycles
// out = a / b
// Synchronous reset
module DividerCore #(parameter A=16,
                     parameter B=8)
  (input [A-1:0] a,
   input [B-1:0] b,
   input reset,
   input clock,
   output logic [A-1:0] out,
   output logic divByZero);

  initial begin
    assert(A >= B);
  end

  localparam SUM = A + B;

  // There are A steps of the division which defined the unpacked dimensions
  // (from A-1 to 0)
  // Each round we shift `a` a sigle step left towards the MSB
  logic [SUM-1:0] aShifted[A-1:0];
  logic [SUM-1:0] aNewShifted[A-1:0];
  logic [B:0] diff[A-1:0];
  logic [A-1:0] divOut[A-1:0];
  logic [SUM-1:0] aExpand;

  // Each cycle we write a new bit into divOut, so only a triangular portion of
  // this is valid
  // cycle 0: divOut[A-1]:   [A-1]
  // cycle 1: divOut[A-2]:   [A-1] [A-2]
  // cycle N: divOut[A-1-N]: [A-1] [A-2] ... [A-1-N]

  // For the sake of similar indexing for the wires above, we don't use the 0
  // index of the registers; the final register are the output ports
  logic [A-1:0] divOutReg[A-1:0];
  logic [SUM-1:0] aShiftedReg[A-1:0];
  logic [B-1:0] bReg[A-1:0];

  integer i;

  always_comb begin
    aExpand = SUM'(a);

    // The digit we are calculating
    for (i = A - 1; i >= 0; --i) begin
      // Subtract b from our remainder of a, with space to determine the carry
      // (i.e., if we go negative)
      diff[i] = (i == A - 1 ?
                 aExpand[A+B-1-:B+1] :
                 aShiftedReg[i+1][A+B-1-:B+1]) -
             {1'b0, i == A - 1 ? b : bReg[i+1]};

      // If the subtraction above didn't go negative, then this digit is a 1
      // (i.e., we contain a multiple of b)
      divOut[i] = (i == (A - 1)) ? (A)'(1'b0) : divOutReg[i+1];
      divOut[i][i] = !diff[i][B];

      aNewShifted[i] = i == A - 1 ? aExpand : aShiftedReg[i+1];

      if (!diff[i][B]) begin
        aNewShifted[i][A+B-1-:B+1] = diff[i];
      end

      // shift left
      aShifted[i] = {aNewShifted[i][A+B-2:0], 1'b0};
    end
  end

  integer j;

  always_ff @(posedge clock) begin
    if (reset) begin
      for (j = A-1; j >= 1; --j) begin
        divOutReg[j] <= A'(1'b0);
        aShiftedReg[j] <= SUM'(1'b0);
        bReg[j] <= B'(1'b0);
      end

      out <= A'(1'b0);
      divByZero <= 1'b0;
    end else begin
      for (j = A-1; j >= 1; --j) begin
        divOutReg[j] <= divOut[j];
        aShiftedReg[j] <= aShifted[j];
        // preserve b from the input across all stages
        bReg[j] <= j == A-1 ? b : bReg[j+1];
      end

      // divOut is combinational, hence the 0 index
      out <= divOut[0];
      // bReg is a register, so we look at the previous state
      divByZero <= (bReg[1] == B'(1'b0));
    end
  end
endmodule

// A fully-pipelined divider for signed or unsigned integers
// Takes A cycles if unsigned, A + 1 cycles if signed
// out = a / b
// Synchronous reset
module Divider #(parameter A=16,
                 parameter B=8,
                 parameter SIGNED=1)
  (input [A-1:0] a,
   input [B-1:0] b,
   input clock,
   input reset,
   output logic [A-1:0] out,
   output logic divByZero);

  generate
    if (SIGNED) begin : genSigned
      // Signed divider; we divide unsigned and then negate based on final
      // output sign
      logic [A-1:0] divOut;
      logic [A-1:0] isNegative;
      logic divByZeroWire;

      DividerCore #(.A(A), .B(B))
      div(.a(a[A-1] ? -a : a),
          .b(b[B-1] ? -b : b),
          .out(divOut),
          .divByZero(divByZeroWire),
          .clock,
          .reset);

      always_ff @(posedge clock) begin
        if (reset) begin
          out <= A'(1'b0);
          isNegative <= A'(1'b0);
          divByZero <= 1'b0;
        end else begin
          isNegative <= {a[A-1] ^ b[B-1], isNegative[A-1:1]};
          out <= isNegative[0] ? -divOut : divOut;
          // delay an extra cycle
          divByZero <= divByZeroWire;
        end
      end
    end else begin
      // Unsigned divider
      DividerCore #(.A(A), .B(B))
      div(.*);
    end
  endgenerate
endmodule
