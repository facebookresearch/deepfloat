// Copyright (c) Facebook, Inc. and its affiliates. All Rights Reserved.
// All rights reserved.
//
// This source code is licensed under the license found in the
// LICENSE file in the root directory of this source tree.

module GenWaves();
  localparam WIDTH = 8;
  localparam LS = 1;
  localparam LOG_TO_LINEAR_BITS = 5;
  localparam LINEAR_TO_LOG_BITS = 5;
  localparam M = PositDef::getSignedExponentBits(WIDTH, LS);
  localparam F = PositDef::getFractionBits(WIDTH, LS);

  localparam TILE = 32;

  localparam LENGTH = 128;

  logic signed [WIDTH-1:0] aIn[0:TILE-1];
  logic signed [WIDTH-1:0] bIn[0:TILE-1];
  logic signed [WIDTH-1:0] cOut[0:TILE-1];

  logic reset;
  logic clock;

  logic enableMul;
  logic enableShiftOut;

  PaperLogSystolicGrid #(.WIDTH(WIDTH),
                         .LS(LS),
                         .LOG_TO_LINEAR_BITS(LOG_TO_LINEAR_BITS),
                         .LINEAR_TO_LOG_BITS(LINEAR_TO_LOG_BITS),
                         .TILE(TILE))
  pe(.aNextIn(aIn),
     .bNextIn(bIn),
     .cNextOut(cOut),
     .enableMul,
     .enableShiftOut,
     .reset,
     .clock);

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


  integer run;
  integer i;
  integer j;

  shortreal r;

  initial begin : clockgen
    clock <= 1'b0;
    forever #(`CLOCK_PERIOD/2) clock = ~clock;
  end

  task gen_rand(inout integer seed, output logic [7:0] x);
    r = $dist_normal(seed, 0, 10000000) / 10000000.0;
    floatInA.data = $shortrealtobits(r);
    #1;
    x = logCompactA.data;
  endtask

  integer seed;
  integer x;

  initial begin
    $fsdbDumpfile("./design.fsdb");
    $fsdbDumpvars(0, "GenWaves/pe");
    $display("clock period is %p", `CLOCK_PERIOD);
    seed = 1;

    for (run = 0; run < 10; ++run) begin
      reset = 1'b1;
      enableMul = 1'b0;
      enableShiftOut = 1'b0;

      @(posedge clock);
      #1 reset = 1'b0;

      // Initial cycles
      enableMul = 1'b1;

      for (i = 0; i < TILE; ++i) begin
        for (j = 0; j < TILE; ++j) begin
          // Only fill this
          gen_rand(seed, x);
          aIn[j] = j <= i ? WIDTH'(x) : WIDTH'(1'b0);
          gen_rand(seed, x);
          bIn[j] = j <= i ? WIDTH'(x) : WIDTH'(1'b0);
        end

        @(posedge clock);
        // #1      $display("init %p %p %p", i, aIn, bIn);
        // $display("c %p", cOut);
      end

      // Middle runs
      for (i = 0; i < LENGTH - TILE; ++i) begin
        for (j = 0; j < TILE; ++j) begin
          gen_rand(seed, x);
          aIn[j] = WIDTH'(x);
          gen_rand(seed, x);
          bIn[j] = WIDTH'(x);
        end

        @(posedge clock);
        // #1 $display("middle %p %p %p", i, aIn, bIn);
        // $display("c %p", cOut);
      end

      // End runs
      for (i = 0; i < TILE; ++i) begin
        for (j = 0; j < TILE; ++j) begin
          // Only fill this
          gen_rand(seed, x);
          aIn[j] = j <= i ? WIDTH'(8'd0) : WIDTH'(x);
          gen_rand(seed, x);
          bIn[j] = j <= i ? WIDTH'(8'd0) : WIDTH'(x);
        end

        @(posedge clock);
        // #1 $display("end %p %p %p", i, aIn, bIn);
        // $display("c %p", cOut);
      end

      // Run another TILE clocks
      for (i = 0; i < TILE + 1; ++i) begin
        @(posedge clock);
      end

      #1 $display("out row %p: %p", TILE - 1, cOut);

      enableMul = 1'b0;
      enableShiftOut = 1'b1;
      for (i = 2; i <= TILE; ++i) begin
        @(posedge clock);
        #1 $display("out row %p: %p", TILE - i, cOut);
      end

    end

    disable clockgen;
  end
endmodule
