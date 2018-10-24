// Copyright (c) Facebook, Inc. and its affiliates. All Rights Reserved.
// All rights reserved.
//
// This source code is licensed under the license found in the
// LICENSE file in the root directory of this source tree.


// Shifts the input value `in` right by `shift` places, producing all shifted
// bits beyond the MSB of the output width ORed together as `sticky` or ANDed
// together as `stickyAnd`, if any.
//
// Also allows for controlling the size of the shift parameter (thus the depth
// of the barrel shifter), if full shift isn't needed, as well as control over
// the maximum expected value of the shift (if the shift exceeds SHIFT_MAX, the
// result will not be correct).
module ShiftRightSticky #(parameter IN_WIDTH=8,
                          parameter OUT_WIDTH=8,
                          parameter SHIFT_VAL_WIDTH=$clog2(OUT_WIDTH+1),
                          parameter SHIFT_MAX=2**(SHIFT_VAL_WIDTH)-1)
  (input [IN_WIDTH-1:0] in,
   input [SHIFT_VAL_WIDTH-1:0] shift,
   output logic [OUT_WIDTH-1:0] out,
   output logic sticky,
   output logic stickyAnd);

  // The number of levels of the shifter is based on the output width
  localparam NUM_STEPS = SHIFT_MAX >= OUT_WIDTH ?
                         $clog2(OUT_WIDTH) : $clog2(SHIFT_MAX);

  wire [NUM_STEPS:0][OUT_WIDTH-1:0] val;
  wire [NUM_STEPS:0] valSticky;
  wire [NUM_STEPS:0] valStickyAnd;
  wire maxShift;

  genvar i;
  genvar j;

  // Truncate or extend to the output size with 0s on the right
  ZeroPadRight #(.IN_WIDTH(IN_WIDTH),
                 .OUT_WIDTH(OUT_WIDTH))
  zpr(.in,
      .out(val[0]));

  generate
    // If we're truncating ourselves for the output, then the sticky bit needs
    // to include bits that we are truncating
    if (IN_WIDTH <= OUT_WIDTH) begin : srs1
      assign valSticky[0] = 1'b0;
      assign valStickyAnd[0] = 1'b1;
    end else begin : srs2
      assign valSticky[0] = |in[IN_WIDTH-OUT_WIDTH-1:0];
      assign valStickyAnd[0] = &in[IN_WIDTH-OUT_WIDTH-1:0];
    end

    for (i = 1; i <= NUM_STEPS; ++i) begin : srs3
      // Build shift bit selector
      for (j = 0; j < OUT_WIDTH; ++j) begin : srs4
        if (j + (2 ** (i - 1)) >= OUT_WIDTH) begin : srs5
          assign val[i][j] = shift[i - 1] ? 1'b0 : val[i - 1][j];
        end else begin : srs6
          assign val[i][j] =
            shift[i - 1] ? val[i - 1][j + (2 ** (i - 1))] : val[i - 1][j];
        end
      end

      // Build sticky bits
      assign valSticky[i] = valSticky[i - 1] |
                            (shift[i - 1] ? |val[i - 1][(2 **(i - 1))-1:0] : 1'b0);
      assign valStickyAnd[i] = valStickyAnd[i - 1] &
                               (shift[i - 1] ? &val[i - 1][(2 **(i - 1))-1:0] : 1'b1);
    end

    // The shift tree handles the maximum possible in-bounds shift; for
    // out-of-bounds shift, we prefer a separate comparator, as this can happen
    // in parallel with the barrel shifter
    if (SHIFT_MAX < OUT_WIDTH) begin : srs7
      assign out = val[NUM_STEPS];
      assign sticky = valSticky[NUM_STEPS];
      assign stickyAnd = valStickyAnd[NUM_STEPS];
    end else if (SHIFT_MAX == OUT_WIDTH) begin : srs8
      assign maxShift = shift == OUT_WIDTH;
      assign out = maxShift ? {OUT_WIDTH{1'b0}} : val[NUM_STEPS];
      assign sticky = maxShift ? (|val[0] | valSticky[0]) : valSticky[NUM_STEPS];
      assign stickyAnd = maxShift ? (&val[0] & valStickyAnd[0]) : valStickyAnd[NUM_STEPS];
    end else begin : srs9
      assign maxShift = shift >= OUT_WIDTH;
      assign out = maxShift ? {OUT_WIDTH{1'b0}} : val[NUM_STEPS];
      assign sticky = maxShift ? (|val[0] | valSticky[0]) : valSticky[NUM_STEPS];
      assign stickyAnd = maxShift ? (&val[0] & valStickyAnd[0]) : valStickyAnd[NUM_STEPS];
    end
  endgenerate
endmodule
