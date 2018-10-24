// Copyright (c) Facebook, Inc. and its affiliates. All Rights Reserved.
// All rights reserved.
//
// This source code is licensed under the license found in the
// LICENSE file in the root directory of this source tree.


// Extracts a field from a potentially wider type; this is a trivial operation
// but it is designed to extract the same bits that FieldWrite will write

module FieldRead #(parameter IN=8,
                   parameter OUT=8)
  (input [IN-1:0] in,
   output logic [OUT-1:0] out);
  initial begin
    assert(OUT <= IN);
  end

  always_comb begin
    out = in[OUT-1:0];
  end
endmodule
