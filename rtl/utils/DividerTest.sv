// Copyright (c) Facebook, Inc. and its affiliates. All Rights Reserved.
// All rights reserved.
//
// This source code is licensed under the license found in the
// LICENSE file in the root directory of this source tree.

module DividerTestTemplate #(parameter A=16,
                             parameter B=8,
                             parameter SIGNED=1)
  ();
  logic [A-1:0] a;
  logic [B-1:0] b;
  logic [A-1:0] out;
  logic divByZero;

  logic [A-1:0] testA;
  logic [B-1:0] testB;

  logic clock;
  logic reset;

  Divider #(.A(A),
            .B(B),
            .SIGNED(SIGNED))
  div(.a,
      .b,
      .out,
      .divByZero,
      .clock,
      .reset);

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

    for (i = 0; i < 20; ++i) begin
      a = $random;
      b = $random;

      testA = a;
      testB = b;

      for (j = 0; j < A + SIGNED; ++j) begin
        @(posedge clock);
        // fill with garbage
        #1;

        a = $random;
        b = $random;
      end

      #1;

      if (SIGNED) begin
        if (testB == 0) begin
          assert(divByZero);
        end else begin
          assert(signed'(out) == signed'(testA) / signed'(testB));
          assert(!divByZero);
        end
      end else begin
        if (testB == 0) begin
          assert(divByZero);
        end else begin
          assert(out == testA / testB);
          assert(!divByZero);
        end
      end
    end

    disable clockgen;
  end
endmodule

module DividerTest();
  DividerTestTemplate #(.A(10), .B(6), .SIGNED(1)) dts1();
  DividerTestTemplate #(.A(10), .B(10), .SIGNED(1)) dts2();
  DividerTestTemplate #(.A(5), .B(3), .SIGNED(1)) dts3();
  DividerTestTemplate #(.A(5), .B(5), .SIGNED(1)) dts4();
  DividerTestTemplate #(.A(100), .B(25), .SIGNED(1)) dts5();
  DividerTestTemplate #(.A(100), .B(100), .SIGNED(1)) dts6();

  DividerTestTemplate #(.A(10), .B(6), .SIGNED(0)) dtu1();
  DividerTestTemplate #(.A(10), .B(10), .SIGNED(0)) dtu2();
  DividerTestTemplate #(.A(5), .B(3), .SIGNED(0)) dtu3();
  DividerTestTemplate #(.A(5), .B(5), .SIGNED(0)) dtu4();
  DividerTestTemplate #(.A(100), .B(25), .SIGNED(0)) dtu5();
  DividerTestTemplate #(.A(100), .B(100), .SIGNED(0)) dtu6();
endmodule
