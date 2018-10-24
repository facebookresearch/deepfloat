// Copyright (c) Facebook, Inc. and its affiliates. All Rights Reserved.
// All rights reserved.
//
// This source code is licensed under the license found in the
// LICENSE file in the root directory of this source tree.


module LogNumberToLogNumberUnpacked #(parameter M=3,
                                      parameter F=4)
  (LogNumber.InputIf in,
   LogNumberUnpacked.OutputIf out);

  initial begin
    assert(in.M == M);
    assert(in.F == F);
    assert(out.M == M);
    assert(out.F == F);
  end

  logic isZeroOrInf;

  localparam VAL_LEN = M + F;
  localparam TOTAL_LEN = 1 + VAL_LEN;

  always_comb begin
    isZeroOrInf = in.isZeroOrInf(in.data);
    out.data.sign = in.data.sign;
    out.data.isZero = isZeroOrInf && !in.data.sign;
    out.data.isInf = isZeroOrInf && in.data.sign;
    out.data.signedLogExp = in.signedExponent(in.data);
    out.data.logFrac = in.data.logFrac;
  end
endmodule
