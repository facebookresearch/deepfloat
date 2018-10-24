// Copyright (c) Facebook, Inc. and its affiliates. All Rights Reserved.
// All rights reserved.
//
// This source code is licensed under the license found in the
// LICENSE file in the root directory of this source tree.

module CountLeadingZerosShiftLeftTest();
  localparam WIDTH = 9;
  localparam SHIFT = $clog2(WIDTH + 1);

  bit [WIDTH-1:0] in;
  bit [WIDTH-1:0] out;
  bit [SHIFT-1:0] shiftClzsl;
  bit [SHIFT-1:0] shiftClz;

  integer i;

  CountLeadingZerosShiftLeft #(.WIDTH(WIDTH))
  testClzsl(.in, .out, .shift(shiftClzsl));

  // Compare against CLZ + shift left
  CountLeadingZeros #(.WIDTH(WIDTH),
                      .ADD_OFFSET(0))
  origClz(.in, .out(shiftClz));

  initial begin
    for (i = 0; i <= (2 ** WIDTH) - 1; ++i) begin
      in = 8'(i);
      #1;

      assert(shiftClz == shiftClzsl);
      assert(out == in << shiftClz);
    end
  end
endmodule
