// Copyright (c) Facebook, Inc. and its affiliates. All Rights Reserved.
// All rights reserved.
//
// This source code is licensed under the license found in the
// LICENSE file in the root directory of this source tree.

module LogNumberUnpackedToLogCompactTest();
  localparam WIDTH = 8;
  localparam LS = 1;

  localparam M = PositDef::getSignedExponentBits(WIDTH, LS);
  localparam F = PositDef::getFractionBits(WIDTH, LS);

  LogNumberCompact #(.WIDTH(WIDTH), .LS(LS)) logIn();
  LogNumberUnpacked #(.M(M), .F(F)) logInUnpacked();

  LogCompactToLogUnpacked #(.WIDTH(WIDTH),
                            .LS(LS))
  lc2l(.in(logIn),
       .out(logInUnpacked));

  LogNumberCompact #(.WIDTH(WIDTH), .LS(LS)) logOut();

  LogNumberUnpackedToLogCompact #(.WIDTH(WIDTH),
                                  .LS(LS))
  l2lc(.in(logInUnpacked),
       .trailingBits(2'b0),
       .stickyBit(1'b0),
       .out(logOut));

  integer i;
  initial begin
    for (i = 0; i < 2 ** $bits(logIn.data); ++i) begin
      logIn.data = i;
      #1;

      // log posit -> log -> log posit should be the identity
      assert(logIn.data.bits == logOut.data.bits);
    end
  end
endmodule

// FIXME: not a real test
module LogNumberUnpackedToLogCompactTest2();
  localparam WIDTH = 8;
  localparam LS = 1;

  localparam M = PositDef::getSignedExponentBits(WIDTH, LS);
  localparam F = PositDef::getFractionBits(WIDTH, LS);
  localparam LOG_TO_LINEAR_BITS = 8;
  localparam LINEAR_TO_LOG_BITS = 8;
  localparam FRAC_PRECISION = 8;

  // Test conversion of float -> log compact -> float
  Float #(.EXP(8), .FRAC(23)) floatIn();
  LogNumberUnpacked #(.M(M), .F(F)) logUnpacked();
  logic [2:0] logTrailingBits;

  FloatToLog #(.EXP(8),
               .FRAC(23),
               .LINEAR_TO_LOG_BITS(LINEAR_TO_LOG_BITS),
               .M(M),
               .F(F),
               .SATURATE_MAX(1))
  f2l(.in(floatIn),
      .out(logUnpacked),
      .logTrailingBits);

  LogNumberCompact #(.WIDTH(WIDTH), .LS(LS)) logCompact();

  LogNumberUnpackedToLogCompact #(.WIDTH(WIDTH),
                                  .LS(LS))
  l2lc(.in(logUnpacked),
       .trailingBits(logTrailingBits[2:1]),
       .stickyBit(logTrailingBits[0]),
       .out(logCompact));

  LogNumberUnpacked #(.M(M), .F(F)) logUnpacked2();

  LogCompactToLogUnpacked #(.WIDTH(WIDTH),
                            .LS(LS))
  lc2l(.in(logCompact),
       .out(logUnpacked2));

  Float #(.EXP(8), .FRAC(23)) fOut();

  LogToFloat #(.M(M),
               .F(F),
               .LOG_TO_LINEAR_BITS(LOG_TO_LINEAR_BITS),
               .EXP(8),
               .FRAC(23))
  l2f(.in(logUnpacked2),
      .out(fOut));

  integer i;

  initial begin
    for (i = 0; i < 10; ++i) begin
      floatIn.data.sign = $random;
      floatIn.data.fraction = $random;
      floatIn.data.exponent = $urandom_range(FloatDef::getExpBias(8, 23) - 10,
                                             FloatDef::getExpBias(8, 23) + 10);
      #1;

      $display("%g -> log unpacked %s -> log compact %p -> log unpacked %s -> %g",
               floatIn.toReal(floatIn.data),
               logUnpacked.print(logUnpacked.data),
               logCompact.data.bits,
               logUnpacked2.print(logUnpacked2.data),
               fOut.toReal(fOut.data));
    end
  end
endmodule
