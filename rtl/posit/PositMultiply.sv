// Copyright (c) Facebook, Inc. and its affiliates. All Rights Reserved.
// All rights reserved.
//
// This source code is licensed under the license found in the
// LICENSE file in the root directory of this source tree.

module PositMultiply #(parameter WIDTH=8,
                       parameter ES=1,
                       parameter TRAILING_BITS=2)
  (PositUnpacked.InputIf a,
   PositUnpacked.InputIf b,
   PositUnpacked.OutputIf out,
   output logic [TRAILING_BITS-1:0] trailingBits,
   output logic stickyBit);

  initial begin
    assert(a.WIDTH == b.WIDTH);
    assert(a.WIDTH == out.WIDTH);
    assert(a.WIDTH == WIDTH);
    assert(a.ES == b.ES);
    assert(a.ES == out.ES);
    assert(a.ES == ES);
  end

  // Quartus doesn't support parameterized class typedefs
  localparam LOCAL_FRACTION_BITS = PositDef::getFractionBits(WIDTH, ES);
  localparam LOCAL_UNSIGNED_EXPONENT_BITS = PositDef::getUnsignedExponentBits(WIDTH, ES);
  localparam LOCAL_MAX_UNSIGNED_EXPONENT = PositDef::getMaxUnsignedExponent(WIDTH, ES);
  localparam LOCAL_EXPONENT_BIAS = PositDef::getExponentBias(WIDTH, ES);

  // Number of bits for the exponent bias
  localparam EXP_BIAS_BITS = $clog2(LOCAL_EXPONENT_BIAS);

  // Size of the product a * b
  localparam EXP_PRODUCT_BITS = LOCAL_UNSIGNED_EXPONENT_BITS + 1;
  localparam FRAC_PRODUCT_BITS = (LOCAL_FRACTION_BITS + 1) * 2;

  logic abSign;

  logic [EXP_PRODUCT_BITS-1:0] abExp;
  logic abExpTooSmall;
  logic abExpTooBig;
  logic abExpShift;

  logic [EXP_PRODUCT_BITS-1:0] finalExpExtended;
  logic [LOCAL_UNSIGNED_EXPONENT_BITS-1:0] finalExp;

  // The product in the form 1x.bbbb or 01.bbbb; it is known to be one form or
  // another because there are no denormals
  logic [FRAC_PRODUCT_BITS-1:0] abUnshiftedProduct;

  // The product in the form 1.bbbb
  logic [FRAC_PRODUCT_BITS-1:0] abShiftedProduct;

  // Amount of underflow for shifting purposes
  logic [EXP_BIAS_BITS-1:0] underflowShift;

  // Shifted product in case of underflow
  logic [TRAILING_BITS+1-1:0] underflowProduct;

  // Sticky bit produced in case of underflow
  logic underflowSticky;

  // Trailing and sticky bits produced in case of normal range results
  logic [TRAILING_BITS-1:0] normalTrailingBits;
  logic normalStickyBit;

  ShiftRightSticky #(.IN_WIDTH(FRAC_PRODUCT_BITS),
                     .OUT_WIDTH(TRAILING_BITS+1),
                     .SHIFT_VAL_WIDTH(EXP_BIAS_BITS))
  srs(.in(abShiftedProduct),
      .shift(underflowShift),
      .out(underflowProduct),
      .sticky(underflowSticky),
      .stickyAnd());

  ZeroPadRight #(.IN_WIDTH(FRAC_PRODUCT_BITS-2-LOCAL_FRACTION_BITS),
                 .OUT_WIDTH(TRAILING_BITS))
  zpr(.in(abShiftedProduct[FRAC_PRODUCT_BITS-2-LOCAL_FRACTION_BITS-1:0]),
      .out(normalTrailingBits));

  always_comb begin
    abSign = a.data.sign ^ b.data.sign;

    // FIXME: handle posit sign / fraction encoding (2s complement)?
    // Posits always have a leading 1
    abUnshiftedProduct = {1'b1, a.data.fraction} * {1'b1, b.data.fraction};

    // The product result may be of the form 01.bbbb, or 1b.bbbb. In the latter
    // case, our exponent is adjusted by 1.
    abExpShift = abUnshiftedProduct[FRAC_PRODUCT_BITS-1];

    // FIXME: case where we are right at the limit, and the +1 from abExpShift
    // causes an overflow? This might not be possible though except for some
    // very specific (N, es) choices.
    abExp = EXP_PRODUCT_BITS'(a.data.exponent) + EXP_PRODUCT_BITS'(b.data.exponent) +
            EXP_PRODUCT_BITS'(abExpShift);

    // This is the product with the exponent abExp, which takes into account the
    // shift needed for the location of the leading one.
    // It is thus in the form 1.bbbb, with only a single leading digit
    abShiftedProduct = abExpShift ?
                       // reinterpret 1b.bbbb -> 1.bbbbb
                       abUnshiftedProduct :
                       // 01.bbbb -> 1.bbbb0
                       {abUnshiftedProduct[FRAC_PRODUCT_BITS-2:0], 1'b0};

    // (a_unsigned - bias) + (b_unsigned - bias) >= min signed (-bias)
    // a_u + b_u >= bias
    abExpTooSmall = abExp < EXP_PRODUCT_BITS'(LOCAL_EXPONENT_BIAS);
    // Highest representable exponent is 2 * bias + MAX_UNSIGNED_EXPONENT
    abExpTooBig =
      abExp > EXP_PRODUCT_BITS'(LOCAL_EXPONENT_BIAS +
                                LOCAL_MAX_UNSIGNED_EXPONENT);
    finalExpExtended = abExp - EXP_PRODUCT_BITS'(LOCAL_EXPONENT_BIAS);
    finalExp = finalExpExtended[LOCAL_UNSIGNED_EXPONENT_BITS-1:0];

    // For abExpTooSmall, we need to shift right by (bias - abExp) to determine
    // the trailing and sticky bits.
    // This is only used in the case abExp < bias, so it can be narrower
    underflowShift = EXP_BIAS_BITS'(LOCAL_EXPONENT_BIAS) -
                     abExp[EXP_BIAS_BITS-1:0];

    out.data.isInf = a.data.isInf || b.data.isInf;
    out.data.sign = !out.data.isInf && abSign;
    out.data.isZero = !out.data.isInf && (a.data.isZero || b.data.isZero || abExpTooSmall);

    out.data.exponent = out.data.isInf || out.data.isZero ?
                        LOCAL_UNSIGNED_EXPONENT_BITS'(1'b0) :
                        (abExpTooBig ?
                         LOCAL_UNSIGNED_EXPONENT_BITS'(LOCAL_MAX_UNSIGNED_EXPONENT) :
                         finalExp);

    out.data.fraction = out.data.isInf || out.data.isZero || abExpTooBig ?
                        LOCAL_FRACTION_BITS'(1'b0) :
                        abShiftedProduct[FRAC_PRODUCT_BITS-2-:LOCAL_FRACTION_BITS];

    trailingBits = out.data.isInf || (a.data.isZero || b.data.isZero) || abExpTooBig ?
                   TRAILING_BITS'(1'b0) :
                   (abExpTooSmall ? underflowProduct[TRAILING_BITS-1:0] : normalTrailingBits);

    stickyBit = out.data.isInf || (a.data.isZero || b.data.isZero) || abExpTooBig ?
                1'b0 :
                (abExpTooSmall ? underflowSticky : normalStickyBit);
  end

  generate
    if (FRAC_PRODUCT_BITS-2-LOCAL_FRACTION_BITS-TRAILING_BITS >= 1) begin
      assign normalStickyBit = |abShiftedProduct[FRAC_PRODUCT_BITS-2-
                                                 LOCAL_FRACTION_BITS-TRAILING_BITS-1:0];
    end else begin
       assign normalStickyBit = 1'b0;
    end
  endgenerate
endmodule
