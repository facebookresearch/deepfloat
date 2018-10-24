// Copyright (c) Facebook, Inc. and its affiliates. All Rights Reserved.
// All rights reserved.
//
// This source code is licensed under the license found in the
// LICENSE file in the root directory of this source tree.

module PositEncodeTestTemplate #(parameter WIDTH=8,
                                 parameter ES=1)
  ();
  PositPacked #(.WIDTH(WIDTH), .ES(ES)) in();
  PositUnpacked #(.WIDTH(WIDTH), .ES(ES)) out();
  PositPacked #(.WIDTH(WIDTH), .ES(ES)) postEncode();

  integer i;

  PositDecode #(.WIDTH(WIDTH),
                .ES(ES))
  decode(.in(in.InputIf),
         .out(out.OutputIf));

  PositEncode #(.WIDTH(WIDTH),
                .ES(ES))
  encode(.in(out.InputIf),
         .out(postEncode.OutputIf));

  initial begin
    for (i = 0; i < 2 ** WIDTH; ++i) begin
      in.data.bits = i;
      #1;

      // Re-packing after unpacking should produce the same value
      assert(i == postEncode.data.bits);
    end
  end
endmodule

module PositEncodeTest();
  PositEncodeTestTemplate #(.WIDTH(8), .ES(0)) pe8_0();
  PositEncodeTestTemplate #(.WIDTH(8), .ES(1)) pe8_1();
  PositEncodeTestTemplate #(.WIDTH(8), .ES(2)) pe8_2();
  PositEncodeTestTemplate #(.WIDTH(9), .ES(0)) pe9_0();
  PositEncodeTestTemplate #(.WIDTH(9), .ES(1)) pe9_1();
  PositEncodeTestTemplate #(.WIDTH(9), .ES(2)) pe9_2();
endmodule
