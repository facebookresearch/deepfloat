// Copyright (c) Facebook, Inc. and its affiliates. All Rights Reserved.
// All rights reserved.
//
// This source code is licensed under the license found in the
// LICENSE file in the root directory of this source tree.


module PositAdd_Instance
  (input logic [CONFIG_POSIT_WRAP_BITS-1:0] positA,
   input logic [CONFIG_POSIT_WRAP_BITS-1:0] positB,
   output logic [CONFIG_POSIT_WRAP_BITS-1:0] positOut,
   input [7:0] subtract,
   input [7:0] roundStochastic,
   input clock,
   input resetn,
   input ivalid,
   input iready,
   output logic ovalid,
   output logic oready);

  PositPacked #(.WIDTH(CONFIG_POSIT_WIDTH), .ES(CONFIG_POSIT_ES)) positAIf();
  PositPacked #(.WIDTH(CONFIG_POSIT_WIDTH), .ES(CONFIG_POSIT_ES)) positBIf();
  PositPacked #(.WIDTH(CONFIG_POSIT_WIDTH), .ES(CONFIG_POSIT_ES)) positOutIf();

  FieldRead #(.IN(CONFIG_POSIT_WRAP_BITS),
              .OUT(CONFIG_POSIT_WIDTH))
  fra(.in(positA),
      .out(positAIf.data));

  FieldRead #(.IN(CONFIG_POSIT_WRAP_BITS),
              .OUT(CONFIG_POSIT_WIDTH))
  frb(.in(positB),
      .out(positBIf.data));

  FieldWrite #(.IN(CONFIG_POSIT_WIDTH),
               .OUT(CONFIG_POSIT_WRAP_BITS))
  fw(.in(positOutIf.data),
     .out(positOut));

  PositAdd_Impl #(.WIDTH(CONFIG_POSIT_WIDTH),
                  .ES(CONFIG_POSIT_ES),
                  .TRAILING_BITS(8))
  pa(.positA(positAIf),
     .positB(positBIf),
     .positOut(positOutIf),
     .subtract(subtract[0]),
     .roundStochastic(roundStochastic[0]),
     .*);
endmodule

module PositMul_Instance
  (input logic [CONFIG_POSIT_WRAP_BITS-1:0] positA,
   input logic [CONFIG_POSIT_WRAP_BITS-1:0] positB,
   output logic [CONFIG_POSIT_WRAP_BITS-1:0] positOut,
   input [7:0] roundStochastic,
   input clock,
   input resetn,
   input ivalid,
   input iready,
   output logic ovalid,
   output logic oready);

  PositPacked #(.WIDTH(CONFIG_POSIT_WIDTH), .ES(CONFIG_POSIT_ES)) positAIf();
  PositPacked #(.WIDTH(CONFIG_POSIT_WIDTH), .ES(CONFIG_POSIT_ES)) positBIf();
  PositPacked #(.WIDTH(CONFIG_POSIT_WIDTH), .ES(CONFIG_POSIT_ES)) positOutIf();

  FieldRead #(.IN(CONFIG_POSIT_WRAP_BITS),
              .OUT(CONFIG_POSIT_WIDTH))
  fra(.in(positA),
      .out(positAIf.data));

  FieldRead #(.IN(CONFIG_POSIT_WRAP_BITS),
              .OUT(CONFIG_POSIT_WIDTH))
  frb(.in(positB),
      .out(positBIf.data));

  FieldWrite #(.IN(CONFIG_POSIT_WIDTH),
               .OUT(CONFIG_POSIT_WRAP_BITS))
  fw(.in(positOutIf.data),
     .out(positOut));

  PositMul_Impl #(.WIDTH(CONFIG_POSIT_WIDTH),
                  .ES(CONFIG_POSIT_ES),
                  .TRAILING_BITS(8))
  pm(.positA(positAIf),
     .positB(positBIf),
     .positOut(positOutIf),
     .roundStochastic(roundStochastic[0]),
     .*);
endmodule

module PositDiv_Instance
  (input logic [CONFIG_POSIT_WRAP_BITS-1:0] positA,
   input logic [CONFIG_POSIT_WRAP_BITS-1:0] positB,
   output logic [CONFIG_POSIT_WRAP_BITS-1:0] positOut,
   input clock,
   input resetn,
   input ivalid,
   input iready,
   output logic ovalid,
   output logic oready);

  PositPacked #(.WIDTH(CONFIG_POSIT_WIDTH), .ES(CONFIG_POSIT_ES)) positAIf();
  PositPacked #(.WIDTH(CONFIG_POSIT_WIDTH), .ES(CONFIG_POSIT_ES)) positBIf();
  PositPacked #(.WIDTH(CONFIG_POSIT_WIDTH), .ES(CONFIG_POSIT_ES)) positOutIf();


  FieldRead #(.IN(CONFIG_POSIT_WRAP_BITS),
              .OUT(CONFIG_POSIT_WIDTH))
  fra(.in(positA),
      .out(positAIf.data));

  FieldRead #(.IN(CONFIG_POSIT_WRAP_BITS),
              .OUT(CONFIG_POSIT_WIDTH))
  frb(.in(positB),
      .out(positBIf.data));

  FieldWrite #(.IN(CONFIG_POSIT_WIDTH),
               .OUT(CONFIG_POSIT_WRAP_BITS))
  fw(.in(positOutIf.data),
     .out(positOut));

  PositDiv_Impl #(.WIDTH(CONFIG_POSIT_WIDTH),
                  .ES(CONFIG_POSIT_ES))
  pd(.positA(positAIf),
     .positB(positBIf),
     .positOut(positOutIf),
     .*);
endmodule
