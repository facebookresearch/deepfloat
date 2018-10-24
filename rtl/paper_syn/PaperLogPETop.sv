// Copyright (c) Facebook, Inc. and its affiliates. All Rights Reserved.
// All rights reserved.
//
// This source code is licensed under the license found in the
// LICENSE file in the root directory of this source tree.

module PaperLogPETop #(parameter WIDTH=8,
                       parameter LS=1,
                       parameter OVERFLOW_DETECTION=0,
                       parameter NON_FRAC_REDUCE=0,
                       parameter LOG_TO_LINEAR_BITS=5)
  (input logic [PositDef::getSignedExponentBits(WIDTH, LS) +
                PositDef::getFractionBits(WIDTH, LS) +
                3-1:0] aIn,
   input logic [PositDef::getSignedExponentBits(WIDTH, LS) +
                PositDef::getFractionBits(WIDTH, LS) +
                3-1:0] bIn,
   output logic [KulischDef::getStructSize(
                   LogDef::getAccNonFracTapered(WIDTH, LS) - NON_FRAC_REDUCE,
                   LogDef::getAccFracTapered(WIDTH, LS))-1:0] cOut,
   input reset,
   input clock);

  localparam ACC_NON_FRAC = LogDef::getAccNonFracTapered(WIDTH, LS);
  localparam ACC_FRAC = LogDef::getAccFracTapered(WIDTH, LS);

  localparam M = PositDef::getSignedExponentBits(WIDTH, LS);
  localparam F = PositDef::getFractionBits(WIDTH, LS);

  // Register inputs for timing
  LogNumberUnpacked #(.M(M), .F(F)) aInReg();
  LogNumberUnpacked #(.M(M), .F(F)) bInReg();

  Kulisch #(.ACC_NON_FRAC(ACC_NON_FRAC), .ACC_FRAC(ACC_FRAC)) cOutNew();
  Kulisch #(.ACC_NON_FRAC(ACC_NON_FRAC), .ACC_FRAC(ACC_FRAC)) cOutReg();

  initial begin
    assert($bits(aIn) == $bits(aInReg.data));
    assert($bits(bIn) == $bits(bInReg.data));
    assert($bits(cOut) == $bits(cOutReg.data));
  end

  always_ff @(posedge clock) begin
    if (reset) begin
      aInReg.data <= aInReg.zero();
      bInReg.data <= bInReg.zero();
      cOutReg.data <= cOutReg.zero();
    end else begin
      aInReg.data <= aIn;
      bInReg.data <= bIn;
      cOutReg.data <= cOutNew.data;
    end
  end

  PaperLogPE #(.M(M),
               .F(F),
               .ACC_NON_FRAC(ACC_NON_FRAC),
               .ACC_FRAC(ACC_FRAC),
               .OVERFLOW_DETECTION(OVERFLOW_DETECTION),
               .NON_FRAC_REDUCE(NON_FRAC_REDUCE),
               .LOG_TO_LINEAR_BITS(LOG_TO_LINEAR_BITS))
  pe(.aIn(aInReg),
     .bIn(bInReg),
     .cIn(cOutReg),
     .cOut(cOutNew));

  always_comb begin
    cOut = cOutReg.data;
  end
endmodule

module PaperLogSystolicPE #(parameter WIDTH=8,
                            parameter LS=1,
                            parameter OVERFLOW_DETECTION=0,
                            parameter NON_FRAC_REDUCE=0,
                            parameter LOG_TO_LINEAR_BITS=5)
  (LogNumberUnpacked.InputIf aIn,
   LogNumberUnpacked.InputIf bIn,
   Kulisch.InputIf cIn,
   LogNumberUnpacked.OutputIf aOut,
   LogNumberUnpacked.OutputIf bOut,
   Kulisch.OutputIf cOut,
   input enableMul,
   input enableShiftOut,
   input reset,
   input clock);

  localparam ACC_NON_FRAC = LogDef::getAccNonFracTapered(WIDTH, LS) - NON_FRAC_REDUCE;
  localparam ACC_FRAC = LogDef::getAccFracTapered(WIDTH, LS);

  localparam M = PositDef::getSignedExponentBits(WIDTH, LS);
  localparam F = PositDef::getFractionBits(WIDTH, LS);

  initial begin
    assert(aIn.M == M);
    assert(aIn.F == F);
    assert(bIn.M == M);
    assert(bIn.F == F);
    assert(aOut.M == M);
    assert(aOut.F == F);
    assert(bOut.M == M);
    assert(bOut.F == F);

    assert(cIn.ACC_NON_FRAC == ACC_NON_FRAC);
    assert(cIn.ACC_FRAC == ACC_FRAC);
    assert(cOut.ACC_NON_FRAC == ACC_NON_FRAC);
    assert(cOut.ACC_FRAC == ACC_FRAC);
  end

  LogNumberUnpacked #(.M(M), .F(F)) aOutReg();
  LogNumberUnpacked #(.M(M), .F(F)) bOutReg();

  Kulisch #(.ACC_NON_FRAC(ACC_NON_FRAC), .ACC_FRAC(ACC_FRAC)) cOutNew();
  Kulisch #(.ACC_NON_FRAC(ACC_NON_FRAC), .ACC_FRAC(ACC_FRAC)) cOutReg();

  always_ff @(posedge clock) begin
    if (reset) begin
      aOutReg.data <= aOutReg.zero();
      bOutReg.data <= bOutReg.zero();
      cOutReg.data <= cOutReg.zero();
    end else if (enableMul) begin
      aOutReg.data <= aIn.data;
      bOutReg.data <= bIn.data;
      cOutReg.data <= cOutNew.data;
    end else if (enableShiftOut) begin
      cOutReg.data <= cIn.data;
    end
  end

  PaperLogPE #(.M(M),
               .F(F),
               .ACC_NON_FRAC(ACC_NON_FRAC),
               .ACC_FRAC(ACC_FRAC),
               .OVERFLOW_DETECTION(OVERFLOW_DETECTION),
               .NON_FRAC_REDUCE(NON_FRAC_REDUCE),
               .LOG_TO_LINEAR_BITS(LOG_TO_LINEAR_BITS))
  pe(.aIn(aIn),
     .bIn(bIn),
     .cIn(cOutReg),
     .cOut(cOutNew));

  always_comb begin
    aOut.data = aOutReg.data;
    bOut.data = bOutReg.data;
    cOut.data = cOutReg.data;
  end
endmodule
