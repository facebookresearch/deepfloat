// Copyright (c) Facebook, Inc. and its affiliates. All Rights Reserved.
// All rights reserved.
//
// This source code is licensed under the license found in the
// LICENSE file in the root directory of this source tree.

module LinearFixedToLog #(parameter ACC_NON_FRAC=16,
                          parameter ACC_FRAC=16,
                          parameter M=3,
                          parameter F=4,
                          parameter LINEAR_TO_LOG_BITS=8,
                          parameter USE_LOG_TRAILING_BITS=0,
                          parameter LOG_TRAILING_BITS=1,
                          parameter USE_ADJUST=0,
                          parameter ADJUST_EXP_SIZE=1,
                          parameter SATURATE_MAX=1)
  (Kulisch.InputIf in,
   input signed [ADJUST_EXP_SIZE-1:0] adjustExp,
   LogNumberUnpacked.OutputIf out,
   output logic [LOG_TRAILING_BITS-1:0] logTrailingBits);

  initial begin
    assert(in.ACC_NON_FRAC == ACC_NON_FRAC);
    assert(in.ACC_FRAC == ACC_FRAC);

    assert(out.M == M);
    assert(out.F == F);

    assert(LINEAR_TO_LOG_BITS >= F);
  end

  localparam TOTAL_ACC = KulischDef::getBits(ACC_NON_FRAC, ACC_FRAC);
  localparam LZ_COUNT_BITS = $clog2(TOTAL_ACC-1+1+1);
  localparam TRAILING_BITS = 2;

  FloatSigned #(.EXP(LZ_COUNT_BITS), .FRAC(LINEAR_TO_LOG_BITS)) fs();
  logic [TRAILING_BITS-1:0] trailingBits;
  logic stickyBit;

  LinearFixedToFloatSigned #(.ACC_NON_FRAC(ACC_NON_FRAC),
                             .ACC_FRAC(ACC_FRAC),
                             .EXP(LZ_COUNT_BITS),
                             .FRAC(LINEAR_TO_LOG_BITS),
                             .TRAILING_BITS(TRAILING_BITS),
                             .USE_ADJUST(USE_ADJUST),
                             .ADJUST_EXP_SIZE(ADJUST_EXP_SIZE),
                             .SATURATE_MAX(SATURATE_MAX))
  linFix2FloatSgn(.in(in),
                  .adjustExp(adjustExp),
                  .out(fs),
                  .trailingBits,
                  .stickyBit);

  // Round the float number based on the rounding bits
  FloatSigned #(.EXP(LZ_COUNT_BITS), .FRAC(LINEAR_TO_LOG_BITS)) fsRound();
  logic roundUp;

  FloatSignedRoundToNearestEven #(.EXP(LZ_COUNT_BITS),
                                  .FRAC(LINEAR_TO_LOG_BITS),
                                  .SATURATE_MAX(SATURATE_MAX))
  r2ne(.in(fs),
       .trailingBits,
       .stickyBit,
       .out(fsRound),
       .roundUp);

  localparam REAL_LOG_TRAILING_BITS = USE_LOG_TRAILING_BITS ?
                                      LOG_TRAILING_BITS : 0;

  // Convert the linear float to a log number, producing a desired number of
  // trailing bits
  LogNumberUnpacked #(.M(M), .F(F+REAL_LOG_TRAILING_BITS)) logWithTrailing();

  FloatSignedToLog #(.EXP_IN(LZ_COUNT_BITS),
                     .FRAC_IN(LINEAR_TO_LOG_BITS),
                     .M(M),
                     .F(F+REAL_LOG_TRAILING_BITS),
                     .SATURATE_MAX(SATURATE_MAX))
  floatSgn2Log(.in(fsRound),
               .out(logWithTrailing));

  generate
    if (USE_LOG_TRAILING_BITS) begin
      LogNumberUnpackedExtractTrailing #(.M(M),
                                         .F(F),
                                         .LOG_TRAILING_BITS(LOG_TRAILING_BITS))
      extTrailing(.in(logWithTrailing),
                  .out(out),
                  .logTrailingBits);
    end else begin
      always_comb begin
        out.data = logWithTrailing.data;
      end
    end
  endgenerate
endmodule
