// Copyright (c) Facebook, Inc. and its affiliates. All Rights Reserved.
// All rights reserved.
//
// This source code is licensed under the license found in the
// LICENSE file in the root directory of this source tree.


// Shifts the input value `in` left by `shift` places, producing all shifted
// bits beyond the MSB of the output width ORed together as `sticky` or ANDed
// together as `stickyAnd`, if any.
//
// Also allows for controlling the size of the shift parameter (thus the depth
// of the barrel shifter), if full shift isn't needed, as well as control over
// the maximum expected value of the shift (if the shift exceeds SHIFT_MAX, the
// result will not be correct).
module ShiftLeftSticky #(parameter IN_WIDTH=8,
                         parameter OUT_WIDTH=8,
                         parameter SHIFT_VAL_WIDTH=$clog2(OUT_WIDTH+1),
                         parameter SHIFT_MAX=2**(SHIFT_VAL_WIDTH)-1)
  (input [IN_WIDTH-1:0] in,
   input [SHIFT_VAL_WIDTH-1:0] shift,
   output logic [OUT_WIDTH-1:0] out,
   output logic sticky,
   output logic stickyAnd);

  logic [OUT_WIDTH-1:0] inPad;

  // Truncate or extend to the output size with 0s on the left
  ZeroPadLeft #(.IN_WIDTH(IN_WIDTH),
                .OUT_WIDTH(OUT_WIDTH))
  zpl(.in,
      .out(inPad));

  logic [OUT_WIDTH-1:0] inPadRev;
  logic [OUT_WIDTH-1:0] outRev;

  always_comb begin
    inPadRev = {<<{inPad}};
    out = {<<{outRev}};
  end

  // Reverse the bits and shift right
  ShiftRightSticky #(.IN_WIDTH(OUT_WIDTH),
                     .OUT_WIDTH(OUT_WIDTH),
                     .SHIFT_VAL_WIDTH(SHIFT_VAL_WIDTH),
                     .SHIFT_MAX(SHIFT_MAX))
  sr(.in(inPadRev),
     .shift,
     .out(outRev),
     .sticky,
     .stickyAnd);

endmodule
