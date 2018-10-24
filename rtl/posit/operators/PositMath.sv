// Copyright (c) Facebook, Inc. and its affiliates. All Rights Reserved.
// All rights reserved.
//
// This source code is licensed under the license found in the
// LICENSE file in the root directory of this source tree.


module PositAdd_Impl #(parameter WIDTH=8,
                       parameter ES=1,
                       parameter TRAILING_BITS=8)
  (PositPacked.InputIf positA,
   PositPacked.InputIf positB,
   PositPacked.OutputIf positOut,
   input subtract,
   input roundStochastic,
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
    assert(positOut.WIDTH == WIDTH);
    assert(positOut.ES == ES);
  end

  // 1. Unpack posits
  PositUnpacked #(.WIDTH(WIDTH), .ES(ES)) upA();
  PositUnpacked #(.WIDTH(WIDTH), .ES(ES)) upAReg();
  PositUnpacked #(.WIDTH(WIDTH), .ES(ES)) upB();
  PositUnpacked #(.WIDTH(WIDTH), .ES(ES)) upBReg();
  logic subtractReg;
  logic roundStochastic1Reg;

  PositDecode #(.WIDTH(WIDTH),
                .ES(ES))
  decA(.in(positA),
       .out(upA));

  PositDecode #(.WIDTH(WIDTH),
                .ES(ES))
  decB(.in(positB),
       .out(upB));

  // 2. Add
  PositUnpacked #(.WIDTH(WIDTH), .ES(ES)) upOutUnrounded();
  PositUnpacked #(.WIDTH(WIDTH), .ES(ES)) upOutUnroundedReg();
  logic [TRAILING_BITS-1:0] trailingBits;
  logic [TRAILING_BITS-1:0] trailingBitsReg;
  logic stickyBit;
  logic stickyBitReg;
  logic roundStochastic2Reg;

  PositAdd #(.WIDTH(WIDTH),
             .ES(ES),
             .TRAILING_BITS(TRAILING_BITS))
  add(.a(upAReg),
      .b(upBReg),
      .out(upOutUnrounded),
      .trailingBits,
      .stickyBit,
      .subtract(subtractReg));

  // 3. Round result
  // The output is registered
  PositUnpacked #(.WIDTH(WIDTH), .ES(ES)) upOutRoundedReg();

  PositRound #(.WIDTH(WIDTH),
               .ES(ES),
               .TRAILING_BITS(TRAILING_BITS))
  pr(.in(upOutUnroundedReg),
     .trailingBits(trailingBitsReg),
     .stickyBit(stickyBitReg),
     .roundStochastic(roundStochastic2Reg),
     .out(upOutRoundedReg),
     .clock,
     .reset(~resetn));

  // 4. Pack result
  PositPacked #(.WIDTH(WIDTH), .ES(ES)) pOutRounded();

  PositEncode #(.WIDTH(WIDTH),
                .ES(ES))
  pe(.in(upOutRoundedReg),
     .out(pOutRounded));

  always_comb begin
    oready = 1'b1;
    ovalid = 1'b1;
  end

  always_ff @(posedge clock) begin
    if (!resetn) begin
      // 1
      upAReg.data <= upA.zero(1'b0);
      upBReg.data <= upB.zero(1'b0);
      subtractReg <= 1'b0;
      roundStochastic1Reg <= 1'b0;

      // 2
      upOutUnroundedReg.data <= upOutUnrounded.zero(1'b0);
      trailingBitsReg <= TRAILING_BITS'(1'b0);
      stickyBitReg <= 1'b0;
      roundStochastic2Reg <= 1'b0;

      // 3
      // (done in PositRound)

      // 4
      positOut.data <= positOut.zeroPacked();
    end
    else begin
      // 1
      upAReg.data <= upA.data;
      upBReg.data <= upB.data;
      subtractReg <= subtract;
      roundStochastic1Reg <= roundStochastic;

      // 2
      upOutUnroundedReg.data <= upOutUnrounded.data;
      trailingBitsReg <= trailingBits;
      stickyBitReg <= stickyBit;
      roundStochastic2Reg <= roundStochastic1Reg;

      // 3
      // (done in PositRound)

      // 4
      positOut.data <= pOutRounded.data;
    end
  end
endmodule

module PositMul_Impl #(parameter WIDTH=8,
                       parameter ES=1,
                       parameter TRAILING_BITS=8)
  (PositPacked.InputIf positA,
   PositPacked.InputIf positB,
   PositPacked.OutputIf positOut,
   input roundStochastic,
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
    assert(positOut.WIDTH == WIDTH);
    assert(positOut.ES == ES);
  end

  // 1. Unpack posits
  PositUnpacked #(.WIDTH(WIDTH), .ES(ES)) upA();
  PositUnpacked #(.WIDTH(WIDTH), .ES(ES)) upAReg();
  PositUnpacked #(.WIDTH(WIDTH), .ES(ES)) upB();
  PositUnpacked #(.WIDTH(WIDTH), .ES(ES)) upBReg();
  logic roundStochastic1Reg;

  PositDecode #(.WIDTH(WIDTH),
                .ES(ES))
  decA(.in(positA),
       .out(upA));

  PositDecode #(.WIDTH(WIDTH),
                .ES(ES))
  decB(.in(positB),
       .out(upB));

  // 2. Add
  PositUnpacked #(.WIDTH(WIDTH), .ES(ES)) upOutUnrounded();
  PositUnpacked #(.WIDTH(WIDTH), .ES(ES)) upOutUnroundedReg();
  logic [TRAILING_BITS-1:0] trailingBits;
  logic [TRAILING_BITS-1:0] trailingBitsReg;
  logic stickyBit;
  logic stickyBitReg;
  logic roundStochastic2Reg;

  PositMultiply #(.WIDTH(WIDTH),
                  .ES(ES),
                  .TRAILING_BITS(TRAILING_BITS))
  add(.a(upAReg),
      .b(upBReg),
      .out(upOutUnrounded),
      .trailingBits,
      .stickyBit);

  // 3. Round result
  // The output is registered
  PositUnpacked #(.WIDTH(WIDTH), .ES(ES)) upOutRoundedReg();

  PositRound #(.WIDTH(WIDTH),
               .ES(ES),
               .TRAILING_BITS(TRAILING_BITS))
  pr(.in(upOutUnroundedReg),
     .trailingBits(trailingBitsReg),
     .stickyBit(stickyBitReg),
     .roundStochastic(roundStochastic2Reg),
     .out(upOutRoundedReg),
     .clock,
     .reset(~resetn));

  // 4. Pack result
  PositPacked #(.WIDTH(WIDTH), .ES(ES)) pOutRounded();

  PositEncode #(.WIDTH(WIDTH),
                .ES(ES))
  pe(.in(upOutRoundedReg),
     .out(pOutRounded));

  always_comb begin
    oready = 1'b1;
    ovalid = 1'b1;
  end

  always_ff @(posedge clock) begin
    if (!resetn) begin
      // 1
      upAReg.data <= upA.zero(1'b0);
      upBReg.data <= upB.zero(1'b0);
      roundStochastic1Reg <= 1'b0;

      // 2
      upOutUnroundedReg.data <= upOutUnrounded.zero(1'b0);
      trailingBitsReg <= TRAILING_BITS'(1'b0);
      stickyBitReg <= 1'b0;
      roundStochastic2Reg <= 1'b0;

      // 3
      // (done in PositRound)

      // 4
      positOut.data <= positOut.zeroPacked();
    end
    else begin
      // 1
      upAReg.data <= upA.data;
      upBReg.data <= upB.data;
      roundStochastic1Reg <= roundStochastic;

      // 2
      upOutUnroundedReg.data <= upOutUnrounded.data;
      trailingBitsReg <= trailingBits;
      stickyBitReg <= stickyBit;
      roundStochastic2Reg <= roundStochastic1Reg;

      // 3
      // (done in PositRound)

      // 4
      positOut.data <= pOutRounded.data;
    end
  end
endmodule

module PositDiv_Impl #(parameter WIDTH=8,
                       parameter ES=1)
  (PositPacked.InputIf positA,
   PositPacked.InputIf positB,
   PositPacked.OutputIf positOut,
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
    assert(positOut.WIDTH == WIDTH);
    assert(positOut.ES == ES);
  end

  // r2ne only right now
  localparam TRAILING_BITS = 2;

  // 1. Unpack posits
  PositUnpacked #(.WIDTH(WIDTH), .ES(ES)) upA();
  PositUnpacked #(.WIDTH(WIDTH), .ES(ES)) upAReg();
  PositUnpacked #(.WIDTH(WIDTH), .ES(ES)) upB();
  PositUnpacked #(.WIDTH(WIDTH), .ES(ES)) upBReg();
  logic roundStochastic1Reg;

  PositDecode #(.WIDTH(WIDTH),
                .ES(ES))
  decA(.in(positA),
       .out(upA));

  PositDecode #(.WIDTH(WIDTH),
                .ES(ES))
  decB(.in(positB),
       .out(upB));

  // 2. Divide
  // The output is registered
  PositUnpacked #(.WIDTH(WIDTH), .ES(ES)) upOutUnrounded();
  PositUnpacked #(.WIDTH(WIDTH), .ES(ES)) upOutUnroundedReg();
  logic [TRAILING_BITS-1:0] trailingBitsReg;
  logic stickyBitReg;

  PositDivide #(.WIDTH(WIDTH),
                .ES(ES),
                .TRAILING_BITS(TRAILING_BITS))
  div(.a(upAReg),
      .b(upBReg),
      .out(upOutUnroundedReg),
      .divByZero(),
      .trailingBits(trailingBitsReg),
      .stickyBit(stickyBitReg),
      .clock,
      .reset(~resetn));

  // 3. Round result
  PositUnpacked #(.WIDTH(WIDTH), .ES(ES)) upOutRounded();
  PositUnpacked #(.WIDTH(WIDTH), .ES(ES)) upOutRoundedReg();

  PositRoundToNearestEven #(.WIDTH(WIDTH),
                            .ES(ES))
  pr(.in(upOutUnroundedReg),
     .trailingBits(trailingBitsReg),
     .stickyBit(stickyBitReg),
     .out(upOutRounded));

  // 4. Pack result
  PositPacked #(.WIDTH(WIDTH), .ES(ES)) pOutRounded();

  PositEncode #(.WIDTH(WIDTH),
                .ES(ES))
  pe(.in(upOutRoundedReg),
     .out(pOutRounded));

  always_comb begin
    oready = 1'b1;
    ovalid = 1'b1;
  end

  always_ff @(posedge clock) begin
    if (!resetn) begin
      // 1
      upAReg.data <= upA.zero(1'b0);
      upBReg.data <= upB.zero(1'b0);
      roundStochastic1Reg <= 1'b0;

      // 2
      // PositDivide is registered

      // 3
      upOutRoundedReg.data <= upOutRounded.zero(1'b0);

      // 4
      positOut.data <= positOut.zeroPacked();
    end
    else begin
      // 1
      upAReg.data <= upA.data;
      upBReg.data <= upB.data;

      // 2
      // PositDivide is registered

      // 3
      upOutRoundedReg.data <= upOutRounded.data;

      // 4
      positOut.data <= pOutRounded.data;
    end
  end
endmodule
