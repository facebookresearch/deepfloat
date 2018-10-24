// Copyright (c) Facebook, Inc. and its affiliates. All Rights Reserved.
// All rights reserved.
//
// This source code is licensed under the license found in the
// LICENSE file in the root directory of this source tree.

module GenWaves();
  localparam EXP = 5;
  localparam FRAC = 10;
  localparam WIDTH = 1 + EXP + FRAC;

  logic reset;
  logic clock;

  Float #(.EXP(8), .FRAC(23)) a32In();
  Float #(.EXP(EXP), .FRAC(FRAC)) aOut();

  FloatContract #(.EXP_IN(8),
                  .FRAC_IN(23),
                  .EXP_OUT(EXP),
                  .FRAC_OUT(FRAC))
  fca(.in(a32In),
      .out(aOut),
      .trailingBitsOut(),
      .stickyBitOut(),
      .isNanOut());

  Float #(.EXP(8), .FRAC(23)) b32In();
  Float #(.EXP(EXP), .FRAC(FRAC)) bOut();

  FloatContract #(.EXP_IN(8),
                  .FRAC_IN(23),
                  .EXP_OUT(EXP),
                  .FRAC_OUT(FRAC))
  fcb(.in(b32In),
      .out(bOut),
      .trailingBitsOut(),
      .stickyBitOut(),
      .isNanOut());

  Float #(.EXP(EXP), .FRAC(FRAC)) cIn();
  Float #(.EXP(8), .FRAC(23)) c32Out();

  FloatExpand #(.EXP_IN(EXP),
                .FRAC_IN(FRAC),
                .EXP_OUT(8),
                .FRAC_OUT(23))
  fec(.in(cIn),
      .out(c32Out),
      .isInf(),
      .isNan(),
      .isZero(),
      .isDenormal());

  PaperFloatPETop #(.EXP(EXP),
                    .FRAC(FRAC))
  pe(.aIn(aOut.data),
     .bIn(bOut.data),
     .cOut(cIn.data),
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

        a32In.data = $shortrealtobits(a);
        b32In.data = $shortrealtobits(b);

        @(posedge clock);
        #1 $display("a %g b %g c %b %g",
                    a, b, cIn.data, $bitstoshortreal(c32Out.data));
      end
    end

    disable clockgen;
  end
endmodule
