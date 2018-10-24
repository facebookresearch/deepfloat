// Copyright (c) Facebook, Inc. and its affiliates. All Rights Reserved.
// All rights reserved.
//
// This source code is licensed under the license found in the
// LICENSE file in the root directory of this source tree.

module PaperLogPE #(parameter M=5,
                    parameter F=10,
                    parameter ACC_FRAC=20,
                    parameter ACC_NON_FRAC=11,
                    parameter OVERFLOW_DETECTION=0,
                    parameter NON_FRAC_REDUCE=0,
                    parameter LOG_TO_LINEAR_BITS=8)
   (LogNumberUnpacked.InputIf aIn,
    LogNumberUnpacked.InputIf bIn,
    Kulisch.InputIf cIn,
    Kulisch.OutputIf cOut);

  initial begin
    assert(aIn.M == M);
    assert(aIn.F == F);
    assert(bIn.M == M);
    assert(bIn.F == F);

    assert(cIn.ACC_NON_FRAC == ACC_NON_FRAC);
    assert(cIn.ACC_FRAC == ACC_FRAC);
    assert(cOut.ACC_NON_FRAC == ACC_NON_FRAC);
    assert(cOut.ACC_FRAC == ACC_FRAC);
  end

  LogMultiplyAdd #(.M(M),
                   .F(F),
                   .M_OUT(M+1),
                   .LOG_TO_LINEAR_BITS(LOG_TO_LINEAR_BITS),
                   .ACC_NON_FRAC(ACC_NON_FRAC),
                   .ACC_FRAC(ACC_FRAC),
                   .OVERFLOW_DETECTION(OVERFLOW_DETECTION))
  lma(.a(aIn),
      .b(bIn),
      .accIn(cIn),
      .accOut(cOut));
endmodule
