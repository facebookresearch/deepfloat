// Copyright (c) Facebook, Inc. and its affiliates. All Rights Reserved.
// All rights reserved.
//
// This source code is licensed under the license found in the
// LICENSE file in the root directory of this source tree.

module PaperPositPETop #(parameter WIDTH=8,
                         parameter ES=1,
                         parameter OVERFLOW=0,
                         parameter FRAC_REDUCE=0)
   (input logic [PositDef::getUnpackedStructSize(WIDTH, ES)-1:0] aIn,
    input logic [PositDef::getUnpackedStructSize(WIDTH, ES)-1:0] bIn,
    output logic [PositDef::getUnpackedStructSize(WIDTH, ES)-1:0] aOut,
    output logic [PositDef::getUnpackedStructSize(WIDTH, ES)-1:0] bOut,
    output logic [KulischDef::getStructSize(QuireDef::getNonFracBits(WIDTH, ES, OVERFLOW, FRAC_REDUCE),
                                            QuireDef::getFracBits(WIDTH, ES, OVERFLOW))-1:0] cOut,
    input reset,
    input clock);

  localparam ACC_NON_FRAC = QuireDef::getNonFracBits(WIDTH, ES, OVERFLOW, FRAC_REDUCE);
  localparam ACC_FRAC = QuireDef::getFracBits(WIDTH, ES, OVERFLOW);

  // Register inputs for timing
  PositUnpacked #(.WIDTH(WIDTH), .ES(ES)) aInReg();
  PositUnpacked #(.WIDTH(WIDTH), .ES(ES)) bInReg();

  always_ff @(posedge clock) begin
    aInReg.data <= aIn;
    bInReg.data <= bIn;
  end

  PositUnpacked #(.WIDTH(WIDTH), .ES(ES)) aOutIf();
  PositUnpacked #(.WIDTH(WIDTH), .ES(ES)) bOutIf();
  Kulisch #(.ACC_NON_FRAC(ACC_NON_FRAC), .ACC_FRAC(ACC_FRAC)) cOutIf();

  always_comb begin
    cOut = cOutIf.data;
  end

  PaperPositPE #(.WIDTH(WIDTH),
                 .ES(ES),
                 .OVERFLOW(OVERFLOW),
                 .FRAC_REDUCE(FRAC_REDUCE))
  pe(.aIn(aInReg),
     .bIn(bInReg),
     .aOut(aOutIf),
     .bOut(bOutIf),
     .cOut(cOutIf),
     .reset,
     .clock);
endmodule
