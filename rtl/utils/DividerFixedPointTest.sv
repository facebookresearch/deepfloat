// Copyright (c) Facebook, Inc. and its affiliates. All Rights Reserved.
// All rights reserved.
//
// This source code is licensed under the license found in the
// LICENSE file in the root directory of this source tree.

// FIXME: not a real test
module DividerFixedPointTestTemplate #(parameter A1=4,
                                       parameter A2=4,
                                       parameter B1=4,
                                       parameter B2=4,
                                       parameter SIGNED=1)
  ();

  logic [A1+A2-1:0] a;
  logic [B1+B2-1:0] b;
  logic [A1+A2-1:0] out;
  logic divByZero;

  logic clock;
  logic reset;

  DividerFixedPoint #(.A1(A1),
                      .A2(A2),
                      .B1(B1),
                      .B2(B2),
                      .SIGNED(SIGNED))
  div(.*);

  integer i;
  integer j;

  initial begin : clockgen
    clock <= 1'b0;
    forever #5 clock = ~clock;
  end

  initial begin
    reset = 1'b1;
    @(posedge clock);
    reset = 1'b0;

    for (i = 0; i < 1; ++i) begin
      a = {A1'(8'd5), A2'(8'b11000000)};
      b = {A1'(8'd2), A2'(8'b00100000)};

      b = (b == 0) ? (B1+B2)'(1'b1) : b;
      for (j = 0; j < A1+A2+B1; ++j) begin
        @(posedge clock);
      end

      #1;
      $display("%b.%b / %b.%b = %b.%b",
               a[A1+A2-1-:A1],
               a[A2-1:0],
               b[B1+B2-1-:B1],
               b[B2-1:0],
               out[A1+A2-1-:A1],
               out[A2-1:0]);
    end

    disable clockgen;
  end
endmodule

module DividerFixedPointTest();
  DividerFixedPointTestTemplate #(.A1(8), .A2(8),
                                  .B1(8), .B2(8), .SIGNED(0)) dt1();
endmodule
