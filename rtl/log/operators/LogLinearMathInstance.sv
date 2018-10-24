// Copyright (c) Facebook, Inc. and its affiliates. All Rights Reserved.
// All rights reserved.
//
// This source code is licensed under the license found in the
// LICENSE file in the root directory of this source tree.


module LogToLinear_Instance
  (input logic [CONFIG_LOG_WRAP_BITS-1:0] logIn,
   output logic [CONFIG_LOG_ACC_WRAP_BITS-1:0] accOut,
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

  LogNumberCompact #(.WIDTH(CONFIG_LOG_WIDTH), .LS(CONFIG_LOG_LS)) logInIf();

  FieldRead #(.IN(CONFIG_LOG_WRAP_BITS),
              .OUT(CONFIG_LOG_WIDTH))
  frIn(.in(logIn),
       .out(logInIf.data));

  Kulisch #(.ACC_NON_FRAC(ACC_NON_FRAC), .ACC_FRAC(ACC_FRAC)) accOutIf();

  initial begin
    assert($bits(accOutIf.data) == CONFIG_LOG_ACC_BITS);
  end

  LogToLinear_Impl #(.WIDTH(CONFIG_LOG_WIDTH),
                     .LS(CONFIG_LOG_LS),
                     .LOG_TO_LINEAR_BITS(CONFIG_LOG_TO_LINEAR_BITS),
                     .ACC_NON_FRAC(ACC_NON_FRAC),
                     .ACC_FRAC(ACC_FRAC))
  l2lin(.in(logInIf),
        .out(accOutIf),
        .*);

  FieldWrite #(.IN(CONFIG_LOG_ACC_BITS),
               .OUT(CONFIG_LOG_ACC_WRAP_BITS))
  fw(.in(accOutIf.data),
     .out(accOut));
endmodule

module LinearAdd_Instance
  (input [CONFIG_LOG_ACC_WRAP_BITS-1:0] linA,
   input [CONFIG_LOG_ACC_WRAP_BITS-1:0] linB,
   output logic [CONFIG_LOG_ACC_WRAP_BITS-1:0] linOut,
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

  Kulisch #(.ACC_NON_FRAC(ACC_NON_FRAC), .ACC_FRAC(ACC_FRAC)) linAIf();
  Kulisch #(.ACC_NON_FRAC(ACC_NON_FRAC), .ACC_FRAC(ACC_FRAC)) linBIf();
  Kulisch #(.ACC_NON_FRAC(ACC_NON_FRAC), .ACC_FRAC(ACC_FRAC)) linOutIf();

  initial begin
    assert($bits(linAIf.data) == CONFIG_LOG_ACC_BITS);
    assert($bits(linBIf.data) == CONFIG_LOG_ACC_BITS);
    assert($bits(linOutIf.data) == CONFIG_LOG_ACC_BITS);
  end

  FieldRead #(.IN(CONFIG_LOG_ACC_WRAP_BITS),
              .OUT(CONFIG_LOG_ACC_BITS))
  fra(.in(linA),
      .out(linAIf.data));

  FieldRead #(.IN(CONFIG_LOG_ACC_WRAP_BITS),
              .OUT(CONFIG_LOG_ACC_BITS))
  frb(.in(linB),
      .out(linBIf.data));

  FieldWrite #(.IN(CONFIG_LOG_ACC_BITS),
               .OUT(CONFIG_LOG_ACC_WRAP_BITS))
  fw(.in(linOutIf.data),
     .out(linOut));

  LinearAdd_Impl #(.ACC_NON_FRAC(ACC_NON_FRAC),
                   .ACC_FRAC(ACC_FRAC))
  add(.linA(linAIf),
      .linB(linBIf),
      .linOut(linOutIf),
      .*);
endmodule

module LinearToLog_Instance
  (input [CONFIG_LOG_ACC_WRAP_BITS-1:0] accIn,
   input signed [7:0] adjustExp,
   output logic [CONFIG_LOG_WRAP_BITS-1:0] logOut,
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

  Kulisch #(.ACC_NON_FRAC(ACC_NON_FRAC), .ACC_FRAC(ACC_FRAC)) accInIf();

  initial begin
    assert($bits(accInIf.data) == CONFIG_LOG_ACC_BITS);
  end

  FieldRead #(.IN(CONFIG_LOG_ACC_WRAP_BITS),
              .OUT(CONFIG_LOG_ACC_BITS))
  fra(.in(accIn),
      .out(accInIf.data));

  LogNumberCompact #(.WIDTH(CONFIG_LOG_WIDTH), .LS(CONFIG_LOG_LS)) logOutIf();

  FieldWrite #(.IN(CONFIG_LOG_WIDTH),
               .OUT(CONFIG_LOG_WRAP_BITS))
  fw(.in(logOutIf.data),
     .out(logOut));

  LinearToLog_Impl #(.WIDTH(CONFIG_LOG_WIDTH),
                     .LS(CONFIG_LOG_LS),
                     .LINEAR_TO_LOG_BITS(CONFIG_LINEAR_TO_LOG_BITS),
                     .USE_ADJUST(1),
                     .ADJUST_EXP_SIZE(8),
                     .SATURATE_MAX(1),
                     .ACC_NON_FRAC(ACC_NON_FRAC),
                     .ACC_FRAC(ACC_FRAC))
  l2log(.in(accInIf),
        .adjustExp(adjustExp),
        .out(logOutIf),
        .*);
endmodule

module LogMultiplyToLinear_Instance
  (input logic [CONFIG_LOG_WRAP_BITS-1:0] logA,
   input logic [CONFIG_LOG_WRAP_BITS-1:0] logB,
   output logic [CONFIG_LOG_ACC_WRAP_BITS-1:0] accOut,
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

  LogNumberCompact #(.WIDTH(CONFIG_LOG_WIDTH), .LS(CONFIG_LOG_LS)) logAIf();

  FieldRead #(.IN(CONFIG_LOG_WRAP_BITS),
              .OUT(CONFIG_LOG_WIDTH))
  frInA(.in(logA),
        .out(logAIf.data));

  LogNumberCompact #(.WIDTH(CONFIG_LOG_WIDTH), .LS(CONFIG_LOG_LS)) logBIf();

  FieldRead #(.IN(CONFIG_LOG_WRAP_BITS),
              .OUT(CONFIG_LOG_WIDTH))
  frInB(.in(logB),
        .out(logBIf.data));

  Kulisch #(.ACC_NON_FRAC(ACC_NON_FRAC), .ACC_FRAC(ACC_FRAC)) accOutIf();

  initial begin
    assert($bits(accOutIf.data) == CONFIG_LOG_ACC_BITS);
  end

  FieldWrite #(.IN(CONFIG_LOG_ACC_BITS),
               .OUT(CONFIG_LOG_ACC_WRAP_BITS))
  fw(.in(accOutIf.data),
     .out(accOut));

  LogMultiplyToLinear_Impl #(.WIDTH(CONFIG_LOG_WIDTH),
                             .LS(CONFIG_LOG_LS),
                             .LOG_TO_LINEAR_BITS(CONFIG_LOG_TO_LINEAR_BITS),
                             .ACC_NON_FRAC(ACC_NON_FRAC),
                             .ACC_FRAC(ACC_FRAC))
  mul(.inA(logAIf),
      .inB(logBIf),
      .out(accOutIf),
      .*);
endmodule

module LinearDivide_Instance
  (input [CONFIG_LOG_ACC_WRAP_BITS-1:0] accIn,
   input [7:0] div,
   output logic [CONFIG_LOG_ACC_WRAP_BITS-1:0] accOut,
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

  Kulisch #(.ACC_NON_FRAC(ACC_NON_FRAC), .ACC_FRAC(ACC_FRAC)) accInIf();
  Kulisch #(.ACC_NON_FRAC(ACC_NON_FRAC), .ACC_FRAC(ACC_FRAC)) accOutIf();

  initial begin
    assert($bits(accInIf.data) == CONFIG_LOG_ACC_BITS);
    assert($bits(accOutIf.data) == CONFIG_LOG_ACC_BITS);
  end

  FieldRead #(.IN(CONFIG_LOG_ACC_WRAP_BITS),
              .OUT(CONFIG_LOG_ACC_BITS))
  fr(.in(accIn),
     .out(accInIf.data));

  FieldWrite #(.IN(CONFIG_LOG_ACC_BITS),
               .OUT(CONFIG_LOG_ACC_WRAP_BITS))
  fw(.in(accOutIf.data),
     .out(accOut));

  always_comb begin
    oready = 1'b1;
    ovalid = 1'b1;
  end

  KulischAccumulatorDivide #(.ACC_NON_FRAC(ACC_NON_FRAC),
                             .ACC_FRAC(ACC_FRAC),
                             .DIV(8))
  kad(.accIn(accInIf),
      .div,
      .accOut(accOutIf),
      .clock,
      .reset(~resetn));
endmodule
