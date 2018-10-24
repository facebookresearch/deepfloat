// Copyright (c) Facebook, Inc. and its affiliates. All Rights Reserved.
// All rights reserved.
//
// This source code is licensed under the license found in the
// LICENSE file in the root directory of this source tree.

// Performs division on arbitrary posits: out = a / b
// Fully pipelined; takes 3 + 2 * FRAC_BITS + TRAILING_BITS + STICKY_BITS cycles
// to execute
// The STICKY_BITS parameter determines how many additional digits beyond the
// TRAILING_BITS we wish to calculate for rounding purposes.
module PositDivide #(parameter WIDTH=8,
                     parameter ES=1,
                     parameter TRAILING_BITS=2,
                     parameter STICKY_BITS=1)
  (PositUnpacked.InputIf a,
   PositUnpacked.InputIf b,
   PositUnpacked.OutputIf out,
   output logic divByZero,
   output logic [TRAILING_BITS-1:0] trailingBits,
   output logic stickyBit,
   input clock,
   logic reset);

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
  localparam LOCAL_EXPONENT_BIAS = PositDef::getExponentBias(WIDTH, ES);
  localparam LOCAL_MIN_EXP = PositDef::getMinUnsignedExponent(WIDTH, ES);
  localparam LOCAL_MAX_EXP = PositDef::getMaxUnsignedExponent(WIDTH, ES);

  // We calculate the exponent a - b, but we want to determine the underflow, if
  // any.
  localparam EXP_CALC_BITS = LOCAL_UNSIGNED_EXPONENT_BITS + 2;

  // Posits always have a leading 1, so the smallest division value
  // would be:
  // 1.000... / 1.111... = 0.1...
  // which has a leading 1 behind the point
  // The largest division
  // 1.111... / 1.000... = 1.bbb...
  // so the only normalization case is aligning the result by 1 bit.
  // To ensure proper rounding, we need 1 bit for the normalization,
  // the fraction bits, TRAILING_BITS and at least 1 sticky bit.

  // [leading 1 bit]
  localparam A1 = 1;
  // [fraction bits, trailing bits, sticky bits, extra bit post-normalization]
  localparam A2 = LOCAL_FRACTION_BITS + TRAILING_BITS + STICKY_BITS + 1;

  // Takes A1 + A2 + B2 cycles
  localparam DIV_CYCLES = A1 + A2 + LOCAL_FRACTION_BITS;

  logic [A1+A2-1:0] divOutReg;
  logic divByZeroReg;

  DividerFixedPoint #(.A1(1),
                      .A2(A2),
                      .B1(1),
                      .B2(LOCAL_FRACTION_BITS),
                      .SIGNED(0))
  div(.a({1'b1, a.data.fraction, TRAILING_BITS'(1'b0), STICKY_BITS'(1'b0), 1'b0}),
      .b({~b.data.isZero, b.data.fraction}),
      .clock,
      .reset,
      .out(divOutReg),
      // FIXME: ignore this, just preserve b.isZero
      .divByZero(divByZeroReg));

  // We have to preserve some other information about the input:
  logic abSignReg;

  PipelineRegister #(.WIDTH(1), .STAGES(DIV_CYCLES))
  prSign(.in(a.data.sign ^ b.data.sign),
         .init(1'b0),
         .out(abSignReg),
         .reset,
         .clock);

  // a is inf (produces inf as output)
  logic aIsInfReg;

  PipelineRegister #(.WIDTH(1), .STAGES(DIV_CYCLES))
  prAIsInf(.in(a.data.isInf),
           .init(1'b0),
           .out(aIsInfReg),
           .reset,
           .clock);

  // b is inf (produces zero or inf as output)
  logic bIsInfReg;

  PipelineRegister #(.WIDTH(1), .STAGES(DIV_CYCLES))
  prBIsInf(.in(b.data.isInf),
           .init(1'b0),
           .out(bIsInfReg),
           .reset,
           .clock);

  // a is zero (b is a div-by-zero)
  logic aIsZeroReg;

  PipelineRegister #(.WIDTH(1), .STAGES(DIV_CYCLES))
  prAIsZero(.in(a.data.isZero),
            .init(1'b0),
            .out(aIsZeroReg),
            .reset,
            .clock);

  // divExp calculation
  logic signed [EXP_CALC_BITS-1:0] divExp;
  logic signed [EXP_CALC_BITS-1:0] divExpReg;

  PipelineRegister #(.WIDTH(EXP_CALC_BITS), .STAGES(DIV_CYCLES))
  prExp(.in(divExp),
        .init(EXP_CALC_BITS'(1'b0)),
        .out(divExpReg),
        .reset,
        .clock);

  logic signed [EXP_CALC_BITS-1:0] divExpNormalized;
  logic normRequired;
  logic underflow;
  logic overflow;

  // After division, we might need to shift the fraction by 1
  logic [A1+A2-1:0] normalizedFrac;

  // In case of underflow, we still need to produce the trailing and sticky bits
  logic [A1+A2-1:0] underflowFrac;

  logic outIsInf;
  logic outIsZero;

  always_comb begin
    // Calculated in first cycle
    divExp = signed'(EXP_CALC_BITS'(a.data.exponent)) -
             signed'(EXP_CALC_BITS'(b.data.exponent)) +
             signed'(EXP_CALC_BITS'(LOCAL_EXPONENT_BIAS));

    // If the result has a leading 0, then we need to normalize
    normRequired = ~divOutReg[1+A2-1];

    // After the division, we need to perform:
    // -post-normalization
    divExpNormalized = divExpReg - signed'(EXP_CALC_BITS'(normRequired));
    underflow = divExpNormalized < signed'(EXP_CALC_BITS'(LOCAL_MIN_EXP));
    overflow = divExpNormalized > signed'(EXP_CALC_BITS'(LOCAL_MAX_EXP));

    normalizedFrac = normRequired ?
                     {divOutReg[A1+A2-2:0], 1'b0} :
                     divOutReg;

    // For underflow, we still need to produce the trailing and sticky bits
    underflowFrac = normalizedFrac << -divExpNormalized;

    outIsInf = aIsInfReg || divByZeroReg;
    outIsZero = !outIsInf && (bIsInfReg || aIsZeroReg);
  end

  always_ff @(posedge clock) begin
    if (reset) begin
      out.data <= out.zero(1'b0);
      divByZero <= 1'b0;
      trailingBits <= TRAILING_BITS'(1'b0);
      stickyBit <= 1'b0;
    end else begin
      divByZero <= divByZeroReg;

      out.data.isInf <= outIsInf;
      out.data.sign <= !outIsInf && abSignReg;
      out.data.isZero <= !outIsInf && (outIsZero || underflow);

      // Exponent
      if (outIsInf || outIsZero || underflow) begin
        out.data.exponent <= LOCAL_UNSIGNED_EXPONENT_BITS'(1'b0);
      end else if (overflow) begin
        out.data.exponent <= LOCAL_UNSIGNED_EXPONENT_BITS'(LOCAL_MAX_EXP);
      end else begin
        // Skip leading bit
        out.data.exponent <= divExpNormalized[EXP_CALC_BITS-3:0];
      end

      // Fraction
      if (outIsInf || outIsZero || underflow || overflow) begin
        out.data.fraction <= LOCAL_FRACTION_BITS'(1'b0);
      end else begin
        out.data.fraction <= normalizedFrac[A1+A2-2-:LOCAL_FRACTION_BITS];
      end

      // Trailing and sticky bits
      if (outIsInf || outIsZero || overflow) begin
        // For overflow, we cannot round up, so there is no need to produce
        // the proper bits
        trailingBits <= TRAILING_BITS'(1'b0);
        stickyBit <= 1'b0;
      end else if (underflow) begin
        trailingBits <= underflowFrac[A1+A2-1-:TRAILING_BITS];
        stickyBit <= |underflowFrac[A1+A2-1-TRAILING_BITS:0];
      end else begin
        trailingBits <= normalizedFrac[A1+A2-2-LOCAL_FRACTION_BITS-:TRAILING_BITS];
        stickyBit <= |normalizedFrac[A1+A2-2-LOCAL_FRACTION_BITS-TRAILING_BITS:0];
      end
    end
  end
endmodule
