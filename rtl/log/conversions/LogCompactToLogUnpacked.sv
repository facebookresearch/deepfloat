// Copyright (c) Facebook, Inc. and its affiliates. All Rights Reserved.
// All rights reserved.
//
// This source code is licensed under the license found in the
// LICENSE file in the root directory of this source tree.


module LogCompactToLogUnpacked #(parameter WIDTH=8,
                                 parameter LS=1)
  (LogNumberCompact.InputIf in,
   LogNumberUnpacked.OutputIf out);

  initial begin
    assert(in.WIDTH == WIDTH);
    assert(in.LS == LS);

    assert(out.M == PositDef::getSignedExponentBits(WIDTH, LS));
    assert(out.F == PositDef::getFractionBits(WIDTH, LS));
  end

  localparam M = PositDef::getSignedExponentBits(WIDTH, LS);

  PositPacked #(.WIDTH(WIDTH), .ES(LS)) inPacked();
  PositUnpacked #(.WIDTH(WIDTH), .ES(LS)) outUnpacked();

  PositDecode #(.WIDTH(WIDTH),
                .ES(LS))
  pdec(.in(inPacked),
       .out(outUnpacked));

  always_comb begin
    inPacked.data.bits = in.data.bits;

    out.data.sign = outUnpacked.data.sign;
    out.data.isInf = outUnpacked.data.isInf;
    out.data.isZero = outUnpacked.data.isZero;
    out.data.signedLogExp = outUnpacked.signedExponent(outUnpacked.data);
    out.data.logFrac = outUnpacked.data.fraction;
  end
endmodule
