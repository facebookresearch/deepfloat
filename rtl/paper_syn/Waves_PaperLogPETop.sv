// Copyright (c) Facebook, Inc. and its affiliates. All Rights Reserved.
// All rights reserved.
//
// This source code is licensed under the license found in the
// LICENSE file in the root directory of this source tree.

module GenWaves();
  localparam WIDTH = 8;
  localparam LS = 1;

  // for float32 input conversion only (beta=8, gamma=7)
  // not used in the PE
  localparam LINEAR_TO_LOG_BITS = 8;

  // PE alpha=5 parameter
  localparam LOG_TO_LINEAR_BITS = 5;

  localparam ACC_NON_FRAC = LogDef::getAccNonFracTapered(WIDTH, LS);
  localparam ACC_FRAC = LogDef::getAccFracTapered(WIDTH, LS);

  localparam M = PositDef::getSignedExponentBits(WIDTH, LS);
  localparam F = PositDef::getFractionBits(WIDTH, LS);

  Float #(.EXP(8), .FRAC(23)) floatInA();
  LogNumberUnpacked #(.M(M), .F(F)) logOutA();
  logic [2:0] logTrailingBitsA;

  FloatToLog #(.EXP(8),
               .FRAC(23),
               .LINEAR_TO_LOG_BITS(LINEAR_TO_LOG_BITS),
               .M(M),
               .F(F),
               .USE_LOG_TRAILING_BITS(1))
  f2la(.in(floatInA),
       .out(logOutA),
       .logTrailingBits(logTrailingBitsA));

  LogNumberCompact #(.WIDTH(WIDTH), .LS(LS)) logCompactA();

  LogNumberUnpackedToLogCompact #(.WIDTH(WIDTH),
                                  .LS(LS))
  lu2lca(.in(logOutA),
         .trailingBits(logTrailingBitsA[2:1]),
         .stickyBit(logTrailingBitsA[0]),
         .out(logCompactA));

  LogNumberUnpacked #(.M(M), .F(F)) aIn();
  LogCompactToLogUnpacked #(.WIDTH(WIDTH),
                            .LS(LS))
  lc2lua(.in(logCompactA),
         .out(aIn));

  // b
  Float #(.EXP(8), .FRAC(23)) floatInB();
  LogNumberUnpacked #(.M(M), .F(F)) logOutB();
  logic [2:0] logTrailingBitsB;

  FloatToLog #(.EXP(8),
               .FRAC(23),
               .LINEAR_TO_LOG_BITS(LINEAR_TO_LOG_BITS),
               .M(M),
               .F(F),
               .USE_LOG_TRAILING_BITS(1))
  f2lb(.in(floatInB),
       .out(logOutB),
       .logTrailingBits(logTrailingBitsB));

  LogNumberCompact #(.WIDTH(WIDTH), .LS(LS)) logCompactB();

  LogNumberUnpackedToLogCompact #(.WIDTH(WIDTH),
                                  .LS(LS))
  lu2lcb(.in(logOutB),
         .trailingBits(logTrailingBitsB[2:1]),
         .stickyBit(logTrailingBitsB[0]),
         .out(logCompactB));

  LogNumberUnpacked #(.M(M), .F(F)) bIn();
  LogCompactToLogUnpacked #(.WIDTH(WIDTH),
                            .LS(LS))
  lc2lub(.in(logCompactB),
         .out(bIn));

  Kulisch #(.ACC_NON_FRAC(ACC_NON_FRAC), .ACC_FRAC(ACC_FRAC)) cOutIf();
  logic reset;
  logic clock;

  PaperLogPETop #(.WIDTH(WIDTH),
                  .LS(LS),
                  .LOG_TO_LINEAR_BITS(LOG_TO_LINEAR_BITS))
  pe(.aIn(aIn.data),
     .bIn(bIn.data),
     .cOut(cOutIf.data),
     .reset,
     .clock);

  integer i;
  integer j;

  shortreal a;
  shortreal b;

  integer seedA;
  integer seedB;

  initial begin : clockgen
    clock <= 1'b0;
    forever #(`CLOCK_PERIOD/2) clock = ~clock;
  end

  initial begin
    $fsdbDumpfile("./design.fsdb");
    $fsdbDumpvars(0, "GenWaves/pe");
    $display("clock period is %p", `CLOCK_PERIOD);

    seedA = 1;
    seedB = 2;

    for (i = 0; i < 10; ++i) begin
      reset = 1'b1;
      @(posedge clock);
      #1 reset = 1'b0;

      for (j = 0; j < 128; ++j) begin
        a = $dist_normal(seedA, 0.0, 10000000) / 10000000.0;
        b = $dist_normal(seedB, 0.0, 10000000) / 10000000.0;

        floatInA.data = $shortrealtobits(a);
        floatInB.data = $shortrealtobits(b);
        @(posedge clock);

        #1;
        $display("a %g -> %s", a,
                 aIn.print(aIn.data));
        $display("b %g -> %s", b,
                 bIn.print(bIn.data));
        $display("c %s", cOutIf.print(cOutIf.data));
      end
    end

    disable clockgen;
  end
endmodule
