// Copyright (c) Facebook, Inc. and its affiliates. All Rights Reserved.
// All rights reserved.
//
// This source code is licensed under the license found in the
// LICENSE file in the root directory of this source tree.


// Writes a field into a larger type, padding with zeros.
// Designed to work with FieldRead.
// Handles all cases of IN <= OUT

module FieldWrite #(parameter IN=8,
                    parameter OUT=8)
  (input [IN-1:0] in,
   output logic [OUT-1:0] out);
  initial begin
    assert(IN <= OUT);
  end

  generate
    if (OUT > IN) begin : fw
      always_comb begin
        out = {(OUT-IN)'(1'b0), in};
      end
    end else begin
      always_comb begin
        out = in;
      end
    end
  endgenerate
endmodule
