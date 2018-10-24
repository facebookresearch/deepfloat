// Copyright (c) Facebook, Inc. and its affiliates. All Rights Reserved.
// All rights reserved.
//
// This source code is licensed under the license found in the
// LICENSE file in the root directory of this source tree.


module PositLUT_Sqrt_8_1
  (PositPacked.InputIf in,
   PositPacked.OutputIf out);
  logic [7:0] mem[0:(2**8)-1];

  initial begin
    $readmemh("sqrt8_1.hex", mem);
  end

  PositLUT #(.WIDTH(8),
             .ES(1))
  lut(.*);
endmodule
