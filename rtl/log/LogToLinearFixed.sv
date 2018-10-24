// Copyright (c) Facebook, Inc. and its affiliates. All Rights Reserved.
// All rights reserved.
//
// This source code is licensed under the license found in the
// LICENSE file in the root directory of this source tree.


// converts a log number -> linear fixed-point number
module LogToLinearFixed #(parameter M=5,
                          parameter F=10,
                          parameter LOG_TO_LINEAR_BITS=8,
                          parameter ACC_NON_FRAC=16,
                          parameter ACC_FRAC=16)
  (LogNumberUnpacked.InputIf in,
   Kulisch.OutputIf out);

  initial begin
    assert(in.M == M);
    assert(in.F == F);
    assert(out.ACC_NON_FRAC == ACC_NON_FRAC);
    assert(out.ACC_FRAC == ACC_FRAC);
  end

  FloatSigned #(.EXP(M), .FRAC(LOG_TO_LINEAR_BITS)) floatSigned();

  LogNumberUnpackedToFloatSigned #(.M(M),
                                   .F(F),
                                   .LOG_TO_LINEAR_BITS(LOG_TO_LINEAR_BITS))
  l2lf(.in(in),
       .out(floatSigned));

  FloatSignedToLinearFixed #(.SIGNED_EXP(M),
                             .FRAC(LOG_TO_LINEAR_BITS),
                             .ACC_NON_FRAC(ACC_NON_FRAC),
                             .ACC_FRAC(ACC_FRAC))
  lf2f(.in(floatSigned),
       .out(out));
endmodule
