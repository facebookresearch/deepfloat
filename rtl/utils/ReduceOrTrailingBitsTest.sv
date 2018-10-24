// Copyright (c) Facebook, Inc. and its affiliates. All Rights Reserved.
// All rights reserved.
//
// This source code is licensed under the license found in the
// LICENSE file in the root directory of this source tree.

module ReduceOrTrailingBitsTest();
  localparam WIDTH = 9;

  logic [WIDTH-1:0] in;
  logic [$clog2(WIDTH):0] n;
  logic out;

  integer pos;
  integer i;

  ReduceOrTrailingBits #(.WIDTH(WIDTH)) mod(.*);

  initial begin
    for (pos = 0; pos < WIDTH; ++pos) begin
      in = WIDTH'(1'b1) << pos;

      for (i = 0; i <= WIDTH; ++i) begin
        n = i;
        #1 assert((i <= pos && !out) || (i > pos && out));
      end
    end
  end
endmodule
