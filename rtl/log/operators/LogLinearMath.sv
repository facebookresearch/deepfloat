// Copyright (c) Facebook, Inc. and its affiliates. All Rights Reserved.
// All rights reserved.
//
// This source code is licensed under the license found in the
// LICENSE file in the root directory of this source tree.


module LogToLinear_Impl #(parameter WIDTH=8,
                          parameter LS=1,
                          parameter LOG_TO_LINEAR_BITS=8,
                          parameter ACC_NON_FRAC =
                          LogDef::getAccNonFracTapered(WIDTH, LS),
                          parameter ACC_FRAC =
                          LogDef::getAccFracTapered(WIDTH, LS))
  (LogNumberCompact.InputIf in,
   Kulisch.OutputIf out,
   input clock,
   input resetn,
   input ivalid,
   input iready,
   output logic ovalid,
   output logic oready);

  localparam M = PositDef::getSignedExponentBits(WIDTH, LS);
  localparam F = PositDef::getFractionBits(WIDTH, LS);

  initial begin
    assert(in.WIDTH == WIDTH);
    assert(in.LS == LS);

    assert(out.ACC_NON_FRAC == ACC_NON_FRAC);
    assert(out.ACC_FRAC == ACC_FRAC);
  end

  // 1
  LogNumberUnpacked #(.M(M), .F(F)) inUnpacked();
  LogNumberUnpacked #(.M(M), .F(F)) inUnpackedReg();

  LogCompactToLogUnpacked #(.WIDTH(WIDTH),
                            .LS(LS))
  lc2lu(.in(in),
        .out(inUnpacked));

  // 2
  Kulisch #(.ACC_NON_FRAC(ACC_NON_FRAC), .ACC_FRAC(ACC_FRAC)) outWire();

  LogToLinearFixed #(.M(M),
                     .F(F),
                     .LOG_TO_LINEAR_BITS(LOG_TO_LINEAR_BITS),
                     .ACC_NON_FRAC(ACC_NON_FRAC),
                     .ACC_FRAC(ACC_FRAC))
  l2lf(.in(inUnpackedReg),
       .out(outWire));

  always_comb begin
    oready = 1'b1;
    ovalid = 1'b1;
  end

  always_ff @(posedge clock) begin
    if (!resetn) begin
      // 1
      inUnpackedReg.data <= inUnpackedReg.zero();

      // 2
      out.data <= out.zero();
    end else begin
      // 1
      inUnpackedReg.data <= inUnpacked.data;

      // 2
      out.data <= outWire.data;
    end
  end
endmodule

module LinearAdd_Impl #(parameter ACC_NON_FRAC=10,
                        parameter ACC_FRAC=10)
  (Kulisch.InputIf linA,
   Kulisch.InputIf linB,
   Kulisch.OutputIf linOut,
   input clock,
   input resetn,
   input ivalid,
   input iready,
   output logic ovalid,
   output logic oready);

  initial begin
    assert(linA.ACC_NON_FRAC == ACC_NON_FRAC);
    assert(linA.ACC_FRAC == ACC_FRAC);

    assert(linB.ACC_NON_FRAC == ACC_NON_FRAC);
    assert(linB.ACC_FRAC == ACC_FRAC);

    assert(linOut.ACC_NON_FRAC == ACC_NON_FRAC);
    assert(linOut.ACC_FRAC == ACC_FRAC);
  end

  Kulisch #(.ACC_NON_FRAC(ACC_NON_FRAC), .ACC_FRAC(ACC_FRAC)) linOutWire();

  KulischAccumulatorAdd #(.ACC_NON_FRAC(ACC_NON_FRAC),
                          .ACC_FRAC(ACC_FRAC))
  add(.a(linA),
      .b(linB),
      .out(linOutWire));

  always_comb begin
    oready = 1'b1;
    ovalid = 1'b1;
  end

  always_ff @(posedge clock) begin
    if (!resetn) begin
      // 1
      linOut.data <= linOut.zero();
    end else begin
      // 1
      linOut.data <= linOutWire.data;
    end
  end
endmodule

module LinearToLog_Impl #(parameter WIDTH=8,
                          parameter LS=1,
                          parameter LINEAR_TO_LOG_BITS=8,
                          parameter USE_ADJUST=0,
                          parameter ADJUST_EXP_SIZE=1,
                          parameter SATURATE_MAX=1,
                          parameter ACC_NON_FRAC =
                          LogDef::getAccNonFracTapered(WIDTH, LS),
                          parameter ACC_FRAC =
                          LogDef::getAccFracTapered(WIDTH, LS))
  (Kulisch.InputIf in,
   input signed [ADJUST_EXP_SIZE-1:0] adjustExp,
   LogNumberCompact.OutputIf out,
   input clock,
   input resetn,
   input ivalid,
   input iready,
   output logic ovalid,
   output logic oready);

  localparam M = PositDef::getSignedExponentBits(WIDTH, LS);
  localparam F = PositDef::getFractionBits(WIDTH, LS);

  initial begin
    assert(in.ACC_NON_FRAC == ACC_NON_FRAC);
    assert(in.ACC_FRAC == ACC_FRAC);

    assert(out.WIDTH == WIDTH);
    assert(out.LS == LS);
  end

  // 1
  LogNumberUnpacked #(.M(M), .F(F)) up();
  LogNumberUnpacked #(.M(M), .F(F)) upReg();

  logic [2:0] logTrailingBits;
  logic [2:0] logTrailingBitsReg;

  LinearFixedToLog #(.ACC_NON_FRAC(ACC_NON_FRAC),
                     .ACC_FRAC(ACC_FRAC),
                     .M(M),
                     .F(F),
                     .LINEAR_TO_LOG_BITS(LINEAR_TO_LOG_BITS),
                     .USE_LOG_TRAILING_BITS(1),
                     .LOG_TRAILING_BITS(3),
                     .USE_ADJUST(USE_ADJUST),
                     .ADJUST_EXP_SIZE(ADJUST_EXP_SIZE),
                     .SATURATE_MAX(SATURATE_MAX))
  lf2l(.in(in),
       .adjustExp(adjustExp),
       .out(up),
       .logTrailingBits);

  // 2
  LogNumberCompact #(.WIDTH(WIDTH), .LS(LS)) outWire();

  LogNumberUnpackedToLogCompact #(.WIDTH(WIDTH),
                                  .LS(LS))
  lu2lc(.in(upReg),
        .trailingBits(logTrailingBitsReg[2:1]),
        .stickyBit(logTrailingBitsReg[0]),
        .out(outWire));

  always_comb begin
    oready = 1'b1;
    ovalid = 1'b1;
  end

  always_ff @(posedge clock) begin
    if (!resetn) begin
      // 1
      upReg.data <= upReg.zero();
      logTrailingBitsReg <= 3'b0;

      // 2
      out.data <= out.zero();
    end else begin
      // 1
      upReg.data <= up.data;
      logTrailingBitsReg <= logTrailingBits;

      // 2
      out.data <= outWire.data;
    end
  end
endmodule

module LogMultiplyToLinear_Impl #(parameter WIDTH=8,
                                  parameter LS=1,
                                  parameter LOG_TO_LINEAR_BITS=8,
                                  parameter ACC_NON_FRAC =
                                  LogDef::getAccNonFracTapered(WIDTH, LS),
                                  parameter ACC_FRAC =
                                  LogDef::getAccFracTapered(WIDTH, LS))
  (LogNumberCompact.InputIf inA,
   LogNumberCompact.InputIf inB,
   Kulisch.OutputIf out,
   input clock,
   input resetn,
   input ivalid,
   input iready,
   output logic ovalid,
   output logic oready);

  localparam M = PositDef::getSignedExponentBits(WIDTH, LS);
  localparam F = PositDef::getFractionBits(WIDTH, LS);

  initial begin
    assert(inA.WIDTH == WIDTH);
    assert(inA.LS == LS);
    assert(inB.WIDTH == WIDTH);
    assert(inB.LS == LS);

    assert(out.ACC_NON_FRAC == ACC_NON_FRAC);
    assert(out.ACC_FRAC == ACC_FRAC);
  end

  // 1
  LogNumberUnpacked #(.M(M), .F(F)) inAUnpacked();

  LogCompactToLogUnpacked #(.WIDTH(WIDTH),
                            .LS(LS))
  lc2luA(.in(inA),
         .out(inAUnpacked));

  LogNumberUnpacked #(.M(M), .F(F)) inBUnpacked();

  LogCompactToLogUnpacked #(.WIDTH(WIDTH),
                            .LS(LS))
  lc2luB(.in(inB),
         .out(inBUnpacked));

  LogNumberUnpacked #(.M(M+1), .F(F)) product();
  LogNumberUnpacked #(.M(M+1), .F(F)) productReg();

  LogMultiply #(.M(M),
                .F(F),
                .M_OUT(M+1))
  mul(.a(inAUnpacked),
      .b(inBUnpacked),
      .c(product));

  // 2
  Kulisch #(.ACC_NON_FRAC(ACC_NON_FRAC), .ACC_FRAC(ACC_FRAC)) outWire();

  LogToLinearFixed #(.M(M+1),
                     .F(F),
                     .LOG_TO_LINEAR_BITS(LOG_TO_LINEAR_BITS),
                     .ACC_NON_FRAC(ACC_NON_FRAC),
                     .ACC_FRAC(ACC_FRAC))
  l2lf(.in(productReg),
       .out(outWire));

  always_comb begin
    oready = 1'b1;
    ovalid = 1'b1;
  end

  always_ff @(posedge clock) begin
    if (!resetn) begin
      // 1
      productReg.data <= productReg.zero();

      // 2
      out.data <= out.zero();
    end else begin
      // 1
      productReg.data <= product.data;

      // 2
      out.data <= outWire.data;
    end
  end
endmodule
