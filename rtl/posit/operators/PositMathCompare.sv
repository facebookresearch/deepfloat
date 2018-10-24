// Copyright (c) Facebook, Inc. and its affiliates. All Rights Reserved.
// All rights reserved.
//
// This source code is licensed under the license found in the
// LICENSE file in the root directory of this source tree.


module PositComp_Impl #(parameter WIDTH=8,
                        parameter ES=1)
  (PositPacked.InputIf positA,
   PositPacked.InputIf positB,
   input logic [7:0] comp,
   output logic [7:0] boolOut,
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

  logic out;

  PositComparePacked #(.WIDTH(WIDTH), .ES(ES))
  pcp(.a(positA),
      .b(positB),
      .comp(Comparison::Type'(comp[2:0])),
      .out);

  always_comb begin
    oready = 1'b1;
    ovalid = 1'b1;
  end

  always_ff @(posedge clock) begin
    if (!resetn) begin
      boolOut <= 8'b0;
    end
    else begin
      boolOut <= {7'b0, out};
    end
  end
endmodule

module PositMax_Impl #(parameter WIDTH=8,
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

  PositPacked #(.WIDTH(WIDTH), .ES(ES)) v();

  PositMaxPacked #(.WIDTH(WIDTH), .ES(ES))
  pmp(.a(positA),
      .b(positB),
      .out(v));

  always_comb begin
    oready = 1'b1;
    ovalid = 1'b1;
  end

  always_ff @(posedge clock) begin
    if (!resetn) begin
      positOut.data <= positOut.zeroPacked();
    end
    else begin
      positOut.data <= v.data;
    end
  end
endmodule

module PositMin_Impl #(parameter WIDTH=8,
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

  PositPacked #(.WIDTH(WIDTH), .ES(ES)) v();

  PositMinPacked #(.WIDTH(WIDTH), .ES(ES))
  pmp(.a(positA),
      .b(positB),
      .out(v));

  always_comb begin
    oready = 1'b1;
    ovalid = 1'b1;
  end

  always_ff @(posedge clock) begin
    if (!resetn) begin
      positOut.data <= positOut.zeroPacked();
    end
    else begin
      positOut.data <= v.data;
    end
  end
endmodule
