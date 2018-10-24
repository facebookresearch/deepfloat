// Copyright (c) Facebook, Inc. and its affiliates. All Rights Reserved.
// All rights reserved.
//
// This source code is licensed under the license found in the
// LICENSE file in the root directory of this source tree.

// We don't preserve NaN signs, or care about signalling / non-signalling NaNs.
// All NaNs are +nan with the MSB of the fraction field set to 1, all other 0.
// FIXME: make denormal handling optional
// FIXME: make sticky bit calculation optional
module FloatMultiplyImpl #(parameter EXP_IN=8,
                           // Allows for capturing results in the otherwise
                           // denormal/zero and inf range when expanding to
                           // higher precision
                           parameter EXP_OUT=8,
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

   Float.OutputIf out,
   // Trailing bits for rounding or extra precision purposes from the
   // multiplication
   output logic [TRAILING_BITS-1:0] trailingBitsOut,
   output logic stickyBitOut,

   // We provide these as a convenience for any consumers
   output logic isNanOut,

   input reset,
   input clock);

  initial begin
    assert(inA.EXP == EXP_IN);
    assert(inB.EXP == EXP_IN);
    assert(inA.FRAC == FRAC);
    assert(inB.FRAC == FRAC);

    assert(out.EXP == EXP_OUT);
    assert(out.FRAC == FRAC);
  end

  // Maximum non-inf input exponent is 2^exp - 2
  // Maximum non-inf sum is 2^(exp + 1) - 4
  localparam EXP_MATH_IN_BITS = $clog2(2 ** (EXP_IN + 1) - 4);
  localparam EXP_MATH_OUT_BITS = $clog2(2 ** (EXP_OUT + 1) - 4);

  localparam EXP_BIAS_DIFFERENCE = FloatDef::getExpBias(EXP_OUT, FRAC) -
                                   FloatDef::getExpBias(EXP_IN, FRAC);

  localparam EXP_SUM_MAX_DENORMAL_VAL = (2 ** (EXP_OUT - 1)) - 3;
  localparam EXP_SUM_OFFSET = (2 ** (EXP_OUT - 1)) - 2;

  localparam FRAC_PRODUCT_WIDTH = (FRAC + 1) * 2;

  initial begin
    assert(TRAILING_BITS <= FRAC);
    assert(EXP_OUT >= EXP_IN);
    assert(TRAILING_BITS + 1 <= FRAC);
  end

  //
  // Combinational logic
  //

  // cycle 1
  logic anyIsZero;
  logic anyIsInf;
  logic outIsNan;

  logic [EXP_MATH_IN_BITS-1:0] expSum;
  logic [EXP_MATH_OUT_BITS-1:0] expSumInOutRange;
  logic expSumInNormalRange;

  // cycle 2
  logic expLargerThanShift;
  logic [EXP_OUT-1:0] renormalizedOutputExp;
  logic [FRAC_PRODUCT_WIDTH-1:0] fracDenormalCorrected;
  logic [$clog2(FRAC)-1:0] productClz;
  logic overflow;

  // cycle 3
  logic [FRAC_PRODUCT_WIDTH-1:0] fracOut;

  //
  // Registers
  //

  // cycle 1

  logic outSign_D_1;
  logic anyIsZero_D_1;
  logic anyIsInf_D_1;
  logic outIsNan_D_1;

  logic [EXP_MATH_OUT_BITS-1:0] expSumInOutRange_D_1;
  logic expSumInNormalRange_D_1;
  // FIXME: can be EXP if we filter out infinity as input
  logic [EXP_OUT+1-1:0] expPlus1_D_1;
  logic [FRAC_PRODUCT_WIDTH-1:0] fracProduct_D_1;

  // cycle 2

  logic outSign_D_2;
  logic outIsZero_D_2;
  logic outIsInf_D_2;
  logic outIsNan_D_2;

  logic [EXP_OUT-1:0] renormalizedOutputExp_D_2;
  logic [EXP_OUT-1:0] outExp_D_2;
  logic [FRAC_PRODUCT_WIDTH-1:0] fracRenormalized_D_2;

  //
  // Sub-modules
  //

  CountLeadingZeros #(.WIDTH(FRAC))
  clz(.in(fracProduct_D_1[(FRAC_PRODUCT_WIDTH-1)-:FRAC]),
      .out(productClz));

  //
  // Combinational logic
  //

  always_comb begin
    //
    // cycle 1
    //

    // NaN / inf logic
    anyIsZero = isZeroA || isZeroB;
    anyIsInf = isInfA || isInfB;

    // The result is NaN if any inputs are NaN, or one input is inf and the
    // other is zero
    outIsNan = isNanA || isNanB || (anyIsZero && anyIsInf);

    // This is the exponent of the output, in the form (real exp + 2 * bias)
    expSum = EXP_MATH_IN_BITS'(inA.data.exponent) +
             EXP_MATH_IN_BITS'(inB.data.exponent) +
             isDenormalA + isDenormalB;

    // This is the value of expSum relative to the bias in the output exponent
    // 2 * new bias - 2 * old bias
    expSumInOutRange = EXP_MATH_OUT_BITS'(expSum) +
                       EXP_MATH_OUT_BITS'(2 * EXP_BIAS_DIFFERENCE);

    // Whether or not the above is out of the denormal range
    expSumInNormalRange = expSumInOutRange >
                          EXP_MATH_OUT_BITS'(EXP_SUM_MAX_DENORMAL_VAL);

    //
    // cycle 2
    //

    expLargerThanShift = expPlus1_D_1 > productClz;

    // This is the exponent after renormalization, upon which we can
    // become denormal again
    renormalizedOutputExp = expLargerThanShift ?
                            (expPlus1_D_1 - productClz) : {EXP_OUT{1'b0}};

    fracDenormalCorrected = expSumInNormalRange_D_1 ? fracProduct_D_1 :
                            (fracProduct_D_1 >> (EXP_SUM_OFFSET - expSumInOutRange_D_1));

    // Did we overflow the multiplication?
    overflow = expPlus1_D_1 > {1'b0, {EXP_OUT{1'b1}}};

    //
    // cycle 3
    //

    // If we are denormal, shift back
    fracOut = renormalizedOutputExp_D_2 == 0 ?
              {1'b0, fracRenormalized_D_2[FRAC_PRODUCT_WIDTH-1:1]} :
              fracRenormalized_D_2;
  end

  always_ff @(posedge clock) begin
    if (reset) begin
      outSign_D_1 <= 0;
      anyIsZero_D_1 <= 0;
      anyIsInf_D_1 <= 0;
      outIsNan_D_1 <= 0;

      expSumInOutRange_D_1 <= 0;
      expSumInNormalRange_D_1 <= 0;
      expPlus1_D_1 <= 0;
      fracProduct_D_1 <= 0;

      outSign_D_2 <= 0;
      outIsZero_D_2 <= 0;
      outIsInf_D_2 <= 0;
      outIsNan_D_2 <= 0;

      renormalizedOutputExp_D_2 <= 0;
      outExp_D_2 <= 0;
      fracRenormalized_D_2 <= 0;

      out.data <= out.getZero(1'b0);
      trailingBitsOut <= 0;
      stickyBitOut <= 0;
      isNanOut <= 0;
    end else begin
      //
      // cycle 1
      //

      // Sign
      outSign_D_1 <= inA.data.sign ^ inB.data.sign;

      anyIsZero_D_1 <= anyIsZero;
      anyIsInf_D_1 <= anyIsInf;
      outIsNan_D_1 <= outIsNan;

      // This is the exponent of the output, in the form (real exp + 2 * bias)
      expSumInOutRange_D_1 <= expSum;

      expSumInNormalRange_D_1 <= expSumInNormalRange;

      // If we will be denormal, our exponent will be 0.
      // Otherwise, subtract (bias - 1) to form (real exp + bias + 1)
      expPlus1_D_1 <= expSumInNormalRange ?
                      expSumInOutRange - EXP_SUM_OFFSET : {$bits(expPlus1_D_1){1'b0}};

      // The basic product with leading 1 (or 0 for denormals)
      fracProduct_D_1 <= {!isDenormalA, inA.data.fraction} *
                         {!isDenormalB, inB.data.fraction};

      //
      // cycle 2
      //

      outSign_D_2 <= outSign_D_1;

      outIsZero_D_2 <= anyIsZero_D_1;
      outIsInf_D_2 <= anyIsInf_D_1 || (!anyIsZero_D_1 && overflow);
      outIsNan_D_2 <= outIsNan_D_1;

      // This is the exponent after renormalization, upon which we can
      // become denormal again
      renormalizedOutputExp_D_2 <= renormalizedOutputExp;

      // Check for overflow
      outExp_D_2 <= (overflow ? {EXP_OUT{1'b1}} : renormalizedOutputExp);

      // Renormalize the product for a leading 1
      fracRenormalized_D_2 <= (fracDenormalCorrected <<
                               (expLargerThanShift ? productClz : expPlus1_D_1));

      //
      // cycle 3
      //

      out.data.sign <= outSign_D_2;
      out.data.exponent <= (outIsInf_D_2 || outIsNan_D_2 || outIsZero_D_2) ?
                      {EXP_OUT{(outIsInf_D_2 || outIsNan_D_2)}} : outExp_D_2;

      if (outIsInf_D_2 || outIsZero_D_2 || outIsNan_D_2) begin
        out.data.fraction <= {outIsNan_D_2, {(FRAC-1){1'b0}}};
      end else begin
        // fpw - 2 to fpw - 2 - (frac - 1)
        out.data.fraction <= fracOut[(FRAC_PRODUCT_WIDTH-2):
                                     (FRAC_PRODUCT_WIDTH-2)-(FRAC-1)];
      end


      // fpw - 2 - frac to fpw - 2 - frac - (tb - 1)
      trailingBitsOut <= fracOut[(FRAC_PRODUCT_WIDTH-2)-FRAC:
                                 (FRAC_PRODUCT_WIDTH-2)-FRAC-(TRAILING_BITS-1)];

      // fpw - 2 - frac - tb to 0
      // FIXME?
      // stickyBitOut <= |fracOut[FRAC_PRODUCT_WIDTH-2-FRAC-TRAILING_BITS+1:0];
      stickyBitOut <= |fracOut[FRAC_PRODUCT_WIDTH-2-FRAC-TRAILING_BITS:0];

      isNanOut <= outIsNan_D_2;
    end
  end
endmodule

module FloatMultiply #(parameter EXP_IN_A=8,
                       parameter FRAC_IN_A=23,
                       parameter EXP_IN_B=8,
                       parameter FRAC_IN_B=23,
                       parameter EXP_OUT=8,
                       parameter FRAC_OUT=23,
                       parameter TRAILING_BITS=2)
  (Float.InputIf inA,
   Float.InputIf inB,
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
    assert(out.EXP == EXP_OUT);
    assert(out.FRAC == FRAC_OUT);

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

  FloatMultiplyImpl #(.EXP_IN(EXP_OUT),
                      .EXP_OUT(EXP_OUT), // FIXME: do we want this option?
                      .FRAC(FRAC_OUT),
                      .TRAILING_BITS(TRAILING_BITS))
  mult(.inA(inAExpand),
       .isInfA,
       .isNanA,
       .isZeroA,
       .isDenormalA,
       .inB(inBExpand),
       .isInfB,
       .isNanB,
       .isZeroB,
       .isDenormalB,
       .out,
       .trailingBitsOut(trailingBits),
       .stickyBitOut(stickyBit),
       .isNanOut(isNan),
       .reset,
       .clock);
endmodule
