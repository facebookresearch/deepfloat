// Copyright (c) Facebook, Inc. and its affiliates. All Rights Reserved.
// All rights reserved.
//
// This source code is licensed under the license found in the
// LICENSE file in the root directory of this source tree.

module GenWaves();
  localparam WIDTH = 8;
  localparam ACC = 32;
  localparam TILE = 32;

  localparam LENGTH = 128;

  logic signed [WIDTH-1:0] aIn[0:TILE-1];
  logic signed [WIDTH-1:0] bIn[0:TILE-1];
  logic signed [ACC-1:0] cOut[0:TILE-1];

  logic reset;
  logic clock;

  logic enableMul;
  logic enableShiftOut;

  PaperIntegerSystolicGrid #(.TILE(TILE),
                             .WIDTH(WIDTH),
                             .ACC(ACC))
  pe(.aNextIn(aIn),
     .bNextIn(bIn),
     .cNextOut(cOut),
     .enableMul,
     .enableShiftOut,
     .reset,
     .clock);

  integer run;
  integer i;
  integer j;

  initial begin : clockgen
    clock <= 1'b0;
    forever #(`CLOCK_PERIOD/2) clock = ~clock;
  end

  task gen_rand(inout integer seed, output integer x);
    x = $dist_normal(seed, 0, 64);
    if (x < -128) x = -128;
    if (x > 127) x = 127;
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
