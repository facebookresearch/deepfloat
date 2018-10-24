// Copyright (c) Facebook, Inc. and its affiliates. All Rights Reserved.
// All rights reserved.
//
// This source code is licensed under the license found in the
// LICENSE file in the root directory of this source tree.

// A helper for performing general floating-point round to nearest even
module RoundToNearestEven(input keepBit,
                          input [1:0] trailingBits,
                          input stickyBit,
                          output logic roundDown);
  always_comb begin
    // Round to nearest even behavior:
    //
    // K | G R S
    // x | 0 x x : round down (truncate)
    // 0 | 1 0 0 : round down (truncate)
    // 1 | 1 0 0 : round up
    // x | 1 0 1 : round up
    // x | 1 1 0 : round up
    // x | 1 1 1 : round up
    roundDown = !trailingBits[1] ||
                (!keepBit && trailingBits[1] && !trailingBits[0] && !stickyBit);
  end
endmodule
