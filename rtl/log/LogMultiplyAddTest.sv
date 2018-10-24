// Copyright (c) Facebook, Inc. and its affiliates. All Rights Reserved.
// All rights reserved.
//
// This source code is licensed under the license found in the
// LICENSE file in the root directory of this source tree.


// FIXME: this is not much of a test
module LogMultiplyAddTest();
  parameter WIDTH = 8;
  parameter LS = 1;

  localparam ACC_NON_FRAC = LogDef::getAccNonFracTapered(WIDTH, LS);
  localparam ACC_FRAC = LogDef::getAccFracTapered(WIDTH, LS);

  localparam M = PositDef::getSignedExponentBits(WIDTH, LS);
  localparam F = PositDef::getFractionBits(WIDTH, LS);
  localparam LOG_TO_LINEAR_BITS = 8;

  LogNumberCompact #(.WIDTH(WIDTH), .LS(LS)) a();
  LogNumberUnpacked #(.M(M), .F(F)) aDec();

  LogCompactToLogUnpacked #(.WIDTH(WIDTH),
                            .LS(LS))
  lc2la(.in(a),
        .out(aDec));

  LogNumberCompact #(.WIDTH(WIDTH), .LS(LS)) b();
  LogNumberUnpacked #(.M(M), .F(F)) bDec();

  LogCompactToLogUnpacked #(.WIDTH(WIDTH),
                            .LS(LS))
  lc2lb(.in(b),
        .out(bDec));

  Kulisch #(.ACC_NON_FRAC(ACC_NON_FRAC), .ACC_FRAC(ACC_FRAC)) accIn();
  Kulisch #(.ACC_NON_FRAC(ACC_NON_FRAC), .ACC_FRAC(ACC_FRAC)) accOut();

  LogMultiplyAdd #(.M(M),
                   .F(F),
                   .M_OUT(M+1),
                   .LOG_TO_LINEAR_BITS(LOG_TO_LINEAR_BITS),
                   .ACC_NON_FRAC(ACC_NON_FRAC),
                   .ACC_FRAC(ACC_FRAC),
                   .OVERFLOW_DETECTION(1))
  lma(.a(aDec),
      .b(bDec),
      .accIn,
      .accOut);

  integer i;

  initial begin
    accIn.data = accIn.zero();

    // Test smallest possible product
    a.data = 1;
    b.data = 1;
    #1;
    // should be the smallest maintained value
    assert(accOut.getFracBits(accOut.data) == 1'b1);

    // Test product of ones
    a.data = a.one(1'b0);
    b.data = b.one(1'b0);
    #1;
    // should be 1
    assert(accOut.getFracBits(accOut.data) == 1'b0);
    assert(accOut.getNonFracBits(accOut.data) == 1'b1);

    // Test sum of product of 1s
    for (i = 0; i < 2 ** ACC_NON_FRAC - 1; ++i) begin
      #1;
      accIn.data = accOut.data;
    end

    // Should not be in overflow yet
    assert(!accOut.data.isOverflow);
    assert(!accOut.getSign(accOut.data));

    #1;

    // Should now be in overflow
    assert(accOut.data.isOverflow);
    assert(!accOut.data.overflowSign);

    // Test sum of -1
    accIn.data = accIn.zero();
    a.data = a.one(1'b1);
    b.data = b.one(1'b0);

    // There is one more sum possible for negative values (2s complement)
    for (i = 0; i < 2 ** ACC_NON_FRAC; ++i) begin
      #1;
      accIn.data = accOut.data;
    end

    // Should not be in overflow yet
    assert(!accOut.data.isOverflow);
    assert(accOut.getSign(accOut.data));

    #1;

    // Should now be in overflow
    assert(accOut.data.isOverflow);
    assert(accOut.data.overflowSign);
  end
endmodule
