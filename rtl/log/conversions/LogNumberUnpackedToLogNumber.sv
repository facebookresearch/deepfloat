// Copyright (c) Facebook, Inc. and its affiliates. All Rights Reserved.
// All rights reserved.
//
// This source code is licensed under the license found in the
// LICENSE file in the root directory of this source tree.


module LogNumberUnpackedToLogNumber #(parameter M=3,
                                      parameter F=4,
                                      parameter SATURATE_MAX=1)
  (LogNumberUnpacked.InputIf in,
   LogNumber.OutputIf out);

  initial begin
    assert(in.M == M);
    assert(in.F == F);
    assert(out.M == M);
    assert(out.F == F);
  end

  logic [M-1:0] biasedLogExp;
  logic isMax;

  always_comb begin
    biasedLogExp = in.biasedExponent(in.data);

    // We disallow this number in the encoded form
    isMax = (&biasedLogExp) & (&in.data.logFrac);

    if (in.data.isInf) begin
      out.data = out.inf();
    end else if (in.data.isZero) begin
      out.data = out.zero();
    end else if (isMax) begin
      if (SATURATE_MAX) begin
        out.data = out.getMax(in.data.sign);
      end else begin
        out.data = out.inf();
      end
    end else begin
      out.data.sign = in.data.sign;
      out.data.logExp = biasedLogExp;
      out.data.logFrac = in.data.logFrac;
    end
  end
endmodule
