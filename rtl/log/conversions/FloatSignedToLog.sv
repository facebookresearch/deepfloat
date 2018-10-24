// Copyright (c) Facebook, Inc. and its affiliates. All Rights Reserved.
// All rights reserved.
//
// This source code is licensed under the license found in the
// LICENSE file in the root directory of this source tree.

// The input linear value is already rounded appropriately
module FloatSignedToLog #(// linear parameters
                          parameter EXP_IN=10,
                          parameter FRAC_IN=10,
                          // log parameters
                          parameter M=3,
                          parameter F=4,
                          parameter SATURATE_MAX=1)
  (FloatSigned.InputIf in,
   LogNumberUnpacked.OutputIf out);

  initial begin
    assert(in.EXP == EXP_IN);
    assert(in.FRAC == FRAC_IN);

    assert(out.M == M);
    assert(out.F == F);
  end

  // The maximum exponent based on the larger of the two inputs
  localparam MAX_EXP_BITS = EXP_IN > M ? EXP_IN : M;

  // Mapping the linear fraction to a log fraction

  // (exp round bit)(log2Fraction)
  logic [F:0] log2LutOut;

  // Whether or not we wish to round up the exponent based on the log rounding
  logic logExpRound;

  // The log fractional part
  logic [F-1:0] log2Fraction;

  // Performs the linear -> log mapping
  Log2Map #(.IN(FRAC_IN),
            .OUT(F))
  log2(.in(in.data.frac),
       .out(log2LutOut));

  // The exponent with the linear -> log conversion rounding
  logic signed [EXP_IN-1:0] logSignedExpRounded;

  logic overflow;
  logic underflow;

  // Final exponent
  logic signed [M-1:0] finalExp;

  always_comb begin
    logExpRound = log2LutOut[F];
    log2Fraction = log2LutOut[F-1:0];

    logSignedExpRounded = in.data.exp + logExpRound;

    // FIXME: if EXP_IN == M, this isn't performed correctly
    overflow = logSignedExpRounded >= signed'(MAX_EXP_BITS'(2 ** (M - 1)));
    underflow = logSignedExpRounded < -signed'(MAX_EXP_BITS'(2 ** (M - 1)));

    finalExp = M'(logSignedExpRounded);

    // $display("expbits %p funround %b fround %b expSigned %p ovf %b unf %b",
    //          MAX_EXP_BITS,
    //          fractionUnrounded,
    //          fractionRounded,
    //          expSigned,
    //          overflow,
    //          underflow);

    if (in.data.isInf || (!SATURATE_MAX && overflow)) begin
      out.data = out.inf();
    end else if (in.data.isZero || underflow) begin
      out.data = out.zero();
    end else if ((SATURATE_MAX && overflow)) begin
      out.data = out.getMax(in.data.sign);
    end else begin
      out.data.sign = in.data.sign;
      out.data.isInf = 1'b0;
      out.data.isZero = 1'b0;
      out.data.signedLogExp = finalExp;
      out.data.logFrac = log2Fraction;
    end
  end
endmodule
