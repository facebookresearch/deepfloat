// Copyright (c) Facebook, Inc. and its affiliates. All Rights Reserved.
// All rights reserved.
//
// This source code is licensed under the license found in the
// LICENSE file in the root directory of this source tree.


module LogComp_Impl #(parameter WIDTH=8,
                      parameter LS=1)
  (LogNumberCompact.InputIf inA,
   LogNumberCompact.InputIf inB,
   input logic [7:0] comp,
   output logic [7:0] boolOut,
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
  end

  // 1
  LogNumberUnpacked #(.M(M), .F(F)) upA();
  LogNumberUnpacked #(.M(M), .F(F)) upAReg();

  LogCompactToLogUnpacked #(.WIDTH(WIDTH),
                            .LS(LS))
  lc2luA(.in(inA),
         .out(upA));

  LogNumberUnpacked #(.M(M), .F(F)) upB();
  LogNumberUnpacked #(.M(M), .F(F)) upBReg();

  LogCompactToLogUnpacked #(.WIDTH(WIDTH),
                            .LS(LS))
  lc2luB(.in(inB),
         .out(upB));

  logic out;

  // 2
  LogCompare #(.M(M),
               .F(F))
  lc(.a(upAReg),
     .b(upBReg),
     .comp(Comparison::Type'(comp[2:0])),
     .out);

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
      boolOut <= 8'b0;
    end else begin
      // 1
      upAReg.data <= upA.data;
      upBReg.data <= upB.data;

      // 2
      boolOut <= {7'b0, out};
    end
  end
endmodule
