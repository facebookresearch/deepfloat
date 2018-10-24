// Copyright (c) Facebook, Inc. and its affiliates. All Rights Reserved.
// All rights reserved.
//
// This source code is licensed under the license found in the
// LICENSE file in the root directory of this source tree.

// FIXME: not a test
module LogCompactToLogUnpackedTest();
  localparam WIDTH = 8;
  localparam LS = 1;

  localparam M = PositDef::getSignedExponentBits(WIDTH, LS);
  localparam F = PositDef::getFractionBits(WIDTH, LS);
  localparam LOG_TO_LINEAR_BITS = 8;

  LogNumberCompact #(.WIDTH(WIDTH), .LS(LS)) logIn();
  LogNumberUnpacked #(.M(M), .F(F)) logInDecoded();

  LogCompactToLogUnpacked #(.WIDTH(WIDTH),
                            .LS(LS))
  lc2l(.in(logIn),
       .out(logInDecoded));

  Float #(.EXP(8), .FRAC(23)) floatOut();

  LogToFloat #(.M(M),
               .F(F),
               .LOG_TO_LINEAR_BITS(LOG_TO_LINEAR_BITS),
               .EXP(8),
               .FRAC(23))
  l2f(.in(logInDecoded),
      .out(floatOut));

  integer i;
  initial begin
    for (i = 0; i < 2 ** $bits(logIn.data); ++i) begin
      logIn.data = i;
      #1;

      $display("%p -> packed log %s %.8g",
               logIn.data.bits,
               logInDecoded.print(logInDecoded.data),
               floatOut.toReal(floatOut.data));
    end
  end
endmodule
