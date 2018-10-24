// Copyright (c) Facebook, Inc. and its affiliates. All Rights Reserved.
// All rights reserved.
//
// This source code is licensed under the license found in the
// LICENSE file in the root directory of this source tree.

// Narrows a signed float to one of a smaller type
module FloatSignedNarrow #(parameter IN_FRAC=10,
                           parameter OUT_FRAC=8,
                           parameter EXP=8,
                           parameter TRAILING_BITS=2)
  (FloatSigned.InputIf in,
   input [TRAILING_BITS-1:0] inTrailingBits,
   input inStickyBit,
   FloatSigned.OutputIf out,
   output logic [TRAILING_BITS-1:0] outTrailingBits,
   output logic outStickyBit);

  initial begin
    assert(in.FRAC == IN_FRAC);
    assert(in.EXP == EXP);
    assert(out.FRAC == OUT_FRAC);
    assert(out.EXP == EXP);
  end

  logic [IN_FRAC+TRAILING_BITS-1:0] inFrac;
  logic [OUT_FRAC-1:0] outFrac;
  logic outSticky;

  TrailingStickySelect #(.IN_WIDTH(IN_FRAC+TRAILING_BITS),
                         .FRAC(OUT_FRAC),
                         .TRAILING_BITS(TRAILING_BITS))
  tss(.in(inFrac),
      .frac(outFrac),
      .trailingBits(outTrailingBits),
      .stickyBit(outSticky));

  always_comb begin
    inFrac = {in.data.frac, inTrailingBits};
    outStickyBit = outSticky | inStickyBit;

    out.data.sign = in.data.sign;
    out.data.isInf = in.data.isInf;
    out.data.isZero = in.data.isZero;
    out.data.exp = in.data.exp;
    out.data.frac = outFrac;
  end
endmodule
