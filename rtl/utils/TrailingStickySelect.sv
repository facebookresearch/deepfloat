// Copyright (c) Facebook, Inc. and its affiliates. All Rights Reserved.
// All rights reserved.
//
// This source code is licensed under the license found in the
// LICENSE file in the root directory of this source tree.

// Extracts trailing and sticky bits from an input fraction for floating-point
// round to nearest even or other purposes.
// Handles cases where the input is not suitably sized

module TrailingStickySelect #(parameter IN_WIDTH=8,
                              parameter FRAC=8,
                              parameter TRAILING_BITS=2)
  (input [IN_WIDTH-1:0] in,
   output logic [FRAC-1:0] frac,
   output logic [TRAILING_BITS-1:0] trailingBits,
   output logic stickyBit);

  PartSelect #(.IN_WIDTH(IN_WIDTH),
               .START_IDX(IN_WIDTH-1),
               .OUT_WIDTH(FRAC))
  psFrac(.in(in),
         .out(frac));

  PartSelect #(.IN_WIDTH(IN_WIDTH),
               .START_IDX(IN_WIDTH-1-FRAC),
               .OUT_WIDTH(TRAILING_BITS))
  psTrailing(.in(in),
             .out(trailingBits));

  PartSelectReduceOr #(.IN_WIDTH(IN_WIDTH),
                       .START_IDX(IN_WIDTH-1-FRAC-TRAILING_BITS),
                       .END_IDX(0))
  psSticky(.in(in),
           .out(stickyBit));
endmodule
