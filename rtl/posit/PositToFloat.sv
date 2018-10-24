// Copyright (c) Facebook, Inc. and its affiliates. All Rights Reserved.
// All rights reserved.
//
// This source code is licensed under the license found in the
// LICENSE file in the root directory of this source tree.

module PositToFloat #(parameter POSIT_WIDTH=8,
                      parameter POSIT_ES=1,
                      parameter FLOAT_EXP=8,
                      parameter FLOAT_FRAC=23,
                      parameter TRAILING_BITS=2,
                      parameter EXP_ADJUST_BITS=1,
                      parameter EXP_ADJUST=0,
                      parameter SATURATE_TO_MAX_FLOAT=0)
  (PositUnpacked.InputIf in,
   input logic signed [EXP_ADJUST_BITS-1:0] expAdjust,
   Float.OutputIf out,
   output logic [TRAILING_BITS-1:0] trailingBitsOut,
   output logic stickyBitOut);

  initial begin
    assert(in.WIDTH == POSIT_WIDTH);
    assert(in.ES == POSIT_ES);
    assert(out.EXP == FLOAT_EXP);
    assert(out.FRAC == FLOAT_FRAC);
  end

  localparam LOCAL_POSIT_EXP_BIAS = PositDef::getExponentBias(POSIT_WIDTH,
                                                              POSIT_ES);
  localparam LOCAL_POSIT_FRACTION_BITS = PositDef::getFractionBits(POSIT_WIDTH,
                                                                   POSIT_ES);

  // Determine the smallest float that can fully encode the posit
  localparam POSIT_AS_FLOAT_EXP_BITS = PositDef::getUnsignedExponentBits(POSIT_WIDTH,
                                                                         POSIT_ES) + 1;

  // There are four cases for converting posit -> float:
  //
  // 1. pexp <= fexp, pfrac <= ffrac
  // 2. pexp > fexp, pfrac > ffrac
  // 3. pexp > fexp, pfrac <= ffrac
  // 4. pexp <= fexp, pfrac > ffrac
  //
  // In all cases, we expand to the larger of the two, such that all cases are
  // contraction.

  // Always expand to the larger of the two exponent representations. If there
  // is an exponent adjustment involved, add a bit.
  // FIXME: really the number of bits added should be based on the max/min value
  // of the exponent plus the max/min value of expAdjust
  localparam EXPAND_EXP_BITS = Functions::getMax(POSIT_AS_FLOAT_EXP_BITS, FLOAT_EXP) +
                               (EXP_ADJUST ? 1 : 0);

  // Always expand to the larger of the two fraction representations
  localparam EXPAND_FRAC_BITS = Functions::getMax(LOCAL_POSIT_FRACTION_BITS, FLOAT_FRAC);

  logic [EXPAND_EXP_BITS-1:0] expandUnsignedExp;
  logic [EXPAND_FRAC_BITS-1:0] expandFrac;

  Float #(.EXP(EXPAND_EXP_BITS), .FRAC(EXPAND_FRAC_BITS)) expandFloat();

  localparam USE_POSIT_EXP_BIAS = FloatDef::getExpBias(EXPAND_EXP_BITS,
                                                       EXPAND_FRAC_BITS);

  initial begin
    assert(USE_POSIT_EXP_BIAS >= LOCAL_POSIT_EXP_BIAS);
  end

  ZeroPadRight #(.IN_WIDTH(LOCAL_POSIT_FRACTION_BITS),
                 .OUT_WIDTH(EXPAND_FRAC_BITS))
  zpr(.in(in.data.fraction),
      .out(expandFrac));

  always_comb begin
    if (EXP_ADJUST) begin
      // FIXME: this isn't quite correct, need to be concerned about exponent
      // underflow. For cases where the posit is much smaller than the float,
      // this doesn't matter though.
      expandUnsignedExp = EXPAND_EXP_BITS'(in.data.exponent)
        + EXPAND_EXP_BITS'(USE_POSIT_EXP_BIAS - LOCAL_POSIT_EXP_BIAS)
          - EXPAND_EXP_BITS'(expAdjust);
    end else begin
      expandUnsignedExp = EXPAND_EXP_BITS'(in.data.exponent)
        + EXPAND_EXP_BITS'(USE_POSIT_EXP_BIAS - LOCAL_POSIT_EXP_BIAS);
    end

    unique if (in.data.isInf) begin
      expandFloat.data.sign = 1'b0;
      expandFloat.data.exponent = {EXPAND_EXP_BITS{1'b1}};
      expandFloat.data.fraction = EXPAND_FRAC_BITS'(1'b0);
    end else if (in.data.isZero) begin
      expandFloat.data.sign = in.data.sign;
      expandFloat.data.exponent = EXPAND_EXP_BITS'(1'b0);
      expandFloat.data.fraction = EXPAND_FRAC_BITS'(1'b0);
    end else begin
      expandFloat.data.sign = in.data.sign;
      expandFloat.data.exponent = expandUnsignedExp;
      expandFloat.data.fraction = expandFrac;
    end
  end

  // All cases are contract
  FloatContract #(.EXP_IN(EXPAND_EXP_BITS),
                  .FRAC_IN(EXPAND_FRAC_BITS),
                  .EXP_OUT(FLOAT_EXP),
                  .FRAC_OUT(FLOAT_FRAC),
                  .TRAILING_BITS(TRAILING_BITS),
                  .SATURATE_TO_MAX_FLOAT(SATURATE_TO_MAX_FLOAT))
  contract(.in(expandFloat),
           .out(out),
           .trailingBitsOut(trailingBitsOut),
           .stickyBitOut(stickyBitOut),
           .isNanOut());
endmodule
