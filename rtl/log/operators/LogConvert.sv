// Copyright (c) Facebook, Inc. and its affiliates. All Rights Reserved.
// All rights reserved.
//
// This source code is licensed under the license found in the
// LICENSE file in the root directory of this source tree.


module LogToFloat_Impl #(parameter WIDTH=8,
                         parameter LS=1)
  (LogNumberCompact.InputIf vIn,
   output logic [31:0] floatOut,
   input clock,
   input resetn,
   input ivalid,
   input iready,
   output logic ovalid,
   output logic oready);

  localparam FLOAT_EXP = 8;
  localparam FLOAT_FRAC = 23;
  localparam M = PositDef::getSignedExponentBits(WIDTH, LS);
  localparam F = PositDef::getFractionBits(WIDTH, LS);

  initial begin
    assert($bits(floatOut) == 1 + FLOAT_EXP + FLOAT_FRAC);
    assert(vIn.WIDTH == WIDTH);
    assert(vIn.LS == LS);
  end

  // 1
  LogNumberUnpacked #(.M(M), .F(F)) logIn();
  LogNumberUnpacked #(.M(M), .F(F)) logInReg();

  LogCompactToLogUnpacked #(.WIDTH(WIDTH),
                            .LS(LS))
  lc2lu(.in(vIn),
        .out(logIn));

  // 2
  Float #(.EXP(8), .FRAC(23)) out();

  LogToFloat #(.M(M),
               .F(F),
               .LOG_TO_LINEAR_BITS(CONFIG_LOG_TO_LINEAR_BITS),
               .EXP(8),
               .FRAC(23))
  l2f(.in(logInReg),
      .out(out));

  always_comb begin
    oready = 1'b1;
    ovalid = 1'b1;
  end

  always_ff @(posedge clock) begin
    if (!resetn) begin
      // 1
      logInReg.data <= logInReg.zero();

      // 2
      floatOut <= out.getZero(1'b0);
    end else begin
      // 1
      logInReg.data <= logIn.data;

      // 2
      floatOut <= out.data;
    end
  end
endmodule

module FloatToLog_Impl #(parameter WIDTH=8,
                         parameter LS=1)
  (input [31:0] floatIn,
   LogNumberCompact.OutputIf vOut,
   input clock,
   input resetn,
   input ivalid,
   input iready,
   output logic ovalid,
   output logic oready);

  localparam FLOAT_EXP = 8;
  localparam FLOAT_FRAC = 23;
  localparam M = PositDef::getSignedExponentBits(WIDTH, LS);
  localparam F = PositDef::getFractionBits(WIDTH, LS);

  initial begin
    assert(vOut.WIDTH == WIDTH);
    assert(vOut.LS == LS);
    assert($bits(floatIn) == 1 + FLOAT_EXP + FLOAT_FRAC);
  end

  // 1
  Float #(.EXP(8), .FRAC(23)) floatInIf();

  always_comb begin
    floatInIf.data = floatIn;
  end

  LogNumberUnpacked #(.M(M), .F(F)) logUnpacked();
  LogNumberUnpacked #(.M(M), .F(F)) logUnpackedReg();
  logic [2:0] logTrailingBits;
  logic [2:0] logTrailingBitsReg;

  FloatToLog #(.EXP(8),
               .FRAC(23),
               .LINEAR_TO_LOG_BITS(CONFIG_LINEAR_TO_LOG_BITS),
               .M(M),
               .F(F),
               .USE_LOG_TRAILING_BITS(1),
               .LOG_TRAILING_BITS(3),
               .SATURATE_MAX(1))
  f2l(.in(floatInIf),
      .out(logUnpacked),
      .logTrailingBits);

  // 2
  LogNumberCompact #(.WIDTH(WIDTH), .LS(LS)) logCompact();

  LogNumberUnpackedToLogCompact #(.WIDTH(WIDTH),
                                  .LS(LS))
  lu2lc(.in(logUnpackedReg),
        .trailingBits(logTrailingBitsReg[2:1]),
        .stickyBit(logTrailingBitsReg[0]),
        .out(logCompact));

  always_ff @(posedge clock) begin
    if (!resetn) begin
      // 1
      logUnpackedReg.data <= logUnpackedReg.zero();
      logTrailingBitsReg <= 3'b0;

      // 2
      vOut.data <= vOut.zero();
    end else begin
      // 1
      logUnpackedReg.data <= logUnpacked.data;
      logTrailingBitsReg <= logTrailingBits;

      // 2
      vOut.data <= logCompact.data;
    end
  end
endmodule
