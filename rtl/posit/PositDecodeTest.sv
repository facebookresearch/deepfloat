// Copyright (c) Facebook, Inc. and its affiliates. All Rights Reserved.
// All rights reserved.
//
// This source code is licensed under the license found in the
// LICENSE file in the root directory of this source tree.

// FIXME: not a real test
module PositDecodeTest();
  localparam WIDTH = 8;
  localparam ES = 1;

  PositPacked #(.WIDTH(WIDTH), .ES(ES)) in();
  PositUnpacked #(.WIDTH(WIDTH), .ES(ES)) out();

  integer i;

  PositDecode #(.WIDTH(WIDTH),
                .ES(ES))
  dec(.in(in),
      .out(out));

  initial begin
    for (i = 0; i < 2 ** WIDTH; ++i) begin
      in.data.bits = i;

      #5 $display("%d (%b): unpack [%s] %g",
                  i, WIDTH'(i),
                  out.print(out.data),
                  out.toReal(out.data));
    end
  end
endmodule
