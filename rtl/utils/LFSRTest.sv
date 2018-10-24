// Copyright (c) Facebook, Inc. and its affiliates. All Rights Reserved.
// All rights reserved.
//
// This source code is licensed under the license found in the
// LICENSE file in the root directory of this source tree.

module LFSRTestTemplate #(parameter N=9,
                          parameter MAX_CHECK=2**N) ();
  parameter CLOCK_PERIOD = 10;

  bit clock;
  bit reset;

  logic [N-1:0] out;
  logic [N-1:0] init;
  longint i;
  bit seenVals[*];

  LFSR #(.N(N)) lfsr(.*);

  // clock generator
  initial begin : clockgen
    clock <= 1'b0;
    forever #5 clock = ~clock;
  end

  initial begin
    reset = 1;
    init = N'(1'b1);
    @(posedge clock);
    reset = 0;

    seenVals[N'(1'b1)] = 1'b1;

    // We never reach the zero state
    for (i = 0; i < 2 ** N - 2; ++i) begin
      @(posedge clock);

      #1 assert(!seenVals.exists(out));
      seenVals[out] = 1'b1;

      if (i >= MAX_CHECK) begin
        break;
      end
    end

    @(posedge clock);
    // should be back where we started
    if (MAX_CHECK == 2**N) begin
      #1 assert(out == N'(1'b1));
    end

    // Let us exit
    disable clockgen;
    $display("LFSR test %d: stopped at %p", N, $stime);
  end
endmodule

module LFSRTest();
  LFSRTestTemplate #(.N(9)) lfsr9();
  LFSRTestTemplate #(.N(17)) lfsr17();
  LFSRTestTemplate #(.N(33), .MAX_CHECK(2**18)) lfsr33();
endmodule
