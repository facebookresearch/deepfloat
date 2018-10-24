// Copyright (c) Facebook, Inc. and its affiliates. All Rights Reserved.
// All rights reserved.
//
// This source code is licensed under the license found in the
// LICENSE file in the root directory of this source tree.

module GenWaves();
  localparam WIDTH = 8;
  localparam ACC = 32;

  logic signed [WIDTH-1:0] aIn;
  logic signed [WIDTH-1:0] bIn;
  logic signed [ACC-1:0] cOut;

  logic reset;
  logic clock;

  PaperIntegerPETop #(.WIDTH(WIDTH),
                      .ACC(ACC))
  pe(.aIn,
     .bIn,
     .aOut(),
     .bOut(),
     .cOut,
     .reset,
     .clock);

  integer i;
  integer j;

  integer a;
  integer b;

  task gen_rand(inout integer seed, output integer x);
    x = $dist_normal(seed, 0, 64);
    if (x < -128) x = -128;
    if (x > 127) x = 127;
  endtask

  integer seed;
  integer x;

  initial begin : clockgen
    clock <= 1'b0;
    forever #(`CLOCK_PERIOD/2) clock = ~clock;
  end

  initial begin
    $fsdbDumpfile("./design.fsdb");
    $fsdbDumpvars(0, "GenWaves/pe");
    $display("clock period is %p", `CLOCK_PERIOD);
    seed = 1;

    for (i = 0; i < 10; ++i) begin
      reset = 1'b1;
      @(posedge clock);
      #1 reset = 1'b0;

      for (j = 0; j < 128; ++j) begin
        gen_rand(seed, x);
        aIn = WIDTH'(x);
        gen_rand(seed, x);
        bIn = WIDTH'(x);

        @(posedge clock);
        #1;
        $display("%p", cOut);
      end
    end

    disable clockgen;
  end
endmodule
