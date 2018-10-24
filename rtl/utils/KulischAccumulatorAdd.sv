// Copyright (c) Facebook, Inc. and its affiliates. All Rights Reserved.
// All rights reserved.
//
// This source code is licensed under the license found in the
// LICENSE file in the root directory of this source tree.

// Sum of two Kulisch accumulators together, where the overflow state (if any)
// is preserved from accA
module KulischAccumulatorAdd #(parameter ACC_NON_FRAC=8,
                               parameter ACC_FRAC=8,
                               parameter OVERFLOW_DETECTION=1)
  (Kulisch.InputIf a,
   Kulisch.InputIf b,
   Kulisch.OutputIf out);

  initial begin
    assert(a.ACC_NON_FRAC == ACC_NON_FRAC);
    assert(a.ACC_FRAC == ACC_FRAC);

    assert(b.ACC_NON_FRAC == ACC_NON_FRAC);
    assert(b.ACC_FRAC == ACC_FRAC);

    assert(out.ACC_NON_FRAC == ACC_NON_FRAC);
    assert(out.ACC_FRAC == ACC_FRAC);
  end

  logic overflow;
  logic overflowSign;

  generate
    if (OVERFLOW_DETECTION) begin
      logic isNegA;
      logic isNegB;
      logic isNegOut;

      // If a and b are not in overflow, but if the sum of the two causes an
      // overflow
      logic nonOverflowSumIsOverflow;

      logic inputsAreOverflow;
      logic inputOverflowSign;
      logic inputUniqueOverflowSign;

      always_comb begin
        isNegA = a.getSign(a.data);
        isNegB = b.getSign(b.data);
        isNegOut = out.getSign(out.data);

        // The sum of two non-overflow values causes an overflow if both inputs are
        // negative but the result is positive, or both are positive and the result
        // is negative
        nonOverflowSumIsOverflow = (isNegA && isNegB && !isNegOut) ||
                                   (!isNegA && !isNegB && isNegOut);

        // Whether or not either of the inputs are in the overflow state
        inputsAreOverflow = a.data.isOverflow || b.data.isOverflow;

        // If only one of the input values is in overflow, we take that sign as our
        // overflow sign.
        inputOverflowSign = // A is in overflow, B is not, use A
                            (a.data.isOverflow &&
                             !b.data.isOverflow &&
                             a.data.overflowSign) ||
                            // B is in overflow, A is not, use B
                            (!a.data.isOverflow &&
                             b.data.isOverflow &&
                             b.data.overflowSign) ||
                            // Both are in overflow, use A
                            (a.data.isOverflow &&
                             b.data.isOverflow &&
                             a.data.overflowSign);

        overflow = inputsAreOverflow || nonOverflowSumIsOverflow;
        overflowSign = inputsAreOverflow ? inputOverflowSign :
                       // Otherwise, overflow can only be caused by
                       // adding two pos or neg values
                       (nonOverflowSumIsOverflow ?
                        (isNegA && isNegB) : 1'b0);
      end
    end else begin
      always_comb begin
        overflow = 1'b0;
        overflowSign = 1'b0;
      end
    end
  endgenerate

  always_comb begin
    out.data.isInf = a.data.isInf | b.data.isInf;
    out.data.isOverflow = overflow;
    out.data.overflowSign = overflowSign;
    out.data.bits = a.data.bits + b.data.bits;
  end
endmodule
