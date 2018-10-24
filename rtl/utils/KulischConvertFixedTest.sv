// Copyright (c) Facebook, Inc. and its affiliates. All Rights Reserved.
// All rights reserved.
//
// This source code is licensed under the license found in the
// LICENSE file in the root directory of this source tree.

// FIXME: not much of a test
module KulischConvertFixedTest();
  localparam FRAC = 4;
  localparam ACC_NON_FRAC = 8;
  localparam ACC_FRAC = 8;

  localparam ACC_BITS = KulischDef::getBits(ACC_NON_FRAC, ACC_FRAC);
  localparam EXP = $clog2(ACC_BITS);

  logic [EXP-1:0] expIn;
  logic [2:-FRAC] fixedIn;
  logic fixedInfIn;

  Kulisch #(.ACC_NON_FRAC(ACC_NON_FRAC),
            .ACC_FRAC(ACC_FRAC))
  accFixed();

  KulischConvertFixed #(.FRAC(FRAC),
                        .EXP(EXP),
                        .ACC_NON_FRAC(ACC_NON_FRAC),
                        .ACC_FRAC(ACC_FRAC))
  cfixed(.expIn,
         .fixedIn,
         .fixedInfIn,
         .out(accFixed));

  Kulisch #(.ACC_NON_FRAC(ACC_NON_FRAC),
            .ACC_FRAC(ACC_FRAC))
  accZero();

  Kulisch #(.ACC_NON_FRAC(ACC_NON_FRAC),
            .ACC_FRAC(ACC_FRAC))
  accOut();

  KulischAccumulatorAdd #(.ACC_NON_FRAC(ACC_NON_FRAC),
                          .ACC_FRAC(ACC_FRAC))
  add(.a(accFixed),
      .b(accZero),
      .out(accOut));

  integer i;

  initial begin
    accZero.data = accZero.zero();

    // Try overflow with a negative fixed point number
    fixedIn = {1'b1, 1'b1, 1'b0, 4'b0101};
    fixedInfIn = 1'b0;

    for (i = 0; i < ACC_NON_FRAC + ACC_FRAC; ++i) begin
      expIn = i;

      #1;
      assert(!accOut.data.isOverflow);
      assert(!accOut.data.overflowSign);
      assert(!accOut.data.isInf);
    end

    expIn = ACC_BITS;
    #1;
    assert(accOut.data.isOverflow);
    assert(accOut.data.overflowSign);
    assert(!accOut.data.isInf);

    // Try overflow with a positive fixed point number
    fixedIn = {1'b0, 1'b0, 1'b1, 4'b0101};
    fixedInfIn = 1'b0;

    for (i = 0; i < ACC_NON_FRAC + ACC_FRAC; ++i) begin
      expIn = i;

      #1;
      assert(!accOut.data.isOverflow);
      assert(!accOut.data.overflowSign);
      assert(!accOut.data.isInf);
    end

    expIn = ACC_BITS;
    #1;
    assert(accOut.data.isOverflow);
    assert(!accOut.data.overflowSign);
    assert(!accOut.data.isInf);
  end
endmodule
