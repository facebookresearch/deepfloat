// Copyright (c) Facebook, Inc. and its affiliates. All Rights Reserved.
// All rights reserved.
//
// This source code is licensed under the license found in the
// LICENSE file in the root directory of this source tree.

// FIXME: no denormal handling
// FIXME: doesn't handle over/underflow, rounding
module FloatSignedToFloat #(parameter EXP=8,
                            parameter FRAC=23,
                            parameter SIGNED_EXP=3,
                            parameter SIGNED_FRAC=8)
  (FloatSigned.InputIf in,
   Float.OutputIf out);

  initial begin
    assert(in.EXP == SIGNED_EXP);
    assert(in.FRAC == SIGNED_FRAC);

    assert(out.EXP == EXP);
    assert(out.FRAC == FRAC);

    assert(SIGNED_EXP <= EXP);
    assert(SIGNED_FRAC <= FRAC);
  end

  // Pad the output with 0s
  logic [FRAC-1:0] outFrac;

  PartSelect #(.IN_WIDTH(SIGNED_FRAC),
               .START_IDX(SIGNED_FRAC-1),
               .OUT_WIDTH(FRAC))
  ps(.in(in.data.frac),
     .out(outFrac));

  always_comb begin
    if (in.data.isInf) begin
      out.data = out.getInf(1'b0);
    end else if (in.data.isZero) begin
      out.data = out.getZero(1'b0);
    end else begin
      out.data.sign = in.data.sign;
      out.data.exponent = unsigned'(EXP'(in.data.exp)) + EXP'(FloatDef::getExpBias(EXP, FRAC));
      out.data.fraction = outFrac;
    end
  end
endmodule
