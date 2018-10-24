// Copyright (c) Facebook, Inc. and its affiliates. All Rights Reserved.
// All rights reserved.
//
// This source code is licensed under the license found in the
// LICENSE file in the root directory of this source tree.

module CountLeadingZerosTest();
  localparam WIDTH = 4;
  localparam ADD_OFFSET = 7;

  bit [WIDTH-1:0] in;
  bit [$clog2(WIDTH+ADD_OFFSET+1)-1:0] out;

  integer i;
  integer j;
  integer testWidth;

  CountLeadingZeros #(.WIDTH(WIDTH),
                      .ADD_OFFSET(ADD_OFFSET))
  count(in, out);

  initial begin
    for (i = 0; i < 100; ++i) begin
      testWidth = {$random} % (WIDTH + 1);

      in = {WIDTH{1'b0}};

      if (testWidth != WIDTH) begin
        in[WIDTH - 1 - testWidth] = 1'b1;
      end

      for (j = 0; j < WIDTH - 1 - testWidth; ++j) begin
        in[j] = {$random} % 2;
      end

      #1;
      if (testWidth + ADD_OFFSET != out) begin
        $display("mismatch: %d %d", testWidth + ADD_OFFSET, out);
        assert(testWidth + ADD_OFFSET == out);
      end
    end
  end
endmodule
