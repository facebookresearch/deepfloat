// Copyright (c) Facebook, Inc. and its affiliates. All Rights Reserved.
// All rights reserved.
//
// This source code is licensed under the license found in the
// LICENSE file in the root directory of this source tree.


module PositExp8_1
  (input logic [7:0] positA,
   output logic [7:0] positOut,
   input clock,
   input resetn,
   input ivalid,
   input iready,
   output logic ovalid,
   output logic oready);

  PositPacked #(.WIDTH(8), .ES(1)) positAIf();
  PositPacked #(.WIDTH(8), .ES(1)) v();

  initial begin
    positAIf.data = positA;
  end

  PositLUT_Exp_8_1 plut(.in(positAIf),
                        .out(v));

  always_comb begin
    oready = 1'b1;
    ovalid = 1'b1;
  end

  always_ff @(posedge clock) begin
    if (!resetn) begin
      positOut <= v.zeroPacked();
    end
    else begin
      positOut <= v.data;
    end
  end
endmodule

module PositLn8_1
  (input logic [7:0] positA,
   output logic [7:0] positOut,
   input clock,
   input resetn,
   input ivalid,
   input iready,
   output logic ovalid,
   output logic oready);

  PositPacked #(.WIDTH(8), .ES(1)) positAIf();
  PositPacked #(.WIDTH(8), .ES(1)) v();

  initial begin
    positAIf.data = positA;
  end

  PositLUT_Ln_8_1 plut(.in(positAIf),
                       .out(v));

  always_comb begin
    oready = 1'b1;
    ovalid = 1'b1;
  end

  always_ff @(posedge clock) begin
    if (!resetn) begin
      positOut <= v.zeroPacked();
    end
    else begin
      positOut <= v.data;
    end
  end
endmodule

module PositInv8_1
  (input logic [7:0] positA,
   output logic [7:0] positOut,
   input clock,
   input resetn,
   input ivalid,
   input iready,
   output logic ovalid,
   output logic oready);

  PositPacked #(.WIDTH(8), .ES(1)) positAIf();
  PositPacked #(.WIDTH(8), .ES(1)) v();

  initial begin
    positAIf.data = positA;
  end

  PositLUT_Inv_8_1 plut(.in(positAIf),
                        .out(v));

  always_comb begin
    oready = 1'b1;
    ovalid = 1'b1;
  end

  always_ff @(posedge clock) begin
    if (!resetn) begin
      positOut <= v.zeroPacked();
    end
    else begin
      positOut <= v.data;
    end
  end
endmodule

module PositSqrt8_1
  (input logic [7:0] positA,
   output logic [7:0] positOut,
   input clock,
   input resetn,
   input ivalid,
   input iready,
   output logic ovalid,
   output logic oready);

  PositPacked #(.WIDTH(8), .ES(1)) positAIf();
  PositPacked #(.WIDTH(8), .ES(1)) v();

  initial begin
    positAIf.data = positA;
  end

  PositLUT_Sqrt_8_1 plut(.in(positAIf),
                         .out(v));

  always_comb begin
    oready = 1'b1;
    ovalid = 1'b1;
  end

  always_ff @(posedge clock) begin
    if (!resetn) begin
      positOut <= v.zeroPacked();
    end
    else begin
      positOut <= v.data;
    end
  end
endmodule

module PositSigmoid8_1
  (input logic [7:0] positA,
   output logic [7:0] positOut,
   input clock,
   input resetn,
   input ivalid,
   input iready,
   output logic ovalid,
   output logic oready);

  PositPacked #(.WIDTH(8), .ES(1)) positAIf();
  PositPacked #(.WIDTH(8), .ES(1)) v();

  initial begin
    positAIf.data = positA;
  end

  PositLUT_Sigmoid_8_1 plut(.in(positAIf),
                            .out(v));

  always_comb begin
    oready = 1'b1;
    ovalid = 1'b1;
  end

  always_ff @(posedge clock) begin
    if (!resetn) begin
      positOut <= v.zeroPacked();
    end
    else begin
      positOut <= v.data;
    end
  end
endmodule
