// Copyright (c) Facebook, Inc. and its affiliates. All Rights Reserved.
// All rights reserved.
//
// This source code is licensed under the license found in the
// LICENSE file in the root directory of this source tree.


module LogAdd_Instance
  (input logic [CONFIG_LOG_WRAP_BITS-1:0] a,
   input logic [CONFIG_LOG_WRAP_BITS-1:0] b,
   output logic [CONFIG_LOG_WRAP_BITS-1:0] logOut,
   input [7:0] subtract,
   input clock,
   input resetn,
   input ivalid,
   input iready,
   output logic ovalid,
   output logic oready);

  localparam ACC_NON_FRAC = LogDef::getAccNonFracTapered(CONFIG_LOG_WIDTH,
                                                         CONFIG_LOG_LS);
  localparam ACC_FRAC = LogDef::getAccFracTapered(CONFIG_LOG_WIDTH,
                                                  CONFIG_LOG_LS);

  LogNumberCompact #(.WIDTH(CONFIG_LOG_WIDTH), .LS(CONFIG_LOG_LS)) aIf();

  FieldRead #(.IN(CONFIG_LOG_WRAP_BITS),
              .OUT(CONFIG_LOG_WIDTH))
  frA(.in(a),
      .out(aIf.data));

  LogNumberCompact #(.WIDTH(CONFIG_LOG_WIDTH), .LS(CONFIG_LOG_LS)) bIf();

  FieldRead #(.IN(CONFIG_LOG_WRAP_BITS),
              .OUT(CONFIG_LOG_WIDTH))
  frB(.in(b),
      .out(bIf.data));

  LogNumberCompact #(.WIDTH(CONFIG_LOG_WIDTH), .LS(CONFIG_LOG_LS)) outIf();

  FieldWrite #(.IN(CONFIG_LOG_WIDTH),
               .OUT(CONFIG_LOG_WRAP_BITS))
  fw(.in(outIf.data),
     .out(logOut));

  LogAdd_Impl #(.WIDTH(CONFIG_LOG_WIDTH),
                .LS(CONFIG_LOG_LS),
                .LOG_TO_LINEAR_BITS(CONFIG_LOG_TO_LINEAR_BITS),
                .LINEAR_TO_LOG_BITS(CONFIG_LINEAR_TO_LOG_BITS),
                .SATURATE_MAX(1),
                .ACC_NON_FRAC(ACC_NON_FRAC),
                .ACC_FRAC(ACC_FRAC))
  add(.a(aIf),
      .b(bIf),
      .subtract(subtract[0]),
      .out(outIf),
      .*);
endmodule

module LogMul_Instance
  (input logic [CONFIG_LOG_WRAP_BITS-1:0] a,
   input logic [CONFIG_LOG_WRAP_BITS-1:0] b,
   output logic [CONFIG_LOG_WRAP_BITS-1:0] logOut,
   input clock,
   input resetn,
   input ivalid,
   input iready,
   output logic ovalid,
   output logic oready);

  LogNumberCompact #(.WIDTH(CONFIG_LOG_WIDTH), .LS(CONFIG_LOG_LS)) aIf();

  FieldRead #(.IN(CONFIG_LOG_WRAP_BITS),
              .OUT(CONFIG_LOG_WIDTH))
  frA(.in(a),
      .out(aIf.data));

  LogNumberCompact #(.WIDTH(CONFIG_LOG_WIDTH), .LS(CONFIG_LOG_LS)) bIf();

  FieldRead #(.IN(CONFIG_LOG_WRAP_BITS),
              .OUT(CONFIG_LOG_WIDTH))
  frB(.in(b),
      .out(bIf.data));

  LogNumberCompact #(.WIDTH(CONFIG_LOG_WIDTH), .LS(CONFIG_LOG_LS)) outIf();

  FieldWrite #(.IN(CONFIG_LOG_WIDTH),
               .OUT(CONFIG_LOG_WRAP_BITS))
  fw(.in(outIf.data),
     .out(logOut));

  LogMul_Impl #(.WIDTH(CONFIG_LOG_WIDTH),
                .LS(CONFIG_LOG_LS))
  mul(.a(aIf),
      .b(bIf),
      .out(outIf),
      .*);
endmodule

/*

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

 */
