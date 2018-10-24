// Copyright (c) Facebook, Inc. and its affiliates. All Rights Reserved.
// All rights reserved.
//
// This source code is licensed under the license found in the
// LICENSE file in the root directory of this source tree.

// Converts a one-hot representation of width WIDTH to a binary count
// with ADD_OFFSET additional leading zeros added, for users who
module OneHotToBinary #(parameter WIDTH=8,
                        parameter ADD_OFFSET=0)
  (input [WIDTH-1:0] in,
   output [$clog2(WIDTH+ADD_OFFSET)-1:0] out);

  logic [WIDTH+ADD_OFFSET-1:0] inWithAddOffset;

  genvar i;
  genvar j;
  generate
    for (i = 0; i < ADD_OFFSET; ++i) begin : genAddOffset
      assign inWithAddOffset[i] = 1'b0;
    end
    assign inWithAddOffset[WIDTH+ADD_OFFSET-1:ADD_OFFSET] = in;

    for (i = 0; i < $clog2(WIDTH+ADD_OFFSET); ++i) begin : gen1
      logic [WIDTH+ADD_OFFSET-1:0] mask;
      for (j = 0; j < WIDTH+ADD_OFFSET; ++j) begin : gen2
        assign mask[j] = j[i];
      end

      assign out[i] = |(mask & inWithAddOffset);
    end
  endgenerate
endmodule
