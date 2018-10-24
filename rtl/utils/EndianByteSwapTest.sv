// Copyright (c) Facebook, Inc. and its affiliates. All Rights Reserved.
// All rights reserved.
//
// This source code is licensed under the license found in the
// LICENSE file in the root directory of this source tree.

module EndianByteSwapTest();
  logic [47:0] in;
  logic [47:0] out;

  EndianByteSwap #(.BYTES(6)) ebs(.*);

  initial begin
    in = 48'haabbccddeeff;
    #1;
    assert(out == 48'hffeeddccbbaa);
  end
endmodule
