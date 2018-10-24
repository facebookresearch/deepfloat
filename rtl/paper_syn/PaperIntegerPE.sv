// Copyright (c) Facebook, Inc. and its affiliates. All Rights Reserved.
// All rights reserved.
//
// This source code is licensed under the license found in the
// LICENSE file in the root directory of this source tree.

// For resources measurement
module MulForPE #(parameter WIDTH=8)
  (input logic signed [WIDTH-1:0] a,
   input logic signed [WIDTH-1:0] b,
   output logic signed [2*WIDTH-1:0] out);
  always_comb begin
    out = a * b;
  end
endmodule

// For resources measurement
module AddForPE #(parameter A=32,
                  parameter B=16)
  (input logic signed [A-1:0] a,
   input logic signed [B-1:0] b,
   output logic signed [A-1:0] out);
  always_comb begin
    out = a + b;
  end
endmodule

// combinational PE
module PaperIntegerPE #(parameter WIDTH=8,
                        parameter ACC=32)
   (input logic [WIDTH-1:0] aIn,
    input logic [WIDTH-1:0] bIn,
    input logic [ACC-1:0] cIn,
    output logic [ACC-1:0] cOut);

  logic [2*WIDTH-1:0] ab;
  MulForPE #(.WIDTH(WIDTH))
  mul(.a(aIn),
      .b(bIn),
      .out(ab));

  logic [ACC-1:0] cNew;
  AddForPE #(.A(ACC),
             .B(WIDTH*2))
  add(.a(cIn),
      .b(ab),
      .out(cOut));
endmodule
