// Copyright (c) Facebook, Inc. and its affiliates. All Rights Reserved.
// All rights reserved.
//
// This source code is licensed under the license found in the
// LICENSE file in the root directory of this source tree.

module Pow2DeltaLUTTestTemplate #(parameter IN=4,
                                  parameter OUT=5)
  ();

  logic [IN-1:0] in;
  logic [OUT-1:0] deltaOut;
  logic [OUT-1:0] out;

  Pow2DeltaLUT #(.IN(IN),
                 .OUT(OUT))
  lutDelta(.in, .out(deltaOut));

  Pow2LUT #(.IN(IN),
            .OUT(OUT))
  lut(.in, .out(out));

  integer i;
  initial begin
    for (i = 0; i < 2 ** IN; ++i) begin
      in = i;
      #1;
      if (out != deltaOut) begin
        $display("%b %b", out, deltaOut);
        assert(out == deltaOut);
      end
    end
  end
endmodule

module Pow2DeltaLUTTest();
  Pow2DeltaLUTTestTemplate #(.IN(4), .OUT(5)) t1();
  Pow2DeltaLUTTestTemplate #(.IN(4), .OUT(8)) t2();
  Pow2DeltaLUTTestTemplate #(.IN(10), .OUT(11)) t3();
endmodule
