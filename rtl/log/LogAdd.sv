// Copyright (c) Facebook, Inc. and its affiliates. All Rights Reserved.
// All rights reserved.
//
// This source code is licensed under the license found in the
// LICENSE file in the root directory of this source tree.


// accOut = accIn + linear(logIn)
module LogAdd #(parameter M=5,
                parameter F=10,
                parameter LOG_TO_LINEAR_BITS=8,
                parameter ACC_NON_FRAC=16,
                parameter ACC_FRAC=16,
                parameter OVERFLOW_DETECTION=0)
  (LogNumberUnpacked.InputIf logIn,
   Kulisch.InputIf accIn,
   Kulisch.OutputIf accOut);

  initial begin
    assert(logIn.M == M);
    assert(logIn.F == F);
    assert(accIn.ACC_NON_FRAC == ACC_NON_FRAC);
    assert(accIn.ACC_FRAC == ACC_FRAC);
    assert(accOut.ACC_NON_FRAC == ACC_NON_FRAC);
    assert(accOut.ACC_FRAC == ACC_FRAC);
  end

  // 1. Convert the log number to a signed float
  FloatSigned #(.EXP(M), .FRAC(LOG_TO_LINEAR_BITS)) floatSigned();

  LogNumberUnpackedToFloatSigned #(.M(M),
                                   .F(F),
                                   .LOG_TO_LINEAR_BITS(LOG_TO_LINEAR_BITS))
  logToFloat(.in(logIn),
             .out(floatSigned));

  // 2. Convert the linear float to a linear fixed-point
  Kulisch #(.ACC_NON_FRAC(ACC_NON_FRAC), .ACC_FRAC(ACC_FRAC)) linearFixed();

  FloatSignedToLinearFixed #(.SIGNED_EXP(M),
                             .FRAC(LOG_TO_LINEAR_BITS),
                             .ACC_NON_FRAC(ACC_NON_FRAC),
                             .ACC_FRAC(ACC_FRAC),
                             .OVERFLOW_DETECTION(OVERFLOW_DETECTION))
  floatToFixed(.in(floatSigned),
               .out(linearFixed));

  // 3. Sum accumulators
  KulischAccumulatorAdd #(.ACC_NON_FRAC(ACC_NON_FRAC),
                          .ACC_FRAC(ACC_FRAC),
                          .OVERFLOW_DETECTION(OVERFLOW_DETECTION))
  add(.a(linearFixed),
      .b(accIn),
      .out(accOut));
endmodule
