// Copyright (c) Facebook, Inc. and its affiliates. All Rights Reserved.
// All rights reserved.
//
// This source code is licensed under the license found in the
// LICENSE file in the root directory of this source tree.

module FloatToLogTool();
  localparam IN_EXP = 8;
  localparam IN_FRAC = 23;

  localparam M = 3;
  localparam F = 4;

  localparam LINEAR_TO_LOG_BITS = 8;
  localparam LOG_TO_LINEAR_BITS = 8;

  Float #(.EXP(IN_EXP), .FRAC(IN_FRAC)) in();
  FloatSigned #(.EXP(IN_EXP), .FRAC(LINEAR_TO_LOG_BITS)) inSigned();

  FloatToFloatSigned #(.EXP(IN_EXP),
                       .FRAC(IN_FRAC),
                       .SIGNED_EXP(IN_EXP),
                       .SIGNED_FRAC(LINEAR_TO_LOG_BITS))
  f2fs(.in(in),
       .out(inSigned));

  // Produce non-tapered (M, F) log number
  LogNumberUnpacked #(.M(M), .F(F)) logUnpacked();

  FloatSignedToLog #(.EXP_IN(IN_EXP),
                     .FRAC_IN(LINEAR_TO_LOG_BITS),
                     .M(M),
                     .F(F))
  fs2l(.in(inSigned),
       .out(logUnpacked));

  LogNumber #(.M(M), .F(F)) logPacked();

  LogNumberUnpackedToLogNumber #(.M(M),
                                 .F(F))
  lu2ln(.in(logUnpacked),
        .out(logPacked));

  // Produce tapered (WIDTH, LS) log number
  localparam WIDTH = 8;
  localparam LS = 1;

  localparam POSIT_M = PositDef::getSignedExponentBits(WIDTH, LS);
  localparam POSIT_F = PositDef::getFractionBits(WIDTH, LS);

  LogNumberUnpacked #(.M(POSIT_M), .F(POSIT_F + 3)) logPositTrailing();

  FloatSignedToLog #(.EXP_IN(IN_EXP),
                     .FRAC_IN(LINEAR_TO_LOG_BITS),
                     .M(POSIT_M),
                     .F(POSIT_F + 3))
  fs2lp(.in(inSigned),
        .out(logPositTrailing));

  LogNumberUnpacked #(.M(M), .F(F)) logPositUnpacked();
  logic [2:0] logTrailingBits;

  LogNumberUnpackedExtractTrailing #(.M(M),
                                     .F(F),
                                     .LOG_TRAILING_BITS(3))
  ext(.in(logPositTrailing),
      .out(logPositUnpacked),
      .logTrailingBits);

  LogNumberCompact #(.WIDTH(WIDTH), .LS(LS)) logPosit();

  LogNumberUnpackedToLogCompact #(.WIDTH(WIDTH),
                                  .LS(LS))
  ln2lc(.in(logPositUnpacked),
        .trailingBits(logTrailingBits[2:1]),
        .stickyBit(logTrailingBits[0]),
        .out(logPosit));

  LogNumberUnpacked #(.M(POSIT_M), .F(POSIT_F)) postPack();

  LogCompactToLogUnpacked #(.WIDTH(WIDTH),
                            .LS(LS))
  lcUnpack(.in(logPosit),
           .out(postPack));

  Float #(.EXP(8), .FRAC(23)) postPackFloat();

  LogToFloat #(.M(POSIT_M),
               .F(POSIT_F),
               .LOG_TO_LINEAR_BITS(LOG_TO_LINEAR_BITS),
               .EXP(8),
               .FRAC(23))
  l2f(.in(postPack),
      .out(postPackFloat));

  integer i;

  shortreal v;

  initial begin
    for (i = 0; i < 20; ++i) begin
      v = 1.0 + i / 20.0;

      in.data = $shortrealtobits(v);
      #1;

      $display("float32 %g", v);
      $display("(%p, %p) log %s",
               M, F,
               logUnpacked.print(logUnpacked.data));
      $display("(%p, %p) log posit %b (%s) %g",
               POSIT_M, POSIT_F,
               logPosit.data,
               postPack.print(postPack.data),
               postPackFloat.toReal(postPackFloat.data));
    end
  end
endmodule
