// Copyright (c) Facebook, Inc. and its affiliates. All Rights Reserved.
// All rights reserved.
//
// This source code is licensed under the license found in the
// LICENSE file in the root directory of this source tree.

// Returns max(a, b). If a == b, we return a
module PositMaxPacked #(parameter WIDTH=8,
                        parameter ES=1)
  (PositPacked.InputIf a,
   PositPacked.InputIf b,
   PositPacked.OutputIf out);

  import Comparison::*;

  logic compOut;

  PositComparePacked #(.WIDTH(WIDTH),
                       .ES(ES))
  comp(.a,
       .b,
       .comp(LT),
       .out(compOut));

  always_comb begin
    out.data = compOut ? b.data : a.data;
  end
endmodule
