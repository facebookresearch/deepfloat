// Copyright (c) Facebook, Inc. and its affiliates. All Rights Reserved.
// All rights reserved.
//
// This source code is licensed under the license found in the
// LICENSE file in the root directory of this source tree.

module LinearFixedToLogCompact #(parameter WIDTH=8,
                                 parameter LS=1,
                                 parameter OVERFLOW_DETECTION=0,
                                 parameter NON_FRAC_REDUCE=0,
                                 parameter LINEAR_TO_LOG_BITS=8,
                                 parameter USE_ADJUST=0,
                                 parameter ADJUST_EXP_SIZE=1,
                                 parameter SATURATE_MAX=1)
  (Kulisch.InputIf in,
   input signed [ADJUST_EXP_SIZE-1:0] adjustExp,
   LogNumberCompact.OutputIf out);

  localparam ACC_NON_FRAC = LogDef::getAccNonFracTapered(WIDTH, LS) - NON_FRAC_REDUCE;
  localparam ACC_FRAC = LogDef::getAccFracTapered(WIDTH, LS);

  localparam M = PositDef::getSignedExponentBits(WIDTH, LS);
  localparam F = PositDef::getFractionBits(WIDTH, LS);

  initial begin
    assert(in.ACC_NON_FRAC == ACC_NON_FRAC);
    assert(in.ACC_FRAC == ACC_FRAC);

    assert(out.WIDTH == WIDTH);
    assert(out.LS == LS);
  end

  // 1
  LogNumberUnpacked #(.M(M), .F(F)) up();
  logic [2:0] logTrailingBits;

  LinearFixedToLog #(.ACC_NON_FRAC(ACC_NON_FRAC),
                     .ACC_FRAC(ACC_FRAC),
                     .M(M),
                     .F(F),
                     .LINEAR_TO_LOG_BITS(LINEAR_TO_LOG_BITS),
                     .USE_LOG_TRAILING_BITS(1),
                     .LOG_TRAILING_BITS(3),
                     .USE_ADJUST(USE_ADJUST),
                     .ADJUST_EXP_SIZE(ADJUST_EXP_SIZE),
                     .SATURATE_MAX(SATURATE_MAX))
  linFix2Log(.in(in),
             .adjustExp(adjustExp),
             .out(up),
             .logTrailingBits);

  LogNumberUnpackedToLogCompact #(.WIDTH(WIDTH),
                                  .LS(LS))
  log2LogC(.in(up),
           .trailingBits(logTrailingBits[2:1]),
           .stickyBit(logTrailingBits[0]),
           .out);
endmodule
