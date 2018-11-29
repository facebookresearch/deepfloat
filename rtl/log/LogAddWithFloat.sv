// Copyright (c) Facebook, Inc. and its affiliates. All Rights Reserved.
// All rights reserved.
//
// This source code is licensed under the license found in the
// LICENSE file in the root directory of this source tree.


// accOut = accIn + linear(logIn)
module LogAddWithFloat #(parameter M=5,
                         parameter F=10,
                         parameter ACC_EXP=5,
                         parameter ACC_FRAC=10,
                         parameter LOG_TO_LINEAR_BITS=8,
                         parameter OVERFLOW_DETECTION=0)
  (LogNumberUnpacked.InputIf logIn,
   Float.InputIf accIn,
   Float.OutputIf accOut);

  initial begin
    assert(logIn.M == M);
    assert(logIn.F == F);

    assert(accIn.EXP == ACC_EXP);
    assert(accIn.FRAC == ACC_FRAC);
    assert(accOut.EXP == ACC_EXP);
    assert(accOut.FRAC == ACC_FRAC);
  end

  // 1. Convert the log number to a signed float
  FloatSigned #(.EXP(M), .FRAC(LOG_TO_LINEAR_BITS)) floatSigned();

  LogNumberUnpackedToFloatSigned #(.M(M),
                                   .F(F),
                                   .LOG_TO_LINEAR_BITS(LOG_TO_LINEAR_BITS))
  logToFloat(.in(logIn),
             .out(floatSigned));

  // 2. Convert the signed float to a biased float
  Float #(.EXP(ACC_EXP), .FRAC(ACC_FRAC)) float();

  FloatSignedToFloat #(.EXP(ACC_EXP),
                       .FRAC(ACC_FRAC),
                       .SIGNED_EXP(M),
                       .SIGNED_FRAC(LOG_TO_LINEAR_BITS))
  fs2f(.in(floatSigned),
       .out(float));

  // 3. Sum the linear floats
  DW_fp_add #(.sig_width(ACC_FRAC),
              .exp_width(ACC_EXP),
              .ieee_compliance(0))
  add(.a(accIn.data),
      .b(float.data),
      .z(accOut.data),
      .status(),
      // r2ne
      .rnd(3'b000));
endmodule
