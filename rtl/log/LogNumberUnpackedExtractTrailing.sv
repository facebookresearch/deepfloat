// Copyright (c) Facebook, Inc. and its affiliates. All Rights Reserved.
// All rights reserved.
//
// This source code is licensed under the license found in the
// LICENSE file in the root directory of this source tree.

module LogNumberUnpackedExtractTrailing #(parameter M=3,
                                          parameter F=4,
                                          parameter LOG_TRAILING_BITS=3)
  (LogNumberUnpacked.InputIf in,
   LogNumberUnpacked.OutputIf out,
   output logic [LOG_TRAILING_BITS-1:0] logTrailingBits);

  initial begin
    assert(in.M == M);
    assert(in.F == F + LOG_TRAILING_BITS);

    assert(out.M == M);
    assert(out.F == F);
  end

  always_comb begin
    out.data.sign = in.data.sign;
    out.data.isInf = in.data.isInf;
    out.data.isZero = in.data.isZero;
    out.data.signedLogExp = in.data.signedLogExp;
    out.data.logFrac = in.data.logFrac[F+LOG_TRAILING_BITS-1:LOG_TRAILING_BITS];
    logTrailingBits = in.data.logFrac[LOG_TRAILING_BITS-1:0];
  end
endmodule
