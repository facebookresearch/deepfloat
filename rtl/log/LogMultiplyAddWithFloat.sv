// Copyright (c) Facebook, Inc. and its affiliates. All Rights Reserved.
// All rights reserved.
//
// This source code is licensed under the license found in the
// LICENSE file in the root directory of this source tree.


module LogMultiplyAddWithFloat #(parameter M=5,
                                 parameter F=4,
                                 parameter M_OUT=M+1,
                                 parameter SATURATE_MAX=1,
                                 parameter LOG_TO_LINEAR_BITS=8,
                                 parameter ACC_EXP=5,
                                 parameter ACC_FRAC=10,
                                 parameter OVERFLOW_DETECTION=0)
  (LogNumberUnpacked.InputIf a,
   LogNumberUnpacked.InputIf b,
   Float.InputIf accIn,
   Float.OutputIf accOut);

  initial begin
    assert(a.M == M);
    assert(a.F == F);
    assert(b.M == M);
    assert(b.F == F);

    assert(accIn.EXP == ACC_EXP);
    assert(accIn.FRAC == ACC_FRAC);
    assert(accOut.EXP == ACC_EXP);
    assert(accOut.FRAC == ACC_FRAC);
  end

  LogNumberUnpacked #(.M(M_OUT), .F(F)) c();

  LogMultiply #(.M(M),
                .F(F),
                .M_OUT(M_OUT),
                .SATURATE_MAX(SATURATE_MAX))
  mul(.a,
      .b,
      .c);

  LogAddWithFloat #(.M(M_OUT),
                    .F(F),
                    .LOG_TO_LINEAR_BITS(LOG_TO_LINEAR_BITS),
                    .ACC_EXP(ACC_EXP),
                    .ACC_FRAC(ACC_FRAC),
                    .OVERFLOW_DETECTION(OVERFLOW_DETECTION))
  add(.logIn(c),
      .accIn(accIn),
      .accOut(accOut));
endmodule
