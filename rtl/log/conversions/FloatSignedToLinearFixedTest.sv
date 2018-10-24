// Copyright (c) Facebook, Inc. and its affiliates. All Rights Reserved.
// All rights reserved.
//
// This source code is licensed under the license found in the
// LICENSE file in the root directory of this source tree.

module FloatSignedToLinearFixedTest();
  localparam FRAC = 8;
  localparam ACC_NON_FRAC = 17;
  localparam ACC_FRAC = 16;
  localparam SIGNED_EXP = $clog2(ACC_NON_FRAC + ACC_FRAC + 1);
  localparam OVERFLOW_DETECTION = 0;

  FloatSigned #(.EXP(SIGNED_EXP), .FRAC(FRAC)) in();
  Kulisch #(.ACC_NON_FRAC(ACC_NON_FRAC), .ACC_FRAC(ACC_FRAC)) out();


  FloatSignedToLinearFixed #(.SIGNED_EXP(SIGNED_EXP),
                             .FRAC(FRAC),
                             .ACC_NON_FRAC(ACC_NON_FRAC),
                             .ACC_FRAC(ACC_FRAC),
                             .OVERFLOW_DETECTION(OVERFLOW_DETECTION))
  fs2lf(.*);

  integer i;

  initial begin
    // Test special values
    in.data = in.zero(1'b0);
    #1;
    assert(!out.data.isInf);
    assert(~|out.data.bits);

    in.data = in.inf(1'b0);
    #1;
    assert(out.data.isInf);

    // Reset
    in.data = in.zero(1'b0);
    in.data.isZero = 1'b0;

    // Test positive values
    in.data.exp = SIGNED_EXP'(0);
    #1;
    assert(out.getNonFracBits(out.data) == 1'b1);

    // exponents go from -ACC_FRAC to ACC_NON_FRAC-1
    for (i = -ACC_FRAC; i < ACC_NON_FRAC; ++i) begin
      in.data.exp = SIGNED_EXP'(i);
      #1;
      assert(out.data.bits == (1 + ACC_NON_FRAC + ACC_FRAC)'(1'b1) << (i + ACC_FRAC));
    end

    // Test negative values
    in.data.sign = 1'b1;

    in.data.exp = SIGNED_EXP'(0);
    #1;
    assert(-out.getNonFracBits(out.data) == 1'b1);

    // exponents go from -ACC_FRAC to ACC_NON_FRAC-1
    for (i = -ACC_FRAC; i < ACC_NON_FRAC; ++i) begin
      in.data.exp = SIGNED_EXP'(i);
      #1;
      assert(out.data.bits == -((1 + ACC_NON_FRAC + ACC_FRAC)'(1'b1) << (i + ACC_FRAC)));
    end
  end
endmodule
