// Copyright (c) Facebook, Inc. and its affiliates. All Rights Reserved.
// All rights reserved.
//
// This source code is licensed under the license found in the
// LICENSE file in the root directory of this source tree.

module PaperFloatPE #(parameter EXP=5,
                      parameter FRAC=10)
   (input logic [1+EXP+FRAC-1:0] aIn,
    input logic [1+EXP+FRAC-1:0] bIn,
    input logic [1+EXP+FRAC-1:0] cIn,
    output logic [1+EXP+FRAC-1:0] cOut);

  localparam WIDTH = 1 + EXP + FRAC;

  DW_fp_mac #(.sig_width(FRAC),
              .exp_width(EXP),
//              .ieee_compliance(1))
              .ieee_compliance(0))
  mac(.a(aIn),
      .b(bIn),
      .c(cIn),
      .rnd(3'b000), // r2ne
      .z(cOut),
      .status());
endmodule
