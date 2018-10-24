// Copyright (c) Facebook, Inc. and its affiliates. All Rights Reserved.
// All rights reserved.
//
// This source code is licensed under the license found in the
// LICENSE file in the root directory of this source tree.


module PositLUT #(parameter WIDTH=8,
                  parameter ES=1)
  (input [WIDTH-1:0] mem[0:(2**WIDTH)-1],
   PositPacked.InputIf in,
   PositPacked.OutputIf out);

  initial begin
    assert(in.WIDTH == WIDTH);
    assert(in.ES == ES);
    assert(out.WIDTH == WIDTH);
    assert(out.ES == ES);
  end

  always_comb begin
    out.data = mem[in.data];
  end
endmodule
