// Copyright (c) Facebook, Inc. and its affiliates. All Rights Reserved.
// All rights reserved.
//
// This source code is licensed under the license found in the
// LICENSE file in the root directory of this source tree.

module LogAddTest();
  localparam M = 3;
  localparam F = 4;
  localparam LOG_TO_LINEAR_BITS = 8;

  localparam ACC_NON_FRAC = 1 + ((2 ** (M - 1)) - 1);
  localparam ACC_FRAC = LOG_TO_LINEAR_BITS + (2 ** (M - 1));

  LogNumber #(.M(M), .F(F)) logIn();
  LogNumberUnpacked #(.M(M), .F(F)) logInDecoded();

  Kulisch #(.ACC_NON_FRAC(ACC_NON_FRAC), .ACC_FRAC(ACC_FRAC)) accIn();
  Kulisch #(.ACC_NON_FRAC(ACC_NON_FRAC), .ACC_FRAC(ACC_FRAC)) accOut();

  LogNumberToLogNumberUnpacked #(.M(M),
                                 .F(F))
  logProps(.in(logIn),
           .out(logInDecoded));

  LogAdd #(.M(M),
           .F(F),
           .LOG_TO_LINEAR_BITS(LOG_TO_LINEAR_BITS),
           .ACC_NON_FRAC(ACC_NON_FRAC),
           .ACC_FRAC(ACC_FRAC))
  add(.logIn(logInDecoded),
      .accIn,
      .accOut);

  Float #(.EXP(8), .FRAC(23)) floatOut();

  KulischToFloat #(.ACC_NON_FRAC(ACC_NON_FRAC),
                   .ACC_FRAC(ACC_FRAC),
                   .EXP(8),
                   .FRAC(23))
  a2f(.in(accOut),
      .out(floatOut));

  integer i;

  initial begin
    for (i = 0; i < 2 ** (M+F+1); ++i) begin
      logIn.data = i;

      accIn.data = accIn.zero();

      #1;
      $display("log %s -> lin %s (%g) exp %d",
               logIn.print(logIn.data),
               accOut.print(accOut.data),
               floatOut.toReal(floatOut.data),
               logIn.signedExponent(logIn.data));
    end
  end
endmodule
