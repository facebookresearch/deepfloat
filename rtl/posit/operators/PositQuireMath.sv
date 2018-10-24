// Copyright (c) Facebook, Inc. and its affiliates. All Rights Reserved.
// All rights reserved.
//
// This source code is licensed under the license found in the
// LICENSE file in the root directory of this source tree.


// Converts a single posit into the posit product form for adding into the quire
module PositQuireConvert_Impl #(parameter WIDTH=8,
                                parameter ES=1,
                                parameter USE_ADJUST=0,
                                parameter ADJUST_SCALE_SIZE=1)
  (PositPacked.InputIf positA,
   input signed [ADJUST_SCALE_SIZE-1:0] adjustScale,
   output logic outIsInf,
   output logic outIsZero,
   output logic outSign,
   output logic [PositDef::getExpProductBits(WIDTH, ES)-1:0] outExp,
   output logic [PositDef::getFracProductBits(WIDTH, ES)-1:0] outFrac,
   input clock,
   input resetn,
   input ivalid,
   input iready,
   output logic ovalid,
   output logic oready);

  initial begin
    assert(positA.WIDTH == WIDTH);
    assert(positA.ES == ES);
  end

  localparam EXP_PROD_BITS = PositDef::getExpProductBits(WIDTH, ES);
  localparam FRAC_PROD_BITS = PositDef::getFracProductBits(WIDTH, ES);

  // 1.
  PositUnpacked #(.WIDTH(WIDTH), .ES(ES)) up();
  PositUnpacked #(.WIDTH(WIDTH), .ES(ES)) upReg();
  logic signed [ADJUST_SCALE_SIZE-1:0] adjustScaleReg;

  PositDecode #(.WIDTH(WIDTH),
                .ES(ES))
  dec(.in(positA),
      .out(up));

  // 2.
  logic [EXP_PROD_BITS-1:0] expWire;
  logic [FRAC_PROD_BITS-1:0] fracWire;

  PositQuireConvert #(.WIDTH(WIDTH),
                      .ES(ES),
                      .USE_ADJUST(USE_ADJUST),
                      .ADJUST_SCALE_SIZE(ADJUST_SCALE_SIZE))
  conv(.in(upReg),
       .adjustScale(adjustScaleReg),
       .outIsInf(),
       .outIsZero(),
       .outSign(),
       .outExp(expWire),
       .outFrac(fracWire));

  always_comb begin
    oready = 1'b1;
    ovalid = 1'b1;
  end

  always_ff @(posedge clock) begin
    if (!resetn) begin
      // 1
      upReg.data <= up.zero(1'b0);
      adjustScaleReg <= ADJUST_SCALE_SIZE'(1'b0);

      // 2
      outIsInf <= 1'b0;
      outIsZero <= 1'b0;
      outSign <= 1'b0;
      outFrac <= FRAC_PROD_BITS'(1'b0);
      outExp <= EXP_PROD_BITS'(1'b0);
    end
    else begin
      // 1
      upReg.data <= up.data;
      adjustScaleReg <= adjustScale;

      // 2
      outIsInf <= upReg.data.isInf;
      outIsZero <= upReg.data.isZero;
      outSign <= upReg.data.sign;
      outFrac <= fracWire;
      outExp <= expWire;
    end
  end
endmodule

module PositQuireMultiply_Impl #(parameter WIDTH=8,
                                 parameter ES=1,
                                 parameter USE_ADJUST=0,
                                 parameter ADJUST_SCALE_SIZE=1)
  (PositPacked.InputIf positA,
   PositPacked.InputIf positB,
   input signed [ADJUST_SCALE_SIZE-1:0] adjustScale,
   output logic abIsInf,
   output logic abIsZero,
   output logic abSign,
   output logic [PositDef::getExpProductBits(WIDTH, ES)-1:0] abExp,
   output logic [PositDef::getFracProductBits(WIDTH, ES)-1:0] abFrac,

   input clock,
   input resetn,
   input ivalid,
   input iready,
   output logic ovalid,
   output logic oready);

  initial begin
    assert(positA.WIDTH == WIDTH);
    assert(positA.ES == ES);
    assert(positB.WIDTH == WIDTH);
    assert(positB.ES == ES);
  end

  localparam EXP_PROD_BITS = PositDef::getExpProductBits(WIDTH, ES);
  localparam FRAC_PROD_BITS = PositDef::getFracProductBits(WIDTH, ES);

  // 1
  PositUnpacked #(.WIDTH(WIDTH), .ES(ES)) upA();
  PositUnpacked #(.WIDTH(WIDTH), .ES(ES)) upB();
  PositUnpacked #(.WIDTH(WIDTH), .ES(ES)) upAReg();
  PositUnpacked #(.WIDTH(WIDTH), .ES(ES)) upBReg();
  logic signed [ADJUST_SCALE_SIZE-1:0] adjustScaleReg;

  // 2
  logic abIsInfWire;
  logic abIsZeroWire;
  logic abSignWire;
  logic [EXP_PROD_BITS-1:0] abExpWire;
  logic [FRAC_PROD_BITS-1:0] abFracWire;

  // 1. Unpack posits
  PositDecode #(.WIDTH(WIDTH), .ES(ES)) decA(.in(positA), .out(upA));
  PositDecode #(.WIDTH(WIDTH), .ES(ES)) decB(.in(positB), .out(upB));

  // 2. Multiply
  PositMultiplyForQuire #(.WIDTH(WIDTH),
                          .ES(ES),
                          .USE_ADJUST(USE_ADJUST),
                          .ADJUST_SCALE_SIZE(ADJUST_SCALE_SIZE))
  pmq(.a(upAReg),
      .b(upBReg),
      .adjustScale(adjustScaleReg),
      .abIsInf(abIsInfWire),
      .abIsZero(abIsZeroWire),
      .abSign(abSignWire),
      .abExp(abExpWire),
      .abFrac(abFracWire));

  always_comb begin
    oready = 1'b1;
    ovalid = 1'b1;
  end

  always_ff @(posedge clock) begin
    if (!resetn) begin
      // 1
      upAReg.data <= upA.zero(1'b0);
      upBReg.data <= upB.zero(1'b0);
      adjustScaleReg <= ADJUST_SCALE_SIZE'(1'b0);

      // 2
      abIsInf <= 1'b0;
      abIsZero <= 1'b0;
      abSign <= 1'b0;
      abFrac <= FRAC_PROD_BITS'(1'b0);
      abExp <= EXP_PROD_BITS'(1'b0);
    end
    else begin
      // 1
      upAReg.data <= upA.data;
      upBReg.data <= upB.data;
      adjustScaleReg <= adjustScale;

      // 2
      abIsInf <= abIsInfWire;
      abIsZero <= abIsZeroWire;
      abSign <= abSignWire;
      abFrac <= abFracWire;
      abExp <= abExpWire;
    end
  end
endmodule

module PositToQuire_Impl #(parameter WIDTH=8,
                           parameter ES=1,
                           parameter OVERFLOW=0,
                           parameter USE_ADJUST=0,
                           parameter ADJUST_SCALE_SIZE=1)
  (PositPacked.InputIf in,
   input signed [ADJUST_SCALE_SIZE-1:0] adjustScale,
   Kulisch.OutputIf out,
   input clock,
   input resetn,
   input ivalid,
   input iready,
   output logic ovalid,
   output logic oready);

  localparam ACC_NON_FRAC = QuireDef::getNonFracBits(WIDTH, ES, OVERFLOW, 0);
  localparam ACC_FRAC = QuireDef::getFracBits(WIDTH, ES, OVERFLOW);

  localparam EXP_PROD_BITS = PositDef::getExpProductBits(WIDTH, ES);
  localparam FRAC_PROD_BITS = PositDef::getFracProductBits(WIDTH, ES);

  initial begin
    assert(in.WIDTH == WIDTH);
    assert(in.ES == ES);

    assert(out.ACC_NON_FRAC == ACC_NON_FRAC);
    assert(out.ACC_FRAC == ACC_FRAC);
  end

  // 1.
  PositUnpacked #(.WIDTH(WIDTH), .ES(ES)) up();
  PositUnpacked #(.WIDTH(WIDTH), .ES(ES)) upReg();
  logic signed [ADJUST_SCALE_SIZE-1:0] adjustScaleReg;

  PositDecode #(.WIDTH(WIDTH),
                .ES(ES))
  dec(.in,
      .out(up));

  // 2.
  logic [EXP_PROD_BITS-1:0] expWire;
  logic [EXP_PROD_BITS-1:0] expReg;
  logic [FRAC_PROD_BITS-1:0] fracWire;
  logic [FRAC_PROD_BITS-1:0] fracReg;
  logic signReg;
  logic infReg;

  PositQuireConvert #(.WIDTH(WIDTH),
                      .ES(ES),
                      .USE_ADJUST(USE_ADJUST),
                      .ADJUST_SCALE_SIZE(ADJUST_SCALE_SIZE))
  conv(.in(upReg),
       .adjustScale(adjustScaleReg),
       .outIsInf(),
       .outIsZero(),
       .outSign(),
       .outExp(expWire),
       .outFrac(fracWire));

  // 3.
  Kulisch #(.ACC_NON_FRAC(ACC_NON_FRAC), .ACC_FRAC(ACC_FRAC)) quireWire();
  Kulisch #(.ACC_NON_FRAC(ACC_NON_FRAC), .ACC_FRAC(ACC_FRAC)) quireZero();

  always_comb begin
    quireZero.data = quireZero.zero();
  end

  QuireAdd #(.WIDTH(WIDTH),
             .ES(ES),
             .OVERFLOW(OVERFLOW))
  qa(.fixedExpIn(expReg),
     .fixedValIn(fracReg),
     .fixedSignIn(signReg),
     .fixedInfIn(infReg),
     .quireIn(quireZero),
     .quireOut(quireWire));

  always_comb begin
    oready = 1'b1;
    ovalid = 1'b1;
  end

  always_ff @(posedge clock) begin
    if (!resetn) begin
      // 1
      upReg.data <= up.zero(1'b0);
      adjustScaleReg <= ADJUST_SCALE_SIZE'(1'b0);

      // 2
      expReg <= EXP_PROD_BITS'(1'b0);
      fracReg <= FRAC_PROD_BITS'(1'b0);
      signReg <= 1'b0;
      infReg <= 1'b0;

      // 3
      out.data <= out.zero();
    end
    else begin
      // 1
      upReg.data <= up.data;
      adjustScaleReg <= adjustScale;

      // 2
      expReg <= expWire;
      fracReg <= fracWire;
      signReg <= upReg.data.sign;
      infReg <= upReg.data.isInf;

      // 3
      out.data <= quireWire.data;
    end
  end
endmodule

module QuirePositAdd_Impl #(parameter WIDTH=8,
                            parameter ES=1,
                            parameter OVERFLOW=0)
  (input abIsInf,
   input abIsZero,
   input abSign,
   Kulisch.InputIf quireIn,
   Kulisch.OutputIf quireOut,
   input [PositDef::getExpProductBits(WIDTH, ES)-1:0] abExp,
   input [PositDef::getFracProductBits(WIDTH, ES)-1:0] abFrac,
   input clock,
   input resetn,
   input ivalid,
   input iready,
   output logic ovalid,
   output logic oready);

  localparam ACC_NON_FRAC = QuireDef::getNonFracBits(WIDTH, ES, OVERFLOW, 0);
  localparam ACC_FRAC = QuireDef::getFracBits(WIDTH, ES, OVERFLOW);

  localparam EXP_PROD_BITS = PositDef::getExpProductBits(WIDTH, ES);
  localparam FRAC_PROD_BITS = PositDef::getFracProductBits(WIDTH, ES);

  initial begin
    assert(quireIn.ACC_NON_FRAC == ACC_NON_FRAC);
    assert(quireIn.ACC_FRAC == ACC_FRAC);

    assert(quireOut.ACC_NON_FRAC == ACC_NON_FRAC);
    assert(quireOut.ACC_FRAC == ACC_FRAC);
  end

  Kulisch #(.ACC_NON_FRAC(ACC_NON_FRAC), .ACC_FRAC(ACC_FRAC)) quireWire();

  QuireAdd #(.WIDTH(WIDTH),
             .ES(ES),
             .OVERFLOW(OVERFLOW))
  qa(.fixedExpIn(abExp),
     .fixedValIn(abFrac),
     .fixedSignIn(abSign),
     .fixedInfIn(abIsInf),
     .quireIn(quireIn),
     .quireOut(quireWire));

  always_comb begin
    oready = 1'b1;
    ovalid = 1'b1;
  end

  always_ff @(posedge clock) begin
    if (!resetn) begin
      // 1
      quireOut.data <= quireOut.zero();
    end else begin
      // 1
      quireOut.data <= quireWire.data;
    end
  end
endmodule

module QuireAdd_Impl #(parameter WIDTH=8,
                       parameter ES=1,
                       parameter OVERFLOW=0)
  (Kulisch.InputIf quireA,
   Kulisch.InputIf quireB,
   Kulisch.OutputIf quireOut,
   input clock,
   input resetn,
   input ivalid,
   input iready,
   output logic ovalid,
   output logic oready);

  localparam ACC_NON_FRAC = QuireDef::getNonFracBits(WIDTH, ES, OVERFLOW, 0);
  localparam ACC_FRAC = QuireDef::getFracBits(WIDTH, ES, OVERFLOW);

  initial begin
    assert(quireA.ACC_NON_FRAC == ACC_NON_FRAC);
    assert(quireA.ACC_FRAC == ACC_FRAC);

    assert(quireB.ACC_NON_FRAC == ACC_NON_FRAC);
    assert(quireB.ACC_FRAC == ACC_FRAC);

    assert(quireOut.ACC_NON_FRAC == ACC_NON_FRAC);
    assert(quireOut.ACC_FRAC == ACC_FRAC);
  end

  Kulisch #(.ACC_NON_FRAC(ACC_NON_FRAC), .ACC_FRAC(ACC_FRAC)) quireWire();

  KulischAccumulatorAdd #(.ACC_NON_FRAC(ACC_NON_FRAC),
                          .ACC_FRAC(ACC_FRAC))
  add(.a(quireA),
      .b(quireB),
      .out(quireWire));

  always_comb begin
    oready = 1'b1;
    ovalid = 1'b1;
  end

  always_ff @(posedge clock) begin
    if (!resetn) begin
      // 1
      quireOut.data <= quireOut.zero();
    end else begin
      // 1
      quireOut.data <= quireWire.data;
    end
  end
endmodule

module QuireToPosit_Impl #(parameter WIDTH=8,
                           parameter ES=1,
                           parameter OVERFLOW=0,
                           parameter TRAILING_BITS=8,
                           parameter USE_ADJUST=0,
                           parameter ADJUST_MUL_SIZE=1)
  (Kulisch.InputIf quireIn,
   input signed [ADJUST_MUL_SIZE-1:0] adjustMul,
   PositPacked.OutputIf positOut,
   input roundStochastic,
   input clock,
   input resetn,
   input ivalid,
   input iready,
   output logic ovalid,
   output logic oready);

  localparam ACC_NON_FRAC = QuireDef::getNonFracBits(WIDTH, ES, OVERFLOW, 0);
  localparam ACC_FRAC = QuireDef::getFracBits(WIDTH, ES, OVERFLOW);

  initial begin
    assert(quireIn.ACC_NON_FRAC == ACC_NON_FRAC);
    assert(quireIn.ACC_FRAC == ACC_FRAC);

    assert(positOut.WIDTH == WIDTH);
    assert(positOut.ES == ES);
  end

  PositUnpacked #(.WIDTH(WIDTH), .ES(ES)) up();
  PositUnpacked #(.WIDTH(WIDTH), .ES(ES)) upReg();
  logic [TRAILING_BITS-1:0] trailingBits;
  logic [TRAILING_BITS-1:0] trailingBitsReg;
  logic stickyBit;
  logic stickyBitReg;
  logic roundStochasticReg;

  // 1. Convert to unpacked posit
  QuireToPosit #(.WIDTH(WIDTH),
                 .ES(ES),
                 .OVERFLOW(OVERFLOW),
                 .TRAILING_BITS(TRAILING_BITS),
                 .USE_ADJUST(USE_ADJUST),
                 .ADJUST_MUL_SIZE(ADJUST_MUL_SIZE))
  qtp(.in(quireIn),
      .adjustMul,
      .out(up),
      .trailingBitsOut(trailingBits),
      .stickyBitOut(stickyBit));

  // 2. Round
  // The output is registered
  PositUnpacked #(.WIDTH(WIDTH), .ES(ES)) upRoundedReg();

  PositRound #(.WIDTH(WIDTH),
               .ES(ES),
               .TRAILING_BITS(TRAILING_BITS))
  pr(.in(upReg),
     .trailingBits(trailingBitsReg),
     .stickyBit(stickyBitReg),
     .roundStochastic(roundStochasticReg),
     .out(upRoundedReg),
     .clock,
     .reset(~resetn));

  // 3
  PositPacked #(.WIDTH(WIDTH), .ES(ES)) p();

  PositEncode #(.WIDTH(WIDTH),
                .ES(ES))
  pe(.in(upRoundedReg),
     .out(p));

  always_comb begin
    oready = 1'b1;
    ovalid = 1'b1;
  end

  always_ff @(posedge clock) begin
    if (!resetn) begin
      // 1
      upReg.data <= up.zero(1'b0);
      trailingBitsReg <= TRAILING_BITS'(1'b0);
      stickyBitReg <= 1'b0;
      roundStochasticReg <= 1'b0;

      // 2
      // (done in PositRound)

      // 3
      positOut.data <= positOut.zeroPacked();
    end
    else begin
      // 1
      upReg.data <= up.data;
      trailingBitsReg <= trailingBits;
      stickyBitReg <= stickyBit;
      roundStochasticReg <= roundStochastic;

      // 2
      // (done in PositRound)

      // 3
      positOut.data <= p.data;
    end
  end
endmodule
