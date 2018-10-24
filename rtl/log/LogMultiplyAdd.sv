// Copyright (c) Facebook, Inc. and its affiliates. All Rights Reserved.
// All rights reserved.
//
// This source code is licensed under the license found in the
// LICENSE file in the root directory of this source tree.


module LogMultiplyAdd #(parameter M=5,
                        parameter F=4,
                        parameter M_OUT=M+1,
                        parameter SATURATE_MAX=1,
                        parameter LOG_TO_LINEAR_BITS=8,
                        parameter ACC_NON_FRAC=16,
                        parameter ACC_FRAC=16,
                        parameter OVERFLOW_DETECTION=0)
  (LogNumberUnpacked.InputIf a,
   LogNumberUnpacked.InputIf b,
   Kulisch.InputIf accIn,
   Kulisch.OutputIf accOut);

  initial begin
    assert(a.M == M);
    assert(a.F == F);
    assert(b.M == M);
    assert(b.F == F);

    assert(accIn.ACC_NON_FRAC == ACC_NON_FRAC);
    assert(accIn.ACC_FRAC == ACC_FRAC);
    assert(accOut.ACC_NON_FRAC == ACC_NON_FRAC);
    assert(accOut.ACC_FRAC == ACC_FRAC);
  end

  LogNumberUnpacked #(.M(M_OUT), .F(F)) c();

  LogMultiply #(.M(M),
                .F(F),
                .M_OUT(M_OUT),
                .SATURATE_MAX(SATURATE_MAX))
  mul(.a,
      .b,
      .c);

  LogAdd #(.M(M_OUT),
           .F(F),
           .LOG_TO_LINEAR_BITS(LOG_TO_LINEAR_BITS),
           .ACC_NON_FRAC(ACC_NON_FRAC),
           .ACC_FRAC(ACC_FRAC),
           .OVERFLOW_DETECTION(OVERFLOW_DETECTION))
  add(.logIn(c),
      .accIn(accIn),
      .accOut(accOut));
endmodule
