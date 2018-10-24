// Copyright (c) Facebook, Inc. and its affiliates. All Rights Reserved.
// All rights reserved.
//
// This source code is licensed under the license found in the
// LICENSE file in the root directory of this source tree.

module FloatToLog #(parameter EXP=8,
                    parameter FRAC=23,
                    parameter LINEAR_TO_LOG_BITS=8,
                    parameter M=3,
                    parameter F=4,
                    parameter USE_LOG_TRAILING_BITS=0,
                    parameter LOG_TRAILING_BITS=3,
                    parameter SATURATE_MAX=1)
  (Float.InputIf in,
   LogNumberUnpacked.OutputIf out,
   output logic [LOG_TRAILING_BITS-1:0] logTrailingBits);

  initial begin
    assert(in.EXP == EXP);
    assert(in.FRAC == FRAC);
    assert(out.M == M);
    assert(out.F == F);
  end

  FloatSigned #(.EXP(EXP), .FRAC(LINEAR_TO_LOG_BITS)) inSigned();

  FloatToFloatSigned #(.EXP(EXP),
                       .FRAC(FRAC),
                       .SIGNED_EXP(EXP),
                       .SIGNED_FRAC(LINEAR_TO_LOG_BITS),
                       .SATURATE_MAX(SATURATE_MAX))
  f2f2(.in(in),
       .out(inSigned));

  localparam REAL_LOG_TRAILING_BITS = USE_LOG_TRAILING_BITS ?
                                      LOG_TRAILING_BITS : 0;

  LogNumberUnpacked #(.M(M), .F(F+REAL_LOG_TRAILING_BITS)) logWithTrailing();

  FloatSignedToLog #(.EXP_IN(EXP),
                     .FRAC_IN(LINEAR_TO_LOG_BITS),
                     .M(M),
                     .F(F+REAL_LOG_TRAILING_BITS),
                     .SATURATE_MAX(SATURATE_MAX))
  fs2l(.in(inSigned),
       .out(logWithTrailing));

  generate
    if (USE_LOG_TRAILING_BITS) begin
      LogNumberUnpackedExtractTrailing #(.M(M),
                                         .F(F),
                                         .LOG_TRAILING_BITS(LOG_TRAILING_BITS))
      ext(.in(logWithTrailing),
          .out(out),
          .logTrailingBits);
    end else begin
      always_comb begin
        out.data = logWithTrailing.data;
      end
    end
  endgenerate
endmodule
