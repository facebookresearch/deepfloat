// Copyright (c) Facebook, Inc. and its affiliates. All Rights Reserved.
// All rights reserved.
//
// This source code is licensed under the license found in the
// LICENSE file in the root directory of this source tree.

// For PE-only profiling
module PaperIntegerPETop #(parameter WIDTH=8,
                           parameter ACC=32)
   (input logic [WIDTH-1:0] aIn,
    input logic [WIDTH-1:0] bIn,
    output logic [ACC-1:0] cOut,
    input reset,
    input clock);

  // Register inputs for timing
  logic [WIDTH-1:0] aInReg;
  logic [WIDTH-1:0] bInReg;
  logic [ACC-1:0] cNew;

  PaperIntegerPE #(.WIDTH(WIDTH),
                   .ACC(ACC))
  pe(.aIn(aInReg),
     .bIn(bInReg),
     .cIn(cOut),
     .cOut(cNew));

  always_ff @(posedge clock) begin
    if (reset) begin
      aInReg <= WIDTH'(1'b0);
      bInReg <= WIDTH'(1'b0);
      cOut <= ACC'(1'b0);
    end else begin
      aInReg <= aIn;
      bInReg <= bIn;
      cOut <= cNew;
    end
  end
endmodule

// Systolic PE
module PaperIntegerSystolicPE #(parameter WIDTH=8,
                                parameter ACC=32)
   (input logic [WIDTH-1:0] aIn,
    input logic [WIDTH-1:0] bIn,
    input logic [ACC-1:0] cIn,
    output logic [WIDTH-1:0] aOut,
    output logic [WIDTH-1:0] bOut,
    output logic [ACC-1:0] cOut,
    input enableMul,
    input enableShiftOut,
    input reset,
    input clock);

  logic [ACC-1:0] cNew;

  PaperIntegerPE #(.WIDTH(WIDTH),
                   .ACC(ACC))
  pe(.aIn(aIn),
     .bIn(bIn),
     .cIn(cOut),
     .cOut(cNew));

  always_ff @(posedge clock) begin
    if (reset) begin
      aOut <= WIDTH'(1'b0);
      bOut <= WIDTH'(1'b0);
      cOut <= ACC'(1'b0);
    end else if (enableMul) begin
      aOut <= aIn;
      bOut <= bIn;
      cOut <= cNew;
    end else if (enableShiftOut) begin
      cOut <= cIn;
    end
  end
endmodule
