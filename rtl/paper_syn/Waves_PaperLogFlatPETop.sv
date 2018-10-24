// Copyright (c) Facebook, Inc. and its affiliates. All Rights Reserved.
// All rights reserved.
//
// This source code is licensed under the license found in the
// LICENSE file in the root directory of this source tree.

module GenWaves();
  localparam EXP = 5;
  localparam FRAC = 10;

  // for float32 input conversion only (beta=8, gamma=7)
  // not used in the PE
  localparam LINEAR_TO_LOG_BITS = 11;

  // PE alpha=5 parameter
  localparam LOG_TO_LINEAR_BITS = 11;

  localparam ACC_NON_FRAC = LogDef::getAccNonFrac(EXP, FRAC);
  localparam ACC_FRAC = LogDef::getAccFrac(EXP, FRAC);

  localparam M = EXP;
  localparam F = FRAC;

  // a
  Float #(.EXP(8), .FRAC(23)) floatInA();
  LogNumberUnpacked #(.M(M), .F(F)) logOutA();

  FloatToLog #(.EXP(8),
               .FRAC(23),
               .LINEAR_TO_LOG_BITS(LINEAR_TO_LOG_BITS),
               .M(M),
               .F(F),
               .USE_LOG_TRAILING_BITS(0))
  f2la(.in(floatInA),
       .out(logOutA),
       .logTrailingBits());

  // Pack the log number in a IEEE-style float
  Float #(.EXP(EXP), .FRAC(FRAC)) logAsFloatA();

  always_comb begin
    if (logOutA.data.isInf) begin
      logAsFloatA.data = logAsFloatA.getInf(1'b0);
    end else if (logOutA.data.isZero) begin
      logAsFloatA.data = logAsFloatA.getZero(1'b0);
    end else begin
      logAsFloatA.data.sign = logOutA.data.sign;
      logAsFloatA.data.exponent = logOutA.data.signedLogExp +
                                  EXP'(FloatDef::getExpBias(EXP, FRAC));
      logAsFloatA.data.fraction = logOutA.data.logFrac;
    end
  end

  // b
  Float #(.EXP(8), .FRAC(23)) floatInB();
  LogNumberUnpacked #(.M(M), .F(F)) logOutB();

  FloatToLog #(.EXP(8),
               .FRAC(23),
               .LINEAR_TO_LOG_BITS(LINEAR_TO_LOG_BITS),
               .M(M),
               .F(F),
               .USE_LOG_TRAILING_BITS(0))
  f2lb(.in(floatInB),
       .out(logOutB),
       .logTrailingBits());

  // Pack the log number in a IEEE-style float
  Float #(.EXP(EXP), .FRAC(FRAC)) logAsFloatB();

  always_comb begin
    if (logOutB.data.isInf) begin
      logAsFloatB.data = logAsFloatB.getInf(1'b0);
    end else if (logOutB.data.isZero) begin
      logAsFloatB.data = logAsFloatB.getZero(1'b0);
    end else begin
      logAsFloatB.data.sign = logOutB.data.sign;
      logAsFloatB.data.exponent = logOutB.data.signedLogExp +
                                  EXP'(FloatDef::getExpBias(EXP, FRAC));
      logAsFloatB.data.fraction = logOutB.data.logFrac;
    end
  end

  Kulisch #(.ACC_NON_FRAC(ACC_NON_FRAC), .ACC_FRAC(ACC_FRAC)) cOutIf();
  logic reset;
  logic clock;

  PaperLogFlatPETop #(.EXP(EXP),
                      .FRAC(FRAC),
                      .LOG_TO_LINEAR_BITS(LOG_TO_LINEAR_BITS))
  pe(.aIn(logAsFloatA.data),
     .bIn(logAsFloatB.data),
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
                 logAsFloatA.print(logAsFloatA.data));
        $display("b %g -> %s", b,
                 logAsFloatB.print(logAsFloatB.data));
        $display("c %s", cOutIf.print(cOutIf.data));
      end
    end

    $display("ACC %p %p", ACC_NON_FRAC, ACC_FRAC);


    disable clockgen;
  end
endmodule
