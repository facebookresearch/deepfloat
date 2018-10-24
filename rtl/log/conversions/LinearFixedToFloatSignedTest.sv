// Copyright (c) Facebook, Inc. and its affiliates. All Rights Reserved.
// All rights reserved.
//
// This source code is licensed under the license found in the
// LICENSE file in the root directory of this source tree.

// Copyright (c) Facebook, Inc. and its affiliates. All Rights Reserved.
// All rights reserved.
//
// This source code is licensed under the license found in the
// LICENSE file in the root directory of this source tree.
module LinearFixedToFloatSignedTest();
  localparam FRAC = 8;
  localparam ACC_NON_FRAC = FRAC * 2 + 1;
  localparam ACC_FRAC = FRAC * 2;
  localparam SIGNED_EXP = $clog2(ACC_NON_FRAC + ACC_FRAC + 1);
  localparam OVERFLOW_DETECTION = 0;

  FloatSigned #(.EXP(SIGNED_EXP), .FRAC(FRAC)) in();
  Kulisch #(.ACC_NON_FRAC(ACC_NON_FRAC), .ACC_FRAC(ACC_FRAC)) linearFixed();

  FloatSignedToLinearFixed #(.SIGNED_EXP(SIGNED_EXP),
                             .FRAC(FRAC),
                             .ACC_NON_FRAC(ACC_NON_FRAC),
                             .ACC_FRAC(ACC_FRAC),
                             .OVERFLOW_DETECTION(OVERFLOW_DETECTION))
  fs2lf(.out(linearFixed),
        .*);

  FloatSigned #(.EXP(SIGNED_EXP), .FRAC(FRAC)) out();
  logic [1:0] trailingBits;
  logic stickyBit;

  LinearFixedToFloatSigned #(.ACC_NON_FRAC(ACC_NON_FRAC),
                             .ACC_FRAC(ACC_FRAC),
                             .EXP(SIGNED_EXP),
                             .FRAC(FRAC),
                             .TRAILING_BITS(2),
                             .USE_ADJUST(0))
  lf2fs(.in(linearFixed),
        .adjustExp(),
        .out(out),
        .trailingBits,
        .stickyBit);

  integer i;

  initial begin
    // Test special values
    in.data = in.zero(1'b0);
    #1;
    assert(out.data.isZero);

    in.data = in.inf(1'b0);
    #1;
    assert(out.data.isInf);

    // Reset
    in.data = in.zero(1'b0);
    in.data.isZero = 1'b0;

    for (i = 0; i < 50; ++i) begin
      // Test random values
      in.data.exp = $random;
      in.data.frac = $random;
      #1;
      if (out.data != in.data) begin
        $display("in %s out %s",
                 in.print(in.data),
                 out.print(out.data));

        assert(out.data == in.data);
      end
    end
  end
endmodule
