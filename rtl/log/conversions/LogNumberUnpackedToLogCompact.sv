// Copyright (c) Facebook, Inc. and its affiliates. All Rights Reserved.
// All rights reserved.
//
// This source code is licensed under the license found in the
// LICENSE file in the root directory of this source tree.

module LogNumberUnpackedToLogCompact #(parameter WIDTH=8,
                                       parameter LS=1)
  (LogNumberUnpacked.InputIf in,
   input [1:0] trailingBits,
   input stickyBit,
   LogNumberCompact.OutputIf out);

  localparam M = PositDef::getSignedExponentBits(WIDTH, LS);

  localparam POSIT_EXP_BITS = PositDef::getUnsignedExponentBits(WIDTH, LS);
  localparam POSIT_FRAC_BITS = PositDef::getFractionBits(WIDTH, LS);

  initial begin
    assert(in.M == PositDef::getSignedExponentBits(WIDTH, LS));
    assert(in.F == PositDef::getFractionBits(WIDTH, LS));

    assert(out.WIDTH == WIDTH);
    assert(out.LS == LS);

    assert(-(2 ** (M - 1)) <= PositDef::getMinSignedExponent(WIDTH, LS));
  end

  PositUnpacked #(.WIDTH(WIDTH), .ES(LS)) preRound();
  PositUnpacked #(.WIDTH(WIDTH), .ES(LS)) postRound();

  PositRoundToNearestEven #(.WIDTH(WIDTH),
                            .ES(LS))
  pr2ne(.in(preRound),
        .trailingBits(trailingBits),
        .stickyBit(stickyBit),
        .out(postRound));

  PositPacked #(.WIDTH(WIDTH), .ES(LS)) postPack();

  PositEncode #(.WIDTH(WIDTH),
                .ES(LS))
  penc(.in(postRound),
       .out(postPack));

  // The compact representation has a fixed minimum exponent; we need to handle
  // underflow before rounding ourselves. Overflow will be handled by the posit
  // round representation
  logic [PositDef::getUnsignedExponentBits(WIDTH, LS)-1:0] inPositExp;
  logic underflow;

  always_comb begin
    underflow = in.data.signedLogExp <
                signed'(M'(PositDef::getMinSignedExponent(WIDTH, LS)));

    preRound.data.sign = in.data.sign;

    if (in.data.isZero || in.data.isInf) begin
      preRound.data.isZero = in.data.isZero;
      preRound.data.isInf = in.data.isInf;
      preRound.data.exponent = POSIT_EXP_BITS'(1'b0);
      preRound.data.fraction = POSIT_FRAC_BITS'(1'b0);
    end else begin
      preRound.data.isInf = 1'b0;

      if (underflow) begin
        // We needn't bother with additional trailing/sticky bits in underflow,
        // since these will never be used in the posit representation
        preRound.data.exponent = POSIT_EXP_BITS'(1'b0);
        preRound.data.fraction = POSIT_FRAC_BITS'(1'b0);
        preRound.data.isZero = 1'b1;
      end else begin
        preRound.data.exponent = unsigned'(in.data.signedLogExp +
                                           PositDef::getExponentBias(WIDTH, LS));
        preRound.data.fraction = in.data.logFrac;
        preRound.data.isZero = 1'b0;
      end
    end

    out.data.bits = postPack.data.bits;
  end
endmodule
