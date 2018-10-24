// Copyright (c) Facebook, Inc. and its affiliates. All Rights Reserved.
// All rights reserved.
//
// This source code is licensed under the license found in the
// LICENSE file in the root directory of this source tree.

module Log2DeltaLUTTestTemplate #(parameter IN=11,
                                  parameter OUT=10)
  ();

  logic [IN-1:0] in;
  logic [OUT:0] deltaOut;
  logic [OUT:0] out;

  Log2DeltaLUT #(.IN(IN),
                 .OUT(OUT))
  lutDelta(.in, .out(deltaOut));

  Log2LUT #(.IN(IN),
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

module Log2DeltaLUTTest();
  Log2DeltaLUTTestTemplate #(.IN(5), .OUT(7)) t1();
  Log2DeltaLUTTestTemplate #(.IN(8), .OUT(7)) t2();
  Log2DeltaLUTTestTemplate #(.IN(11), .OUT(10)) t3();
endmodule
