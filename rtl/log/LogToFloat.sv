// Copyright (c) Facebook, Inc. and its affiliates. All Rights Reserved.
// All rights reserved.
//
// This source code is licensed under the license found in the
// LICENSE file in the root directory of this source tree.

module LogToFloat #(parameter M=3,
                    parameter F=4,
                    parameter LOG_TO_LINEAR_BITS=8,
                    parameter EXP=8,
                    parameter FRAC=23)
  (LogNumberUnpacked.InputIf in,
   Float.OutputIf out);

  initial begin
    assert(in.M == M);
    assert(in.F == F);
    assert(out.EXP == EXP);
    assert(out.FRAC == FRAC);
  end

  FloatSigned #(.EXP(M), .FRAC(LOG_TO_LINEAR_BITS)) floatSigned();

  LogNumberUnpackedToFloatSigned #(.M(M),
                                   .F(F),
                                   .LOG_TO_LINEAR_BITS(LOG_TO_LINEAR_BITS))
  l2lf(.in(in),
       .out(floatSigned));

  FloatSignedToFloat #(.SIGNED_EXP(M),
                       .SIGNED_FRAC(LOG_TO_LINEAR_BITS),
                       .EXP(EXP),
                       .FRAC(FRAC))
  lf2f(.in(floatSigned),
       .out(out));
endmodule
