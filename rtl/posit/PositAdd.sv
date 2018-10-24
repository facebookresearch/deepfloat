// Copyright (c) Facebook, Inc. and its affiliates. All Rights Reserved.
// All rights reserved.
//
// This source code is licensed under the license found in the
// LICENSE file in the root directory of this source tree.

// A combinational-only implementation
module PositAdd #(parameter WIDTH=8,
                  parameter ES=1,
                  parameter TRAILING_BITS=2)
  (PositUnpacked.InputIf a,
   PositUnpacked.InputIf b,
   PositUnpacked.OutputIf out,
   output logic [TRAILING_BITS-1:0] trailingBits,
   output logic stickyBit,
   input subtract);

  initial begin
    assert(a.WIDTH == b.WIDTH);
    assert(a.WIDTH == out.WIDTH);
    assert(a.WIDTH == WIDTH);
    assert(a.ES == b.ES);
    assert(a.ES == out.ES);
    assert(a.ES == ES);
  end

  localparam LOCAL_FRACTION_BITS = PositDef::getFractionBits(WIDTH, ES);
  localparam LOCAL_UNSIGNED_EXPONENT_BITS = PositDef::getUnsignedExponentBits(WIDTH, ES);
  localparam LOCAL_MAX_UNSIGNED_EXPONENT = PositDef::getMaxUnsignedExponent(WIDTH, ES);

  // Whether or not we are performing addition or subtraction (based
  // on the input subtract request and the signs of the
  // operands). The actual operation performed may be either addition
  // or subtraction regardless of the `subtract` input.
  typedef enum logic {ADD, SUBTRACT} AddMode;
  AddMode mode;

  // carry bit, leading 1, fraction bits, trailing bits, sticky bit
  localparam NUM_FRAC_CALC_BITS = 2 + LOCAL_FRACTION_BITS + TRAILING_BITS + 1;
  localparam MSB_BIT = NUM_FRAC_CALC_BITS - 1;
  localparam CARRY_BIT = MSB_BIT;
  localparam LEADING_BIT = MSB_BIT - 1;
  localparam FIRST_FRACTION_BIT = MSB_BIT - 2;
  localparam LAST_FRACTION_BIT = TRAILING_BITS + 1;

  logic [LOCAL_UNSIGNED_EXPONENT_BITS-1:0] largeExponent;
  logic [LOCAL_UNSIGNED_EXPONENT_BITS-1:0] smallExponent;

  logic [NUM_FRAC_CALC_BITS-1:0] largeFraction;
  logic [NUM_FRAC_CALC_BITS-1:0] smallFraction;
  logic [NUM_FRAC_CALC_BITS-1:0] outFraction;

  // post-subtraction normalization fraction
  logic [LOCAL_FRACTION_BITS+TRAILING_BITS+1-1:0] fracRenormalized;

  logic outSign;
  logic anyIsInf;
  logic largeZero;
  logic largeExponentIsMax;

  // The real sign that we apply to B for addition or subtraction
  // purposes
  logic signBInversion;

  logic exponentAGtB;
  logic exponentAEqB;
  logic fractionAGtB;
  logic aGtB;

  // Difference in exponents between large and small number
  logic [LOCAL_UNSIGNED_EXPONENT_BITS-1:0] expDifference;

  // When aligning the smaller fraction, we use this to keep track of the sticky
  // bit
  // We skip the sticky bit in the input, and then attach it at the end
  logic [NUM_FRAC_CALC_BITS-2:0] smallFractionShiftedNoSticky;
  logic [NUM_FRAC_CALC_BITS-1:0] smallFractionShifted;
  logic shiftedStickyBit;

  ShiftRightSticky #(.IN_WIDTH(NUM_FRAC_CALC_BITS-1),
                     .OUT_WIDTH(NUM_FRAC_CALC_BITS-1),
                     .SHIFT_VAL_WIDTH(LOCAL_UNSIGNED_EXPONENT_BITS))
  srs(.in(smallFraction[NUM_FRAC_CALC_BITS-1:1]),
      .shift(expDifference),
      .out(smallFractionShiftedNoSticky),
      .sticky(shiftedStickyBit),
      .stickyAnd());

  // For subtraction, we need to find the leading 1 after the
  // subtraction to renormalize the exponent.
  //
  // How far we shift is clz + 1 (i.e., ignore the leading 1)
  // Our exponent adjustment is -clz
  logic [$clog2(NUM_FRAC_CALC_BITS)-1:0] countLeadingZeros;

  CountLeadingZeros #(.WIDTH(NUM_FRAC_CALC_BITS - 1))
  clz(.in(outFraction[LEADING_BIT:0]), .out(countLeadingZeros));

  always_comb begin
    signBInversion = subtract ? !b.data.sign : b.data.sign;
    anyIsInf = a.data.isInf || b.data.isInf;

    mode = (a.data.sign == signBInversion) ? ADD : SUBTRACT;

    exponentAGtB = a.data.exponent > b.data.exponent;
    exponentAEqB = a.data.exponent == b.data.exponent;
    fractionAGtB = a.data.fraction > b.data.fraction;

    if (a.data.isZero && !b.data.isZero) begin
      aGtB = 1'b0;
    end else if (!a.data.isZero && b.data.isZero) begin
      aGtB = 1'b1;
    end else begin
      aGtB = mode == ADD ? exponentAGtB :
             exponentAGtB || (exponentAEqB && fractionAGtB);
    end

    outSign = mode == ADD ? a.data.sign :
              (aGtB ? a.data.sign : signBInversion);

    largeFraction = {1'b0,
                     aGtB ? !a.data.isZero : !b.data.isZero,
                     aGtB ? a.data.fraction : b.data.fraction,
                     TRAILING_BITS'(1'b0), 1'b0};
    smallFraction = {1'b0,
                     aGtB ? !b.data.isZero : !a.data.isZero,
                     aGtB ? b.data.fraction : a.data.fraction,
                     TRAILING_BITS'(1'b0), 1'b0};

    largeZero = aGtB ? a.data.isZero : b.data.isZero;
    largeExponent = aGtB ? a.data.exponent : b.data.exponent;
    smallExponent = aGtB ? b.data.exponent : a.data.exponent;

    expDifference = largeExponent - smallExponent;

    smallFractionShifted = {smallFractionShiftedNoSticky, shiftedStickyBit};

    outFraction = mode == ADD ?
                  largeFraction + smallFractionShifted :
                  largeFraction - smallFractionShifted;

    // For re-alignment after subtraction, we skip the carry and leading bit.
    fracRenormalized = outFraction[LOCAL_FRACTION_BITS+TRAILING_BITS+1-1:0]
                       << countLeadingZeros;

    if (anyIsInf) begin
      out.data = out.inf();
      trailingBits = TRAILING_BITS'(1'b0);
      stickyBit = 1'b0;
    end else begin
      case (mode)
        ADD: begin
          out.data.sign = outSign;
          out.data.isInf = 1'b0;
          out.data.isZero = largeZero;

          // Add 1 if a carry, unless we are already at max
          out.data.exponent = largeExponent + (outFraction[CARRY_BIT] &&
                                          largeExponent !=
                                          LOCAL_MAX_UNSIGNED_EXPONENT);
          out.data.fraction = outFraction[CARRY_BIT] ?
                         outFraction[LEADING_BIT-:LOCAL_FRACTION_BITS] :
                         outFraction[FIRST_FRACTION_BIT-:LOCAL_FRACTION_BITS];
          trailingBits = outFraction[CARRY_BIT] ?
                         outFraction[LAST_FRACTION_BIT-:TRAILING_BITS] :
                         outFraction[LAST_FRACTION_BIT-1-:TRAILING_BITS];
          stickyBit = outFraction[CARRY_BIT] ?
                      |outFraction[1:0] :
                      outFraction[0];
        end
        SUBTRACT: begin
          // We use these to determine our zero sign as well
          trailingBits = fracRenormalized[TRAILING_BITS-:TRAILING_BITS];
          stickyBit = fracRenormalized[0];

          out.data.isInf = 1'b0;
          out.data.isZero = (countLeadingZeros > largeExponent ||
                        countLeadingZeros == (NUM_FRAC_CALC_BITS-1));
          out.data.sign = out.data.isZero ? ((|trailingBits | stickyBit) ? a.data.sign : 1'b0)
            : outSign;

          out.data.exponent = out.data.isZero ?
                         LOCAL_UNSIGNED_EXPONENT_BITS'(1'b0) :
                         largeExponent - countLeadingZeros;
          out.data.fraction = out.data.isZero ?
                         LOCAL_FRACTION_BITS'(1'b0) :
                         fracRenormalized[FIRST_FRACTION_BIT:LAST_FRACTION_BIT];
        end
      endcase
    end
  end
endmodule
