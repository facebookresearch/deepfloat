// Copyright (c) Facebook, Inc. and its affiliates. All Rights Reserved.
// All rights reserved.
//
// This source code is licensed under the license found in the
// LICENSE file in the root directory of this source tree.

// We don't preserve NaN signs, or care about signalling / non-signalling NaNs.
// All NaNs are +nan with the MSB of the fraction field set to 1, all other 0.
// FIXME: make denormal handling optional
// FIXME: make sticky bit calculation optional
module FloatAddImpl #(parameter EXP=8,
                      parameter FRAC=23,
                      parameter TRAILING_BITS=2)
  (Float.InputIf inA,
   // Provided by our caller, as we may have a preprocessor that is determining
   // these anyways, so no need to perform the same work
   input isInfA,
   input isNanA,
   input isZeroA,
   input isDenormalA,
   Float.InputIf inB,
   // Provided by our caller, as we may have a preprocessor that is determining
   // these anyways, so no need to perform the same work
   input isInfB,
   input isNanB,
   input isZeroB,
   input isDenormalB,

   // Whether we are adding or subtracting the arguments
   input subtract,

   Float.OutputIf out,

   // Trailing bits for rounding purposes from the multiplication
   output logic [TRAILING_BITS-1:0] trailingBitsOut,
   // the stickyBitOut is the bitwise OR of all other bits not
   // retained in TRAILING_BITS
   output logic stickyBitOut,
   output logic isNanOut,
   input reset,
   input clock);

  initial begin
    assert(inA.EXP == inB.EXP);
    assert(inA.EXP == EXP);

    assert(inA.FRAC == inB.FRAC);
    assert(inA.FRAC == FRAC);
  end

  // We do our math in this expanded space, with 2 + TRAILING_BITS more digits
  // than the input fraction:
  // (01).ffff...ff(xxx)
  // #f is the FRAC
  // #x is the TRAILING_BITS
  localparam NUM_FRAC_CALC_BITS = 2 + FRAC + TRAILING_BITS;
  localparam MSB_BIT = NUM_FRAC_CALC_BITS - 1;
  localparam CARRY_BIT = MSB_BIT;
  localparam LEADING_BIT = MSB_BIT - 1;
  localparam FIRST_FRACTION_BIT = MSB_BIT - 2;
  localparam LAST_FRACTION_BIT = TRAILING_BITS;

  // Whether or not we are performing addition or subtraction (based
  // on the input subtract request and the signs of the
  // operands). The actual operation performed may be either addition
  // or subtraction regardless of the `subtract` input.
  typedef enum logic {ADD, SUBTRACT} AddMode;

  //
  // Combinational logic
  //

  // cycle 1

  // The sign of B corrected for subtraction
  logic signBCorrected;

  logic [MSB_BIT:0] smallFraction;
  logic [EXP-1:0] expDifference;

  // Output of the reduce OR for determining the sticky bit
  logic stickyBit;

  AddMode desiredMode;

  // In order to find the larger of the two summands
  logic aGtB;
  logic exponentAGtB;
  logic exponentAEqB;
  logic fractionAGtB;

  logic outIsNan;
  logic outIsInf;

  Float #(.EXP(EXP), .FRAC(FRAC)) larger();
  Float #(.EXP(EXP), .FRAC(FRAC)) smaller();

  logic largerIsZeroExp;
  logic smallerIsZeroExp;

  // cycle 3

  // Result of the number of leading zeros for post-subtraction
  // normalization
  logic [$clog2(NUM_FRAC_CALC_BITS)-1:0] countLeadingZeros;

  //
  // Registers
  //

  // cycle 1

  logic [MSB_BIT:0] outFraction_D_1;
  logic [MSB_BIT:0] smallFraction_D_1;
  logic outIsNan_D_1;
  logic outIsInf_D_1;
  logic outSign_D_1;

  logic [EXP-1:0] outExponent_D_1;
  logic outStickyBit_D_1;
  logic largerIsZeroExp_D_1;
  AddMode mode_D_1;

  // cycle 2

  logic [MSB_BIT:0] outFraction_D_2;
  logic outIsNan_D_2;
  logic outIsInf_D_2;
  logic outSign_D_2;

  logic [EXP-1:0] outExponent_D_2;
  logic outStickyBit_D_2;
  logic largerIsZeroExp_D_2;
  AddMode mode_D_2;

  // cycle 3

  logic [MSB_BIT:0] outFraction_D_3;
  logic outIsNan_D_3;
  logic outSign_D_3;

  logic [EXP-1:0] outExponent_D_3;
  logic outStickyBit_D_3;
  logic largerIsZeroExp_D_3;
  AddMode mode_D_3;

  //
  // Sub-modules
  //

  // For subtraction, we need to find the leading 1 after the
  // subtraction to renormalize the exponent
  CountLeadingZeros #(.WIDTH(NUM_FRAC_CALC_BITS - 1))
  clz(.in(outFraction_D_2[MSB_BIT-1:0]), .out(countLeadingZeros));

  // To determine the sticky bit, we need to reduce shifted out bits
  // that are not retained in the trailing bits
  ReduceOrTrailingBits #(.WIDTH(NUM_FRAC_CALC_BITS - 1),
                         .N_WIDTH(EXP))
  reduceOr(.in(smallFraction[LEADING_BIT:0]),
           .n(expDifference),
           .out(stickyBit));

  //
  // Combinational logic
  //

  always_comb begin
    //
    // cycle 1
    //

    signBCorrected = subtract ? !inB.data.sign : inB.data.sign;
    desiredMode = (inA.data.sign == signBCorrected) ? ADD : SUBTRACT;

    exponentAGtB = inA.data.exponent > inB.data.exponent;
    exponentAEqB = inA.data.exponent == inB.data.exponent;
    fractionAGtB = inA.data.fraction > inB.data.fraction;

    // Determine if our output should be NaN
    outIsNan = // either input is NaN
               (isNanA || isNanB) ||
               // or, both inputs are +/- inf and the sign is mixed
               (isInfA && isInfB && (desiredMode == SUBTRACT));
    outIsInf = !outIsNan && (isInfA || isInfB);

    // Sort values
    aGtB = (desiredMode == ADD) ? exponentAGtB :
           exponentAGtB || (exponentAEqB && fractionAGtB);

    larger.data = aGtB ?
                  inA.data :
                  {signBCorrected, inB.data.exponent, inB.data.fraction};
    smaller.data = aGtB ?
                   {signBCorrected, inB.data.exponent, inB.data.fraction} :
                   inA.data;

    largerIsZeroExp = aGtB ?
                      (isDenormalA || isZeroA) : (isDenormalB || isZeroB);
    smallerIsZeroExp = aGtB ?
                       (isDenormalB || isZeroB) : (isDenormalA || isZeroA);

    smallFraction = {1'b0, !smallerIsZeroExp,
                     smaller.data.fraction, {TRAILING_BITS{1'b0}}};

    // If the larger is normal and the smaller is denormal,
    // then we have to add one additional, since both are
    // already aligned in the expanded representation below
    // despite the exponent difference of 1
    // e.g., 1.0 x 2^-126 versus 0.1 x 2^-126 for 1:8:23
    expDifference = larger.data.exponent - smaller.data.exponent -
                    (!largerIsZeroExp && smallerIsZeroExp);

    //
    // cycle 3
    //

    out.data.sign = outSign_D_3;
    out.data.exponent = outExponent_D_3;
    out.data.fraction = outFraction_D_3[FIRST_FRACTION_BIT:LAST_FRACTION_BIT];
    trailingBitsOut = outFraction_D_3[TRAILING_BITS-1:0];
    stickyBitOut = outStickyBit_D_3;
    isNanOut = outIsNan_D_3;
  end

  //
  // Clocked logic
  //

  always_ff @(posedge clock) begin
    if (reset) begin
      outFraction_D_1 <= 0;
      smallFraction_D_1 <= 0;
      outIsNan_D_1 <= 0;
      outIsInf_D_1 <= 0;
      outSign_D_1 <= 0;

      outExponent_D_1 <= 0;
      outStickyBit_D_1 <= 0;
      largerIsZeroExp_D_1 <= 0;
      mode_D_1 <= ADD;

      outFraction_D_2 <= 0;
      outIsNan_D_2 <= 0;
      outIsInf_D_2 <= 0;
      outSign_D_2 <= 0;

      outExponent_D_2 <= 0;
      outStickyBit_D_2 <= 0;
      largerIsZeroExp_D_2 <= 0;
      mode_D_2 <= ADD;

      outFraction_D_3 <= 0;
      outIsNan_D_3 <= 0;
      outSign_D_3 <= 0;

      outExponent_D_3 <= 0;
      outStickyBit_D_3 <= 0;
      largerIsZeroExp_D_3 <= 0;
      mode_D_3 <= ADD;
    end
    else begin
      //
      // cycle 1
      //
      outExponent_D_1 <= larger.data.exponent;

      // We represent the fraction with the implicit leading 1
      // bit for normal values:
      // 1.fffff if normal
      // 0.fffff if denormal
      //
      // For addition, we need to know if there is a carry, so
      // we add an additional leading bit:
      // 01.fffff if normal
      // 00.fffff if denormal
      // We form the sum (or difference) in the larger number
      outFraction_D_1 <= {1'b0, !largerIsZeroExp,
                          larger.data.fraction, {TRAILING_BITS{1'b0}}};

      // Shift the smaller value into place
      smallFraction_D_1 <= smallFraction >> expDifference;

      largerIsZeroExp_D_1 <= largerIsZeroExp;

      outIsNan_D_1 <= outIsNan;
      outIsInf_D_1 <= outIsInf;

      // Whether or not we are performing an addition or a
      // subtraction
      // If both signs are the same, we are adding.
      // If the signs are mixed (post inversion above), we are
      // subtracting.
      mode_D_1 <= desiredMode;

      // This is the final sign for addition; capture it
      // before sorting
      outSign_D_1 <= desiredMode == ADD ? inA.data.sign :
                     (aGtB ? inA.data.sign : signBCorrected);

      // The sticky bit returned is the OR of all
      // max(FRAC + TRAILING_BITS, expDifference_D) least
      // significant bits in {smallerFraction, TRAILING_BITS'b0}
      // If this is 0, then it is !smallerIsZeroExp (i.e.,
      // whether there was a leading 1 bit that was also
      // shifted away). We could represent this in the shifter
      // thing too.
      outStickyBit_D_1 <= stickyBit;

      //
      // cycle 2
      //

      // If we had bits before and we don't afterwards, and
      // we're subtracting, then we have to subtract {0s, 1}
      // with the 1 in the position of the last trailing bit?
      // FIXME
      outFraction_D_2 <= mode_D_1 == ADD ?
                         outFraction_D_1 + smallFraction_D_1 :
                         outFraction_D_1 - smallFraction_D_1;

      outExponent_D_2 <= outExponent_D_1;
      mode_D_2 <= mode_D_1;
      largerIsZeroExp_D_2 <= largerIsZeroExp_D_1;
      outIsNan_D_2 <= outIsNan_D_1;
      outIsInf_D_2 <= outIsInf_D_1;
      outSign_D_2 <= outSign_D_1;
      outStickyBit_D_2 <= outStickyBit_D_1;

      //
      // cycle 3
      //
      outIsNan_D_3 <= outIsNan_D_2;

      if (outIsNan_D_2) begin
        // We don't care about NaN signs
        outSign_D_3 <= 1'b0;
        outExponent_D_3 <= {EXP{1'b1}};
        outFraction_D_3 <= {3'b001, {(NUM_FRAC_CALC_BITS-3){1'b0}}};
      end
      else if (outIsInf_D_2) begin
        outSign_D_3 <= outSign_D_2;
        outExponent_D_3 <= {EXP{1'b1}};
        outFraction_D_3 <= {(NUM_FRAC_CALC_BITS){1'b0}};
      end
      // FIXME: what about one/both args being inf but output is non-nan?
      else begin
        case (mode_D_2)
          ADD: begin
            // For addition, there may have been a carry.
            // If both values were normal and aligned, you will have a
            // carry:
            // 01.fff +
            // 01.fff =
            // 1x.xxx
            // In the case of the carry, we have to realign the
            // fraction, and add one to the exponent, so we have
            // 01.xxx after alignment
            // The bit that we're shifting out needs to be added to our sticky
            // bits, which we do below
            outFraction_D_3 <= outFraction_D_2[CARRY_BIT] ?
                               // shift right 1
                               {1'b0, outFraction_D_2[MSB_BIT:1]} :
                               outFraction_D_2[MSB_BIT:0];

            // Addition can promote ourselves from denormal to normal:
            // 00.fff +
            // 00.fff =
            // 01.xxx
            outExponent_D_3 <= (outFraction_D_2[CARRY_BIT] ||
                                (outFraction_D_2[LEADING_BIT] &&
                                 largerIsZeroExp_D_2)) ?
                               outExponent_D_2 + 1'b1 :
                               outExponent_D_2;

            outSign_D_3 <= outSign_D_2;
          end
          SUBTRACT: begin
            // For subtraction, we need to renormalize the fraction;
            // i.e., move the leading 1 to the proper place again.
            // countLeadingZeros is the shift required here.
            // If the larger value is already denormalized (thus,
            // smaller is denormalized too), then we never shift.
            // If the shift is greater than the larger's exponent,
            // then we are becoming denormalized. The smallest
            // normalized and the denormalized values have the same
            // alignment, so shift by exp - 1.
            // Otherwise, the count of the leading zeros after the
            // subtraction is exactly the shift we want.
            if (largerIsZeroExp_D_2) begin
              // Already denormal
              outFraction_D_3 <= outFraction_D_2;
            end
            else if (countLeadingZeros >= outExponent_D_2) begin
              // Becoming denormal
              outFraction_D_3 <= outFraction_D_2 << (outExponent_D_2 - 1);
            end
            else begin
              // Shift by clz
              outFraction_D_3 <= outFraction_D_2 << countLeadingZeros;
            end

            // Subtraction can demote ourselves from normal to denormal:
            // 01.fff -
            // 01.fff =
            // 00.fff
            //
            // Likewise, if our answer is all zero, we are zero
            // (the leading bit is in our shifted representation)
            outExponent_D_3 <= (countLeadingZeros > outExponent_D_2) ||
                               (countLeadingZeros == NUM_FRAC_CALC_BITS - 1) ?
                               EXP'(1'b0) : outExponent_D_2 - countLeadingZeros;

            outSign_D_3 <= (countLeadingZeros == NUM_FRAC_CALC_BITS - 1) ?
                           0 : outSign_D_2;
          end
        endcase
      end

      // If there was a carry for the add, we shifted the fraction, and thus
      // there is an additional sticky bit
      outStickyBit_D_3 <= outStickyBit_D_2 |
                          (outFraction_D_2[CARRY_BIT] && outFraction_D_2[0]);
    end
  end
endmodule

module FloatAdd #(parameter EXP_IN_A=8,
                  parameter FRAC_IN_A=23,
                  parameter EXP_IN_B=8,
                  parameter FRAC_IN_B=23,
                  parameter EXP_OUT=8,
                  parameter FRAC_OUT=23,
                  parameter TRAILING_BITS=2)
  (Float.InputIf inA,
   Float.InputIf inB,
   input subtract,
   Float.OutputIf out,
   output logic [TRAILING_BITS-1:0] trailingBits,
   output logic stickyBit,
   output logic isNan,
   input reset,
   input clock);

  // We must always be expanding, not contracting
  initial begin
    assert(inA.EXP == EXP_IN_A);
    assert(inB.EXP == EXP_IN_B);
    assert(inA.FRAC == FRAC_IN_A);
    assert(inB.FRAC == FRAC_IN_B);

    assert(EXP_IN_A <= EXP_OUT);
    assert(EXP_IN_B <= EXP_OUT);
    assert(FRAC_IN_A <= FRAC_OUT);
    assert(FRAC_IN_B <= FRAC_OUT);
  end

  Float #(.EXP(EXP_OUT), .FRAC(FRAC_OUT)) inAExpand();
  logic isInfA;
  logic isNanA;
  logic isZeroA;
  logic isDenormalA;

  Float #(.EXP(EXP_OUT), .FRAC(FRAC_OUT)) inBExpand();
  logic isInfB;
  logic isNanB;
  logic isZeroB;
  logic isDenormalB;

  // Expand the inputs to the output size if needed
  FloatExpand #(.EXP_IN(EXP_IN_A),
                .FRAC_IN(FRAC_IN_A),
                .EXP_OUT(EXP_OUT),
                .FRAC_OUT(FRAC_OUT))
  expandA(.in(inA),
          .out(inAExpand),
          .isInf(isInfA),
          .isNan(isNanA),
          .isZero(isZeroA),
          .isDenormal(isDenormalA));

  FloatExpand #(.EXP_IN(EXP_IN_B),
                .FRAC_IN(FRAC_IN_B),
                .EXP_OUT(EXP_OUT),
                .FRAC_OUT(FRAC_OUT))
  expandB(.in(inB),
          .out(inBExpand),
          .isInf(isInfB),
          .isNan(isNanB),
          .isZero(isZeroB),
          .isDenormal(isDenormalB));

  FloatAddImpl #(.EXP(EXP_OUT),
                 .FRAC(FRAC_OUT),
                 .TRAILING_BITS(TRAILING_BITS))
  add(.inA(inAExpand),
      .isInfA,
      .isNanA,
      .isZeroA,
      .isDenormalA,
      .inB(inBExpand),
      .isInfB,
      .isNanB,
      .isZeroB,
      .isDenormalB,
      .subtract,
      .out,
      .trailingBitsOut(trailingBits),
      .stickyBitOut(stickyBit),
      .isNanOut(isNan),
      .reset,
      .clock);

endmodule
