// Copyright (c) Facebook, Inc. and its affiliates. All Rights Reserved.
// All rights reserved.
//
// This source code is licensed under the license found in the
// LICENSE file in the root directory of this source tree.

module QuireToPosit #(parameter WIDTH=8,
                      parameter ES=1,
                      parameter OVERFLOW=-1,
                      parameter FRAC_REDUCE=0,
                      parameter TRAILING_BITS=2,
                      parameter USE_ADJUST=0,
                      parameter ADJUST_MUL_SIZE=1)
  (Kulisch.InputIf in,
   // Optional adjustment to the quire to shift the value to lie within a
   // preferred dynamic range
   // e.g., adjustMul = +2 means that the output value is multiplied by 4;
   // -3 means the output value is multiplied by 1/8.
   // Ignored if USE_ADJUST == 0
   input signed [ADJUST_MUL_SIZE-1:0] adjustMul,
   PositUnpacked.OutputIf out,
   output logic [TRAILING_BITS-1:0] trailingBitsOut,
   output logic stickyBitOut);

  localparam ACC_NON_FRAC = QuireDef::getNonFracBits(WIDTH, ES, OVERFLOW, FRAC_REDUCE);
  localparam ACC_FRAC = QuireDef::getFracBits(WIDTH, ES, OVERFLOW);

  localparam ACC_BITS = KulischDef::getBits(ACC_NON_FRAC, ACC_FRAC);

  localparam FIRST_REP_BIT = QuireDef::
                             getFirstRepresentableBit(WIDTH, ES,
                                                      OVERFLOW, FRAC_REDUCE);

  localparam LAST_REP_BIT = QuireDef::
                            getLastRepresentableBit(WIDTH, ES,
                                                    OVERFLOW, FRAC_REDUCE);

  localparam LOCAL_UNSIGNED_EXPONENT_BITS = PositDef::
                                            getUnsignedExponentBits(WIDTH,
                                                                    ES);
  localparam LOCAL_FRACTION_BITS = PositDef::getFractionBits(WIDTH, ES);
  localparam LOCAL_MAX_UNSIGNED_EXPONENT = PositDef::getMaxUnsignedExponent(WIDTH,
                                                                            ES)
    - FRAC_REDUCE;
  localparam LOCAL_MIN_UNSIGNED_EXPONENT = PositDef::getMinUnsignedExponent(WIDTH,
                                                                            ES);

  // This is the portion of the quire that is in the representable range
  // from max to -max, including zero
  localparam REPRESENTABLE_SIZE = QuireDef::getRepresentableSize(WIDTH,
                                                                 ES,
                                                                 OVERFLOW,
                                                                 FRAC_REDUCE);

  localparam EXP_CALC_SIZE = Functions::getMax($clog2(REPRESENTABLE_SIZE+2)+1+
                                               (USE_ADJUST ? ADJUST_MUL_SIZE : 0),
                                               LOCAL_UNSIGNED_EXPONENT_BITS + 1);

  initial begin
    assert(in.ACC_NON_FRAC == ACC_NON_FRAC);
    assert(in.ACC_FRAC == ACC_FRAC);

    assert(out.WIDTH == WIDTH);
    assert(out.ES == ES);
  end

  // The sign of the quire (the leading bit)
  logic quireSign;

  // The quire is stored in twos complement form
  logic [ACC_BITS-1:0] positiveQuire;

  // This is the portion of the quire below the overflow range
  logic [FIRST_REP_BIT:0] nonOverflowQuire;

  // This is the portion of the quire that is in the representable range
  logic [REPRESENTABLE_SIZE-1:0] representableQuire;

  // This is nonOverflowQuire aligned past the leading 1
  logic [FIRST_REP_BIT:0] alignedNonOverflowQuire;

  // This is the location of the leading 1, plus one, in representableQuire
  logic [$clog2(REPRESENTABLE_SIZE+2)-1:0] clzQuire;

  // This is clzQuire after adjustment by adjustMulExpand, with an extra bit to
  // handle signed range
  logic signed [EXP_CALC_SIZE-1:0] expOffsetAdjust;

  // This is our adjusted exponent, which may still be in underflow or overflow
  logic signed [EXP_CALC_SIZE-1:0] expAdjusted;

  // Our final exponent, if we have not underflowed or overflowed
  logic signed [LOCAL_UNSIGNED_EXPONENT_BITS-1:0] expFinal;

  // We overflow if the leading 1 is in the overflow exponent range
  logic exponentOverflow;
  logic overflow;

  // We underflow if the leading 1 is
  logic exponentUnderflow;
  logic underflow;

  // We want to skip the first leading 1 as well, so ADD_OFFSET == 1.
  // This avoids an adder
  // We only care about CLZ within the posit representable range
  CountLeadingZeros #(.WIDTH(REPRESENTABLE_SIZE),
                      .ADD_OFFSET(1))
  clz(.in(representableQuire),
      .out(clzQuire));

  // For extracting the trailing and sticky bits, based on the size of the
  // TRAILING_BITS desired, a part select might be negative.
  // We use this module to prevent that.
  logic [TRAILING_BITS-1:0] trailingBitsUnderflow;
  logic stickyBitUnderflow;

  PartSelect #(.IN_WIDTH(FIRST_REP_BIT+1),
               .START_IDX(LAST_REP_BIT-1),
               .OUT_WIDTH(TRAILING_BITS))
  psUnderflowTrailing(.in(nonOverflowQuire),
                      .out(trailingBitsUnderflow));

  PartSelectReduceOr #(.IN_WIDTH(FIRST_REP_BIT+1),
                       .START_IDX(LAST_REP_BIT-1-TRAILING_BITS))
  psUnderflowSticky(.in(nonOverflowQuire),
                    .out(stickyBitUnderflow));

  logic [TRAILING_BITS-1:0] trailingBitsNormal;
  logic stickyBitNormal;

  PartSelect #(.IN_WIDTH(FIRST_REP_BIT+1),
               .START_IDX(FIRST_REP_BIT-LOCAL_FRACTION_BITS),
               .OUT_WIDTH(TRAILING_BITS))
  psNormalTrailing(.in(alignedNonOverflowQuire),
                   .out(trailingBitsNormal));

  PartSelectReduceOr #(.IN_WIDTH(FIRST_REP_BIT+1),
                       .START_IDX(FIRST_REP_BIT-
                                  LOCAL_FRACTION_BITS-TRAILING_BITS))
  psNormalSticky(.in(alignedNonOverflowQuire),
                 .out(stickyBitNormal));

  // All of the overflow bits ORed together, if any
  logic overflowOrReduce;

  PartSelectReduceOr #(.IN_WIDTH(ACC_BITS),
                       .START_IDX(ACC_BITS-2),
                       .END_IDX(FIRST_REP_BIT+1))
  psOverflow(.in(positiveQuire),
             .out(overflowOrReduce));

  // clz has:
  // 0 -> MAX_SIGNED_EXP * 2
  // quire_bits - 1 -> MIN_EXP * 2
  // Figure out the maximum and minimum posit-representable exponent
  //
  // clz must be >= MAX_SIGNED_EXP + clog2(N+1) but <= MAX_SIGNED_EXP * 3 + clog2(N+1)
  // clz MAX_SIGNED_EXP -> MAX_SIGNED_EXP posit
  // clz MAX_SIGNED_EXP + 1 -> MAX_SIGNED_EXP - 1 posit
  // clz MAX_SIGNED_EXP * 3 -> 0
  // (MAX_SIGNED_EXP * 3 + clog2(N+1) - clz) -> 0

  always_comb begin
    // The quire is in 2s complement form.
    quireSign = in.getSign(in.data);
    positiveQuire = quireSign ? -in.data.bits : in.data.bits;

    nonOverflowQuire = positiveQuire[FIRST_REP_BIT:0];
    representableQuire = positiveQuire[FIRST_REP_BIT:LAST_REP_BIT];

    if (USE_ADJUST) begin
      // Adjustment to the exponent, if any (could be negative)
      expOffsetAdjust = signed'((EXP_CALC_SIZE)'(clzQuire)) -
                        signed'((EXP_CALC_SIZE)'(adjustMul));

      // is newExponent < 0 or newExponent > max unsigned?
      // <0: expOffsetAdjust > the thing
      // > max unsigned
      expAdjusted = signed'(EXP_CALC_SIZE'(LOCAL_MAX_UNSIGNED_EXPONENT + 1)) -
                    EXP_CALC_SIZE'(expOffsetAdjust);
      expFinal = expAdjusted[LOCAL_UNSIGNED_EXPONENT_BITS-1:0];

      exponentOverflow = expAdjusted >
                         signed'(EXP_CALC_SIZE'(LOCAL_MAX_UNSIGNED_EXPONENT));
      exponentUnderflow = expAdjusted <
                          signed'(EXP_CALC_SIZE'(LOCAL_MIN_UNSIGNED_EXPONENT));

      // FIXME: underflow or overflow should really be based on shifting the
      // quire, the shifting functionality is really broken
    end else begin
      // There is no exponent adjustment
      exponentOverflow = 1'b0;
      exponentUnderflow = 1'b0;

      expFinal = LOCAL_UNSIGNED_EXPONENT_BITS'(LOCAL_MAX_UNSIGNED_EXPONENT + 1) -
                 LOCAL_UNSIGNED_EXPONENT_BITS'(clzQuire);
    end

    // We have overflowed if there is a high bit in the overflow range, or the
    // quire was already overflowed
    // Because there is one more negative number than positive in 2s complement,
    // it is possible that we overflowed with the largest negative number.
    // In this case, we are negative, with no bits on in the representable or
    // underflow region. This is also the case if the quire is negative and so
    // is positiveQuire

    // FIXME: this is broken for expAdjust
    overflow = overflowOrReduce ||
               in.data.isOverflow ||
               exponentOverflow ||
               (quireSign && positiveQuire[ACC_BITS-1]);

    // We have underflowed if there is no leading 1 within the representable
    // range
    // FIXME: this is broken for expAdjust
    underflow = !overflow && (~(|representableQuire) || exponentUnderflow);

    // Shift the leading 1 if any within the non-overflow bits of the quire
    // xxx1fff... => // fff...000
    alignedNonOverflowQuire = nonOverflowQuire[FIRST_REP_BIT-1:0] << clzQuire;

    out.data.isInf = in.data.isInf;
    out.data.isZero = !in.data.isInf && underflow;
    out.data.sign = in.data.isInf ?
                    1'b0 :
                    (in.data.isOverflow ?  in.data.overflowSign : quireSign);

    if (in.data.isInf || underflow) begin
      out.data.exponent = LOCAL_UNSIGNED_EXPONENT_BITS'(1'b0);
    end else if (overflow) begin
      out.data.exponent = LOCAL_UNSIGNED_EXPONENT_BITS'(LOCAL_MAX_UNSIGNED_EXPONENT);
    end else begin
      out.data.exponent = expFinal;
    end

    if (in.data.isInf || underflow || overflow) begin
      out.data.fraction = LOCAL_FRACTION_BITS'(1'b0);
    end else begin
      out.data.fraction = alignedNonOverflowQuire[FIRST_REP_BIT-:
                                                  LOCAL_FRACTION_BITS];
    end

    if (in.data.isInf || overflow) begin
      trailingBitsOut = TRAILING_BITS'(1'b0);
      stickyBitOut = 1'b0;
    end else if (underflow) begin
      // The keep bit is by definition zero, but these are still valid
      trailingBitsOut = trailingBitsUnderflow;
      stickyBitOut = stickyBitUnderflow;
    end else begin
      trailingBitsOut = trailingBitsNormal;
      stickyBitOut = stickyBitNormal;
    end
  end
endmodule
