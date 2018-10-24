// Copyright (c) Facebook, Inc. and its affiliates. All Rights Reserved.
// All rights reserved.
//
// This source code is licensed under the license found in the
// LICENSE file in the root directory of this source tree.


module ShiftRightStickyTest();
  localparam IN_WIDTH = 6;
  localparam OUT_WIDTH = 6;

  bit [IN_WIDTH-1:0] in;
  bit [$clog2(OUT_WIDTH+1)-1:0] shift;
  bit [OUT_WIDTH-1:0] out;
  bit sticky;
  bit stickyAnd;

  ShiftRightSticky #(.IN_WIDTH(IN_WIDTH),
                     .OUT_WIDTH(OUT_WIDTH))
  srs(.*);

  integer i;
  integer j;

  initial begin
    for (i = 0; i < 2 ** IN_WIDTH; ++i) begin
      for (j = 0; j <= OUT_WIDTH + 1; ++j) begin
        in = i;
        shift = j;
        #1;

        assert(out == (in >> j));
        assert(sticky == |(in & (((IN_WIDTH+1)'(1'b1) << j) - 1'b1)));
      end
    end
  end
endmodule
