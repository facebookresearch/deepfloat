// Copyright (c) Facebook, Inc. and its affiliates. All Rights Reserved.
// All rights reserved.
//
// This source code is licensed under the license found in the
// LICENSE file in the root directory of this source tree.

// NOTE: I tested this for Arria 10 and this was slower and used more resources
// than my CLZ + then shift left
//
// A FPGA-oriented implementation of clz + shift left that does both at the same
// time, as the bitwise reduction on FPGA LUTs is fairly efficient. The
// theoretical delay would be worse than clz then shift left, log(n)^2 versus 2
// log(n).
//
// (p. 286, Handbook of Floating Point Arithmetic)
module CountLeadingZerosShiftLeft #(parameter WIDTH=8)
  (input [WIDTH-1:0] in,
   output logic [WIDTH-1:0] out,
   output logic [$clog2(WIDTH + 1)-1:0] shift);

  localparam K = $clog2(WIDTH + 1);

  wire [K:0][WIDTH-1:0] val;
  wire [K-1:0] hasLeadingZeros;
  wire [$clog2(WIDTH + 1)-1:0] test;

  assign val[K] = in;

  genvar i;

  generate
    for (i = K - 1; i >= 0; --i) begin : genK
      assign hasLeadingZeros[i] = !(|val[i+1][WIDTH-1-:2**i]);
      assign test[i] = hasLeadingZeros[i];

      if (2 ** i >= WIDTH) begin
        assign val[i] = hasLeadingZeros[i] ? {WIDTH{1'b0}} : val[i+1];
      end
      else begin
        assign val[i] = hasLeadingZeros[i] ?
                        {val[i+1][WIDTH-1-2**i:0], {2**i{1'b0}}} :
                        val[i+1];
      end
    end

    assign shift = test > WIDTH ? K'(WIDTH) : test;
    assign out = val[0];
  endgenerate
endmodule
