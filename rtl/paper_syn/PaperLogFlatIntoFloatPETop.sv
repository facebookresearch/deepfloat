// Copyright (c) Facebook, Inc. and its affiliates. All Rights Reserved.
// All rights reserved.
//
// This source code is licensed under the license found in the
// LICENSE file in the root directory of this source tree.

module PaperLogFlatIntoFloatPETop #(parameter EXP=8,
                                    parameter FRAC=7,
                                    parameter ACC_EXP=8,
                                    parameter ACC_FRAC=7,
                                    parameter OVERFLOW_DETECTION=0,
                                    parameter LOG_TO_LINEAR_BITS=11)
  (input logic [1+EXP+FRAC-1:0] aIn,
   input logic [1+EXP+FRAC-1:0] bIn,
   output logic [1+ACC_EXP+ACC_FRAC-1:0] cOut,
   input reset,
   input clock);

  localparam INPUT_WIDTH = 1 + EXP + FRAC;
  localparam ACC_WIDTH = 1 + ACC_EXP + ACC_FRAC;

  // Register inputs for timing
  logic [INPUT_WIDTH-1:0] aInReg;
  logic [INPUT_WIDTH-1:0] bInReg;

  Float #(.EXP(ACC_EXP), .FRAC(ACC_FRAC)) cOutNew();
  Float #(.EXP(ACC_EXP), .FRAC(ACC_FRAC)) cOutReg();

  initial begin
    assert($bits(cOut) == $bits(cOutReg.data));
  end

  always_ff @(posedge clock) begin
    if (reset) begin
      aInReg <= INPUT_WIDTH'(1'b0);
      bInReg <= INPUT_WIDTH'(1'b0);
      cOutReg.data <= cOutReg.getZero(1'b0);
    end else begin
      aInReg <= aIn;
      bInReg <= bIn;
      cOutReg.data <= cOutNew.data;
    end
  end

  Float #(.EXP(EXP), .FRAC(FRAC)) aInFloat();
  Float #(.EXP(EXP), .FRAC(FRAC)) bInFloat();

  always_comb begin
    aInFloat.data = aInReg;
    bInFloat.data = bInReg;
  end

  // Expand to full log value
  FloatSigned #(.EXP(EXP), .FRAC(FRAC)) aInFS();
  FloatSigned #(.EXP(EXP), .FRAC(FRAC)) bInFS();

  FloatToFloatSigned #(.EXP(EXP),
                       .FRAC(FRAC),
                       .SIGNED_EXP(EXP),
                       .SIGNED_FRAC(FRAC))
  f2fsa(.in(aInFloat),
        .out(aInFS));

  FloatToFloatSigned #(.EXP(EXP),
                       .FRAC(FRAC),
                       .SIGNED_EXP(EXP),
                       .SIGNED_FRAC(FRAC))
  f2fsb(.in(bInFloat),
        .out(bInFS));

  LogNumberUnpacked #(.M(EXP), .F(FRAC)) aInLog();
  LogNumberUnpacked #(.M(EXP), .F(FRAC)) bInLog();

  always_comb begin
    aInLog.data.sign = aInFS.data.sign;
    aInLog.data.isInf = aInFS.data.isInf;
    aInLog.data.isZero = aInFS.data.isZero;
    aInLog.data.signedLogExp = aInFS.data.exp;
    aInLog.data.logFrac = aInFS.data.frac;

    bInLog.data.sign = bInFS.data.sign;
    bInLog.data.isInf = bInFS.data.isInf;
    bInLog.data.isZero = bInFS.data.isZero;
    bInLog.data.signedLogExp = bInFS.data.exp;
    bInLog.data.logFrac = bInFS.data.frac;
  end

  LogMultiplyAddWithFloat #(.M(EXP),
                            .F(FRAC),
                            .LOG_TO_LINEAR_BITS(LOG_TO_LINEAR_BITS),
                            .ACC_EXP(ACC_EXP),
                            .ACC_FRAC(ACC_FRAC))
  pe(.a(aInLog),
     .b(bInLog),
     .accIn(cOutReg),
     .accOut(cOutNew));

  always_comb begin
    cOut = cOutReg.data;
  end
endmodule
