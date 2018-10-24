// Copyright (c) Facebook, Inc. and its affiliates. All Rights Reserved.
// All rights reserved.
//
// This source code is licensed under the license found in the
// LICENSE file in the root directory of this source tree.

// Receives a configurable number of bits from the source, plus a sticky bit for
// the remainder
module FloatRoundStochastic #(parameter EXP=8,
                              parameter FRAC=23,
                              parameter ROUND_BITS=8)
  (Float.InputIf in,
   input [ROUND_BITS-1:0] trailingBitsIn,
   input stickyBitIn,
   input isNanIn,
   // FIXME: does not match what I did with posits
   input [ROUND_BITS-1:0] randomBitsIn,
   Float.OutputIf out);

  initial begin
    assert(in.EXP == EXP);
    assert(in.FRAC == FRAC);
    assert(out.EXP == EXP);
    assert(out.FRAC == FRAC);
  end

  localparam FIRST_FRACTION_BIT = FRAC - 1;
  localparam LAST_FRACTION_BIT = 0;

  logic roundDown;
  logic [ROUND_BITS:0] roundCheck;

  logic [EXP+FRAC-1:0] expAndFraction;
  logic [EXP+FRAC-1:0] expAndFractionIncrement;

  always_comb begin
    // FIXME: we can either use a sum with carry bit, or a comparator.
    // The sum with carry bit is likely faster on an FPGA
    //
    // Comparator method:
    // round up if sample is < the value
    // val 4h0 => will not round up
    // val 4hf => will round up if the random bits are not 4hf
    //
    // carry method:
    // Add random bits to trailing bits, round up if there is a carry
    // val 4h0 => will not round up
    // val 4hf => will round up if the random bits are not 4h0
    //
    // FIXME: how to use the sticky bits?
    roundDown = !(trailingBitsIn < randomBitsIn);

    // roundCheck = (ROUND_BITS+1)'(trailingBitsIn) +
    //              (ROUND_BITS+1)'(randomBitsIn);
    // roundDown = !roundCheck[ROUND_BITS];

    expAndFraction[EXP+FRAC-1:FRAC] = in.data.exponent;
    expAndFraction[FRAC-1:0] = in.data.fraction;

    expAndFractionIncrement = expAndFraction + !roundDown;

    out.data.sign = in.data.sign;
    // If the input was inf or NaN (we only set the leading 1 bit in the NaN
    // field), then the exponent field won't be rounded up, so this is safe
    out.data.exponent = expAndFractionIncrement[EXP+FRAC-1:FRAC];

    if (isNanIn) begin
      // The input may be +/-inf or NaN, just pass the fraction field through
      out.data.fraction = in.data.fraction;
    end else if (out.data.exponent == {EXP{1'b1}}) begin
      // We rounded up/down to +/- inf
      out.data.fraction = {FRAC{1'b0}};
    end else begin
      out.data.fraction = expAndFractionIncrement[FRAC-1:0];
    end
  end
endmodule
