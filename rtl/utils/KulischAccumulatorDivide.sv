// Copyright (c) Facebook, Inc. and its affiliates. All Rights Reserved.
// All rights reserved.
//
// This source code is licensed under the license found in the
// LICENSE file in the root directory of this source tree.

// Divide an accumulator by a small unsigned integer value, for more exact average
// calculations
// The overall division takes ACC_BITS + 2 cycles to complete
// (ACC_BITS + 1 for the divider, +1 for our div-by-zero handling)
// out = in / div
module KulischAccumulatorDivide #(parameter ACC_NON_FRAC=8,
                                  parameter ACC_FRAC=8,
                                  parameter DIV=8)
  (Kulisch.InputIf accIn,
   input [DIV-1:0] div,
   Kulisch.OutputIf accOut,
   input clock,
   input reset);

  initial begin
    assert(accIn.ACC_NON_FRAC == ACC_NON_FRAC);
    assert(accIn.ACC_FRAC == ACC_FRAC);

    assert(accOut.ACC_NON_FRAC == ACC_NON_FRAC);
    assert(accOut.ACC_FRAC == ACC_FRAC);
  end

  localparam ACC_BITS = KulischDef::getBits(ACC_NON_FRAC, ACC_FRAC);

  // Our divider is signed, so it takes ACC_BITS + 1 cycles to complete
  localparam STAGES = ACC_BITS + 1;

  logic pipeIsInf;
  logic pipeIsOverflow;
  logic pipeOverflowSign;
  logic [ACC_BITS-1:0] pipeAccBits;
  logic pipeDivByZero;

  // Preserve the input accumulator information
  PipelineRegister #(.WIDTH(1), .STAGES(STAGES))
  pr1(.in(accIn.data.isInf),
      .init(1'b0),
      .out(pipeIsInf),
      .reset,
      .clock);

  PipelineRegister #(.WIDTH(1), .STAGES(STAGES))
  pr2(.in(accIn.data.isOverflow),
      .init(1'b0),
      .out(pipeIsOverflow),
      .reset,
      .clock);

  PipelineRegister #(.WIDTH(1), .STAGES(STAGES))
  pr3(.in(accIn.data.overflowSign),
      .init(1'b0),
      .out(pipeOverflowSign),
      .reset,
      .clock);

  // The accumulator is signed, so to get full range, we need a sign bit on the
  // divisor.
  // The divisor is integer, so we don't need the fixed-point divider
  Divider #(.A(ACC_BITS),
            .B(DIV + 1),
            .SIGNED(1))
  divider(.a(accIn.data.bits),
          .b({1'b0, div}),
          .clock,
          .reset,
          .out(pipeAccBits),
          .divByZero(pipeDivByZero));

  // Handle division by zero
  always_ff @(posedge clock) begin
    if (reset) begin
      accOut.data <= accOut.zero();
    end else begin
      accOut.data.isInf <= pipeIsInf | pipeDivByZero;
      accOut.data.isOverflow <= pipeIsOverflow;
      accOut.data.overflowSign <= pipeOverflowSign;
      accOut.data.bits <= pipeAccBits;
    end
  end
endmodule
