// Copyright (c) Facebook, Inc. and its affiliates. All Rights Reserved.
// All rights reserved.
//
// This source code is licensed under the license found in the
// LICENSE file in the root directory of this source tree.

// Converts a small fixed-point value to a larger one in the same form
// as a Kulisch accumulator
// This version expects the fixed-point alignment right before the start of the
// accumulator's LSB
//              |
//              V
// sooommmm.ffff
//           smm.ffff
module KulischConvertFixed #(parameter FRAC=8,
                             parameter EXP=6,
                             parameter ACC_NON_FRAC=13,
                             parameter ACC_FRAC=12,
                             parameter OVERFLOW_DETECTION=1)
  (input [EXP-1:0] expIn,
   // In the form smm.ffff, including sign (2s complement)
   input signed [2:-FRAC] fixedIn,
   // Is the input inf?
   input fixedInfIn,
   Kulisch.OutputIf out);

  // FIXME
  localparam ACC_BITS = KulischDef::getBits(ACC_NON_FRAC, ACC_FRAC);
  localparam EXTENDED_ACC_BITS = ACC_BITS + FRAC;

  initial begin
    assert(out.ACC_NON_FRAC == ACC_NON_FRAC);
    assert(out.ACC_FRAC == ACC_FRAC);
  end

  // This is {leading bits} smm.ffff which is the initial alignment of the
  // fixed-point value
  logic signed [EXTENDED_ACC_BITS-1:0] fixedInExtended;

  // This is the value post alignment
  logic signed [EXTENDED_ACC_BITS-1:0] fixedInAligned;

  // This is the value post alignment and truncation
  logic signed [ACC_BITS-1:0] fixedInAlignedTruncated;

  // Post-shift, we lop off the trailing bits, and append the sign bit to the
  // top to form a full accumulator for addition
  logic signed [ACC_BITS-1:0] alignedInAddend;

  logic fixedInSign;
  logic overflow;

  generate
    if (OVERFLOW_DETECTION) begin
      // This is used for both alignment, and to determine overflow for positive
      // values based on the sticky bit.
      logic posOverflowSticky;
      logic negOverflowSticky;

      ShiftLeftSticky #(.IN_WIDTH(EXTENDED_ACC_BITS),
                        .OUT_WIDTH(EXTENDED_ACC_BITS),
                        .SHIFT_VAL_WIDTH(EXP))
      sls(.in(fixedInExtended),
          .shift(expIn),
          .out(fixedInAligned),
          .sticky(posOverflowSticky),
          .stickyAnd(negOverflowSticky));

      always_comb begin
        // Assuming the input value is non-zero, we need to determine if an expIn
        // shift will produce a positive or negative overflow.
        // We look to see if the sign bit changed, and also look to see if the
        // sticky bit (OR for positive, AND for negative) got overflowed into as
        // well.
        //
        // FIXME: would it be cheaper to use a comparator on the exponent?
        // However, there might not be any guarantee that there is a leading 1 left
        // of the fixed point in the input. This solution works regardless of the
        // input digits.
        overflow = (!fixedInSign && (posOverflowSticky ||
                                     fixedInAlignedTruncated[ACC_BITS-1])) ||
                   (fixedInSign && (!negOverflowSticky ||
                                    !fixedInAlignedTruncated[ACC_BITS-1]));
      end
    end else begin
      always_comb begin
        fixedInAligned = fixedInExtended << expIn;
        overflow = 1'b0;
      end
    end
  endgenerate

  always_comb begin
    fixedInSign = fixedIn[2];

    // Exponent zero is aligned with the final digit in the accumulator
    //
    // sooommmm.fffff
    //            smm.ffff
    //
    // Pad with leading 0s if positive or leading 1s if negative,
    // shift, then truncate the trailing bits
    // e.g.,
    // sooommmm.fffff
    //         smm.ffff
    // =>
    // sooommmm.fffff
    //         smm.ff
    // FIXME: what about sticky bit for any remainder?

    // fixedInSigned expanded to the full accumulator
    fixedInExtended = {{(ACC_BITS-3){fixedInSign}}, fixedIn};

    // Truncate the post-shifted value
    fixedInAlignedTruncated = fixedInAligned[EXTENDED_ACC_BITS-1-:ACC_BITS];

    out.data.isInf = fixedInfIn;
    out.data.isOverflow = overflow;
    out.data.overflowSign = overflow && fixedInSign;
    out.data.bits = fixedInAlignedTruncated;
  end
endmodule
