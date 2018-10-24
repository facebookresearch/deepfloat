// Copyright (c) Facebook, Inc. and its affiliates. All Rights Reserved.
// All rights reserved.
//
// This source code is licensed under the license found in the
// LICENSE file in the root directory of this source tree.


module LogNumberUnpackedToFloatSigned #(parameter M=5,
                                        parameter F=10,
                                        parameter LOG_TO_LINEAR_BITS=8)
  (LogNumberUnpacked.InputIf in,
   FloatSigned.OutputIf out);

  initial begin
    assert(in.M == M);
    assert(in.F == F);

    assert(out.EXP == M);
    assert(out.FRAC == LOG_TO_LINEAR_BITS);
  end

  logic [F-1:0] log2Fraction;

  // Performs the log -> linear mapping
  Pow2Map #(.IN(F),
            .OUT(LOG_TO_LINEAR_BITS))
  pow2(.in(log2Fraction),
       .out(out.data.frac));

  always_comb begin
    out.data.isInf = in.data.isInf;
    out.data.isZero = in.data.isZero;

    // sign
    // this can be garbage if isInf || isZero
    out.data.sign = in.data.sign;

    // fraction
    // this can be garbage if isInf || isZero
    log2Fraction = in.data.logFrac;

    // exponent
    // this can be garbage if isInf || isZero
    out.data.exp = in.data.signedLogExp;
  end
endmodule
