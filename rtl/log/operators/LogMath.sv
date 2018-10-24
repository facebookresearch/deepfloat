// Copyright (c) Facebook, Inc. and its affiliates. All Rights Reserved.
// All rights reserved.
//
// This source code is licensed under the license found in the
// LICENSE file in the root directory of this source tree.


module LogAdd_Impl #(parameter WIDTH=8,
                     parameter LS=1,
                     parameter LOG_TO_LINEAR_BITS=8,
                     parameter LINEAR_TO_LOG_BITS=8,
                     parameter ACC_NON_FRAC =
                     LogDef::getAccNonFracTapered(WIDTH, LS),
                     parameter ACC_FRAC =
                     LogDef::getAccFracTapered(WIDTH, LS),
                     parameter SATURATE_MAX=1)
  (LogNumberCompact.InputIf a,
   LogNumberCompact.InputIf b,
   LogNumberCompact.OutputIf out,
   input subtract,
   input clock,
   input resetn,
   input ivalid,
   input iready,
   output logic ovalid,
   output logic oready);

  localparam M = PositDef::getSignedExponentBits(WIDTH, LS);
  localparam F = PositDef::getFractionBits(WIDTH, LS);

  initial begin
    assert(a.WIDTH == WIDTH);
    assert(a.LS == LS);

    assert(b.WIDTH == WIDTH);
    assert(b.LS == LS);

    assert(out.WIDTH == WIDTH);
    assert(out.LS == LS);
  end

  // 1
  LogNumberUnpacked #(.M(M), .F(F)) upA();
  LogNumberUnpacked #(.M(M), .F(F)) upAReg();

  LogCompactToLogUnpacked #(.WIDTH(WIDTH),
                            .LS(LS))
  lc2luA(.in(a),
         .out(upA));

  LogNumberUnpacked #(.M(M), .F(F)) upB();

  LogCompactToLogUnpacked #(.WIDTH(WIDTH),
                            .LS(LS))
  lc2luB(.in(b),
         .out(upB));

  LogNumberUnpacked #(.M(M), .F(F)) upBSignAdjusted();
  LogNumberUnpacked #(.M(M), .F(F)) upBSignAdjustedReg();

  // Adjust sign on the second argument to turn this into a subtraction
  always_comb begin
    upBSignAdjusted.data = upB.data;
    upBSignAdjusted.data.sign = subtract ? ~upB.data.sign : upB.data.sign;
  end

  // 2
  Kulisch #(.ACC_NON_FRAC(ACC_NON_FRAC), .ACC_FRAC(ACC_FRAC)) linA();
  Kulisch #(.ACC_NON_FRAC(ACC_NON_FRAC), .ACC_FRAC(ACC_FRAC)) linAReg();

  LogToLinearFixed #(.M(M),
                     .F(F),
                     .LOG_TO_LINEAR_BITS(LOG_TO_LINEAR_BITS),
                     .ACC_NON_FRAC(ACC_NON_FRAC),
                     .ACC_FRAC(ACC_FRAC))
  l2linA(.in(upAReg),
         .out(linA));

  Kulisch #(.ACC_NON_FRAC(ACC_NON_FRAC), .ACC_FRAC(ACC_FRAC)) linB();
  Kulisch #(.ACC_NON_FRAC(ACC_NON_FRAC), .ACC_FRAC(ACC_FRAC)) linBReg();

  LogToLinearFixed #(.M(M),
                     .F(F),
                     .LOG_TO_LINEAR_BITS(LOG_TO_LINEAR_BITS),
                     .ACC_NON_FRAC(ACC_NON_FRAC),
                     .ACC_FRAC(ACC_FRAC))
  l2linB(.in(upBSignAdjustedReg),
         .out(linB));

  // 3
  Kulisch #(.ACC_NON_FRAC(ACC_NON_FRAC), .ACC_FRAC(ACC_FRAC)) linAdd();
  Kulisch #(.ACC_NON_FRAC(ACC_NON_FRAC), .ACC_FRAC(ACC_FRAC)) linAddReg();

  KulischAccumulatorAdd #(.ACC_NON_FRAC(ACC_NON_FRAC),
                          .ACC_FRAC(ACC_FRAC))
  add(.a(linAReg),
      .b(linBReg),
      .out(linAdd));

  // 4
  LogNumberUnpacked #(.M(M), .F(F)) upAdd();
  LogNumberUnpacked #(.M(M), .F(F)) upAddReg();

  logic [2:0] logTrailingBits;
  logic [2:0] logTrailingBitsReg;

  LinearFixedToLog #(.ACC_NON_FRAC(ACC_NON_FRAC),
                     .ACC_FRAC(ACC_FRAC),
                     .M(M),
                     .F(F),
                     .LINEAR_TO_LOG_BITS(LINEAR_TO_LOG_BITS),
                     .USE_LOG_TRAILING_BITS(1),
                     .LOG_TRAILING_BITS(3),
                     .USE_ADJUST(0),
                     .SATURATE_MAX(SATURATE_MAX))
  lf2l(.in(linAddReg),
       .adjustExp(),
       .out(upAdd),
       .logTrailingBits);

  // 5
  LogNumberCompact #(.WIDTH(WIDTH), .LS(LS)) outWire();

  LogNumberUnpackedToLogCompact #(.WIDTH(WIDTH),
                                  .LS(LS))
  lu2lc(.in(upAddReg),
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
      upAReg.data <= upAReg.zero();
      upBSignAdjustedReg.data <= upBSignAdjustedReg.zero();

      // 2
      linAReg.data <= linAReg.zero();
      linBReg.data <= linBReg.zero();

      // 3
      linAddReg.data <= linAddReg.zero();

      // 4
      upAddReg.data <= upAddReg.zero();
      logTrailingBitsReg <= 3'b0;

      // 5
      out.data <= out.zero();
    end else begin
      // 1
      upAReg.data <= upA.data;
      upBSignAdjustedReg.data <= upBSignAdjusted.data;

      // 2
      linAReg.data <= linA.data;
      linBReg.data <= linB.data;

      // 3
      linAddReg.data <= linAdd.data;

      // 4
      upAddReg.data <= upAdd.data;
      logTrailingBitsReg <= logTrailingBits;

      // 5
      out.data <= outWire.data;
    end
  end
endmodule

module LogMul_Impl #(parameter WIDTH=8,
                     parameter LS=1)
  (LogNumberCompact.InputIf a,
   LogNumberCompact.InputIf b,
   LogNumberCompact.OutputIf out,
   input clock,
   input resetn,
   input ivalid,
   input iready,
   output logic ovalid,
   output logic oready);

  localparam M = PositDef::getSignedExponentBits(WIDTH, LS);
  localparam F = PositDef::getFractionBits(WIDTH, LS);
  localparam EXTRA_BITS = 3;

  initial begin
    assert(a.WIDTH == WIDTH);
    assert(a.LS == LS);

    assert(b.WIDTH == WIDTH);
    assert(b.LS == LS);

    assert(out.WIDTH == WIDTH);
    assert(out.LS == LS);
  end

  // 1
  LogNumberUnpacked #(.M(M), .F(F)) upA();
  LogNumberUnpacked #(.M(M), .F(F)) upAReg();

  LogCompactToLogUnpacked #(.WIDTH(WIDTH),
                            .LS(LS))
  lc2luA(.in(a),
         .out(upA));

  LogNumberUnpacked #(.M(M), .F(F)) upB();
  LogNumberUnpacked #(.M(M), .F(F)) upBReg();

  LogCompactToLogUnpacked #(.WIDTH(WIDTH),
                            .LS(LS))
  lc2luB(.in(b),
         .out(upB));

  // 2
  LogNumberUnpacked #(.M(M), .F(F)) upOut();
  LogNumberUnpacked #(.M(M), .F(F)) upOutReg();

  LogMultiply #(.M(M),
                .F(F),
                .M_OUT(M))
  mul(.a(upAReg),
      .b(upBReg),
      .c(upOut));

  // 3
  LogNumberCompact #(.WIDTH(WIDTH), .LS(LS)) outWire();

  LogNumberUnpackedToLogCompact #(.WIDTH(WIDTH),
                                  .LS(LS))
  lu2lc(.in(upOutReg),
        // multiplication is exact
        .trailingBits(2'b0),
        .stickyBit(1'b0),
        .out(outWire));

  always_comb begin
    oready = 1'b1;
    ovalid = 1'b1;
  end

  always_ff @(posedge clock) begin
    if (!resetn) begin
      // 1
      upAReg.data <= upAReg.zero();
      upBReg.data <= upBReg.zero();

      // 2
      upOutReg.data <= upOutReg.zero();

      // 3
      out.data <= out.zero();
    end else begin
      // 1
      upAReg.data <= upA.data;
      upBReg.data <= upB.data;

      // 2
      upOutReg.data <= upOut.data;

      // 3
      out.data <= outWire.data;
    end
  end
endmodule
