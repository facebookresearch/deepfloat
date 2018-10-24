// Copyright (c) Facebook, Inc. and its affiliates. All Rights Reserved.
// All rights reserved.
//
// This source code is licensed under the license found in the
// LICENSE file in the root directory of this source tree.

module LFSR #(parameter N=9)
  (output logic [N-1:0] out,
   input [N-1:0] init,
   input reset,
   input clock);

  initial begin
    // We only support this at the moment
    assert(N <= 33);
  end

  generate
    if (N <= 9) begin : genN

      // LFSR9
      localparam STATE_SIZE = 9;
      logic [STATE_SIZE-1:0] state;

      logic [STATE_SIZE-1:0] initPad;

      ZeroPadRight #(.IN_WIDTH(N), .OUT_WIDTH(STATE_SIZE))
      zpr(.in(init),
          .out(initPad));

      always @(posedge clock) begin
        if (reset) begin
          state <= initPad;
        end else begin
          state[0] <= (state[8] ~^ state[4]);
          state[8:1] <= state[7:0];
        end
      end

      always_comb begin
        out = state[N-1:0];
      end

    end else if (N <= 17) begin

      // LFSR17
      localparam STATE_SIZE = 17;
      logic [STATE_SIZE-1:0] state;

      logic [STATE_SIZE-1:0] initPad;

      ZeroPadRight #(.IN_WIDTH(N), .OUT_WIDTH(STATE_SIZE))
      zpr(.in(init),
          .out(initPad));

      always @(posedge clock) begin
        if (reset) begin
          state <= initPad;
        end else begin
          state[0] <= (state[16] ~^ state[13]);
          state[16:1] <= state[15:0];
        end
      end

      always_comb begin
        out = state[N-1:0];
      end

    end else if (N <= 33) begin

      // LFSR33
      localparam STATE_SIZE = 33;
      logic [STATE_SIZE-1:0] state;

      logic [STATE_SIZE-1:0] initPad;

      ZeroPadRight #(.IN_WIDTH(N), .OUT_WIDTH(STATE_SIZE))
      zpr(.in(init),
          .out(initPad));

      always @(posedge clock) begin
        if (reset) begin
          state <= initPad;
        end else begin
          state[0] <= (state[32] ~^ state[19]);
          state[32:1] <= state[31:0];
        end
      end

      always_comb begin
        out = state[N-1:0];
      end

    end
  endgenerate
endmodule
