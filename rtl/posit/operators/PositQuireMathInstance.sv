// Copyright (c) Facebook, Inc. and its affiliates. All Rights Reserved.
// All rights reserved.
//
// This source code is licensed under the license found in the
// LICENSE file in the root directory of this source tree.


typedef struct packed {
  logic [CONFIG_POSIT_PRODUCT_FRAC_BITS-1:0] abFrac;
  logic [CONFIG_POSIT_PRODUCT_EXP_BITS-1:0] abExp;
  logic abIsInf;
  logic abIsZero;
  logic abSign;
} PositProductStruct;

module PositQuireConvert_Instance
  (input logic [CONFIG_POSIT_WRAP_BITS-1:0] positA,
   input signed [7:0] adjustScale,
   output logic [CONFIG_POSIT_PRODUCT_WRAP_BITS-1:0] productOut,
   input clock,
   input resetn,
   input ivalid,
   input iready,
   output logic ovalid,
   output logic oready);

  PositPacked #(.WIDTH(CONFIG_POSIT_WIDTH), .ES(CONFIG_POSIT_ES)) positAIf();
  PositProductStruct product;

  initial begin
    assert($bits(product.abFrac) ==
           PositDef::getFracProductBits(CONFIG_POSIT_WIDTH,
                                        CONFIG_POSIT_ES));
    assert($bits(product.abExp) ==
           PositDef::getExpProductBits(CONFIG_POSIT_WIDTH,
                                       CONFIG_POSIT_ES));
  end

  FieldRead #(.IN(CONFIG_POSIT_WRAP_BITS),
              .OUT(CONFIG_POSIT_WIDTH))
  fra(.in(positA),
      .out(positAIf.data));

  FieldWrite #(.IN(CONFIG_POSIT_PRODUCT_BITS),
               .OUT(CONFIG_POSIT_PRODUCT_WRAP_BITS))
  fw(.in(product),
     .out(productOut));

  PositQuireConvert_Impl #(.WIDTH(CONFIG_POSIT_WIDTH),
                           .ES(CONFIG_POSIT_ES),
                           .USE_ADJUST(1),
                           .ADJUST_SCALE_SIZE(8))
  pqc(.positA(positAIf),
      .adjustScale,
      .outIsInf(product.abIsInf),
      .outIsZero(product.abIsZero),
      .outSign(product.abSign),
      .outExp(product.abExp),
      .outFrac(product.abFrac),
      .*);
endmodule

module PositQuireMultiply_Instance
  (input logic [CONFIG_POSIT_WRAP_BITS-1:0] positA,
   input logic [CONFIG_POSIT_WRAP_BITS-1:0] positB,
   input signed [7:0] adjustScale,
   output logic [CONFIG_POSIT_PRODUCT_WRAP_BITS-1:0] productOut,
   input clock,
   input resetn,
   input ivalid,
   input iready,
   output logic ovalid,
   output logic oready);

  PositPacked #(.WIDTH(CONFIG_POSIT_WIDTH), .ES(CONFIG_POSIT_ES)) positAIf();
  PositPacked #(.WIDTH(CONFIG_POSIT_WIDTH), .ES(CONFIG_POSIT_ES)) positBIf();
  PositProductStruct product;

  initial begin
    assert($bits(product.abFrac) ==
           PositDef::getFracProductBits(CONFIG_POSIT_WIDTH,
                                        CONFIG_POSIT_ES));
    assert($bits(product.abExp) ==
           PositDef::getExpProductBits(CONFIG_POSIT_WIDTH,
                                       CONFIG_POSIT_ES));
  end

  FieldRead #(.IN(CONFIG_POSIT_WRAP_BITS),
              .OUT(CONFIG_POSIT_WIDTH))
  fra(.in(positA),
      .out(positAIf.data));

  FieldRead #(.IN(CONFIG_POSIT_WRAP_BITS),
              .OUT(CONFIG_POSIT_WIDTH))
  frb(.in(positB),
      .out(positBIf.data));

  FieldWrite #(.IN(CONFIG_POSIT_PRODUCT_BITS),
               .OUT(CONFIG_POSIT_PRODUCT_WRAP_BITS))
  fw(.in(product),
     .out(productOut));

  PositQuireMultiply_Impl #(.WIDTH(CONFIG_POSIT_WIDTH),
                            .ES(CONFIG_POSIT_ES),
                            .USE_ADJUST(1),
                            .ADJUST_SCALE_SIZE(8))
  pqm(.positA(positAIf),
      .positB(positBIf),
      .adjustScale,
      .abIsInf(product.abIsInf),
      .abIsZero(product.abIsZero),
      .abSign(product.abSign),
      .abExp(product.abExp),
      .abFrac(product.abFrac),
      .*);
endmodule

module PositToQuire_Instance
  (input logic [CONFIG_POSIT_WRAP_BITS-1:0] positA,
   input signed [7:0] adjustScale,
   output logic [CONFIG_QUIRE_WRAP_BITS-1:0] quireOut,
   input clock,
   input resetn,
   input ivalid,
   input iready,
   output logic ovalid,
   output logic oready);

  localparam ACC_NON_FRAC = QuireDef::getNonFracBits(CONFIG_POSIT_WIDTH,
                                                     CONFIG_POSIT_ES,
                                                     CONFIG_QUIRE_OVERFLOW, 0);
  localparam ACC_FRAC = QuireDef::getFracBits(CONFIG_POSIT_WIDTH,
                                              CONFIG_POSIT_ES,
                                              CONFIG_QUIRE_OVERFLOW);

  PositPacked #(.WIDTH(CONFIG_POSIT_WIDTH),
                .ES(CONFIG_POSIT_ES)) positAIf();

  Kulisch #(.ACC_NON_FRAC(ACC_NON_FRAC), .ACC_FRAC(ACC_FRAC)) quireOutIf();

  initial begin
    assert($bits(quireOutIf.data) == CONFIG_QUIRE_BITS);
  end

  FieldRead #(.IN(CONFIG_POSIT_WRAP_BITS),
              .OUT(CONFIG_POSIT_WIDTH))
  fra(.in(positA),
      .out(positAIf.data));

  FieldWrite #(.IN(CONFIG_QUIRE_BITS),
               .OUT(CONFIG_QUIRE_WRAP_BITS))
  fw(.in(quireOutIf.data),
     .out(quireOut));

  PositToQuire_Impl #(.WIDTH(CONFIG_POSIT_WIDTH),
                      .ES(CONFIG_POSIT_ES),
                      .OVERFLOW(CONFIG_QUIRE_OVERFLOW),
                      .USE_ADJUST(1),
                      .ADJUST_SCALE_SIZE(8))
  qa(.in(positAIf),
     .adjustScale,
     .out(quireOutIf),
     .*);
endmodule

module ProductToQuire_Instance
  (input [CONFIG_POSIT_PRODUCT_WRAP_BITS-1:0] productIn,
   output logic [CONFIG_QUIRE_WRAP_BITS-1:0] quireOut,
   input clock,
   input resetn,
   input ivalid,
   input iready,
   output logic ovalid,
   output logic oready);

  localparam ACC_NON_FRAC = QuireDef::getNonFracBits(CONFIG_POSIT_WIDTH,
                                                     CONFIG_POSIT_ES,
                                                     CONFIG_QUIRE_OVERFLOW, 0);
  localparam ACC_FRAC = QuireDef::getFracBits(CONFIG_POSIT_WIDTH,
                                              CONFIG_POSIT_ES,
                                              CONFIG_QUIRE_OVERFLOW);

  Kulisch #(.ACC_NON_FRAC(ACC_NON_FRAC), .ACC_FRAC(ACC_FRAC)) quireOutIf();
  Kulisch #(.ACC_NON_FRAC(ACC_NON_FRAC), .ACC_FRAC(ACC_FRAC)) quireZero();

  PositProductStruct product;

  initial begin
    assert($bits(product) == CONFIG_POSIT_PRODUCT_BITS);
    assert($bits(quireOutIf.data) == CONFIG_QUIRE_BITS);
  end

  FieldRead #(.IN(CONFIG_POSIT_PRODUCT_WRAP_BITS),
              .OUT(CONFIG_POSIT_PRODUCT_BITS))
  fr(.in(productIn),
     .out(product));

  FieldWrite #(.IN(CONFIG_QUIRE_BITS),
               .OUT(CONFIG_QUIRE_WRAP_BITS))
  fw(.in(quireOutIf.data),
     .out(quireOut));

  always_comb begin
    quireZero.data = quireZero.zero();
  end

  QuirePositAdd_Impl #(.WIDTH(CONFIG_POSIT_WIDTH),
                       .ES(CONFIG_POSIT_ES),
                       .OVERFLOW(CONFIG_QUIRE_OVERFLOW))
  qa(.abIsInf(product.abIsInf),
     .abIsZero(product.abIsZero),
     .abSign(product.abSign),
     .abFrac(product.abFrac),
     .abExp(product.abExp),
     .quireIn(quireZero),
     .quireOut(quireOutIf),
     .*);
endmodule

module QuirePositAdd_Instance
  (input [CONFIG_POSIT_PRODUCT_WRAP_BITS-1:0] productIn,
   input [CONFIG_QUIRE_WRAP_BITS-1:0] quireIn,
   output logic [CONFIG_QUIRE_WRAP_BITS-1:0] quireOut,
   input clock,
   input resetn,
   input ivalid,
   input iready,
   output logic ovalid,
   output logic oready);

  localparam ACC_NON_FRAC = QuireDef::getNonFracBits(CONFIG_POSIT_WIDTH,
                                                     CONFIG_POSIT_ES,
                                                     CONFIG_QUIRE_OVERFLOW, 0);
  localparam ACC_FRAC = QuireDef::getFracBits(CONFIG_POSIT_WIDTH,
                                              CONFIG_POSIT_ES,
                                              CONFIG_QUIRE_OVERFLOW);

  Kulisch #(.ACC_NON_FRAC(ACC_NON_FRAC), .ACC_FRAC(ACC_FRAC)) quireInIf();
  Kulisch #(.ACC_NON_FRAC(ACC_NON_FRAC), .ACC_FRAC(ACC_FRAC)) quireOutIf();

  PositProductStruct product;

  initial begin
    assert($bits(product) == CONFIG_POSIT_PRODUCT_BITS);
    assert($bits(quireInIf.data) == CONFIG_QUIRE_BITS);
    assert($bits(quireOutIf.data) == CONFIG_QUIRE_BITS);
  end

  FieldRead #(.IN(CONFIG_POSIT_PRODUCT_WRAP_BITS),
              .OUT(CONFIG_POSIT_PRODUCT_BITS))
  frp(.in(productIn),
      .out(product));

  FieldRead #(.IN(CONFIG_QUIRE_WRAP_BITS),
              .OUT(CONFIG_QUIRE_BITS))
  frq(.in(quireIn),
      .out(quireInIf.data));

  FieldWrite #(.IN(CONFIG_QUIRE_BITS),
               .OUT(CONFIG_QUIRE_WRAP_BITS))
  fw(.in(quireOutIf.data),
     .out(quireOut));

  QuirePositAdd_Impl #(.WIDTH(CONFIG_POSIT_WIDTH),
                       .ES(CONFIG_POSIT_ES),
                       .OVERFLOW(CONFIG_QUIRE_OVERFLOW))
  qa(.abIsInf(product.abIsInf),
     .abIsZero(product.abIsZero),
     .abSign(product.abSign),
     .abFrac(product.abFrac),
     .abExp(product.abExp),
     .quireIn(quireInIf),
     .quireOut(quireOutIf),
     .*);
endmodule

module QuireAdd_Instance
  (input [CONFIG_QUIRE_WRAP_BITS-1:0] quireA,
   input [CONFIG_QUIRE_WRAP_BITS-1:0] quireB,
   output logic [CONFIG_QUIRE_WRAP_BITS-1:0] quireOut,
   input clock,
   input resetn,
   input ivalid,
   input iready,
   output logic ovalid,
   output logic oready);

  localparam ACC_NON_FRAC = QuireDef::getNonFracBits(CONFIG_POSIT_WIDTH,
                                                     CONFIG_POSIT_ES,
                                                     CONFIG_QUIRE_OVERFLOW, 0);
  localparam ACC_FRAC = QuireDef::getFracBits(CONFIG_POSIT_WIDTH,
                                              CONFIG_POSIT_ES,
                                              CONFIG_QUIRE_OVERFLOW);

  Kulisch #(.ACC_NON_FRAC(ACC_NON_FRAC), .ACC_FRAC(ACC_FRAC)) quireAIf();
  Kulisch #(.ACC_NON_FRAC(ACC_NON_FRAC), .ACC_FRAC(ACC_FRAC)) quireBIf();
  Kulisch #(.ACC_NON_FRAC(ACC_NON_FRAC), .ACC_FRAC(ACC_FRAC)) quireOutIf();

  initial begin
    assert($bits(quireAIf.data) == CONFIG_QUIRE_BITS);
    assert($bits(quireBIf.data) == CONFIG_QUIRE_BITS);
    assert($bits(quireOutIf.data) == CONFIG_QUIRE_BITS);
  end

  FieldRead #(.IN(CONFIG_QUIRE_WRAP_BITS),
              .OUT(CONFIG_QUIRE_BITS))
  fra(.in(quireA),
      .out(quireAIf.data));

  FieldRead #(.IN(CONFIG_QUIRE_WRAP_BITS),
              .OUT(CONFIG_QUIRE_BITS))
  frb(.in(quireB),
      .out(quireBIf.data));

  FieldWrite #(.IN(CONFIG_QUIRE_BITS),
               .OUT(CONFIG_QUIRE_WRAP_BITS))
  fw(.in(quireOutIf.data),
     .out(quireOut));

  QuireAdd_Impl #(.WIDTH(CONFIG_POSIT_WIDTH),
                  .ES(CONFIG_POSIT_ES),
                  .OVERFLOW(CONFIG_QUIRE_OVERFLOW))
  qa(.quireA(quireAIf),
     .quireB(quireBIf),
     .quireOut(quireOutIf),
     .*);
endmodule

module QuireToPosit_Instance
  (input [CONFIG_QUIRE_WRAP_BITS-1:0] quireIn,
   output logic [CONFIG_POSIT_WRAP_BITS-1:0] positOut,
   input signed [7:0] adjustMul,
   input [7:0] roundStochastic,
   input clock,
   input resetn,
   input ivalid,
   input iready,
   output logic ovalid,
   output logic oready);

  localparam ACC_NON_FRAC = QuireDef::getNonFracBits(CONFIG_POSIT_WIDTH,
                                                     CONFIG_POSIT_ES,
                                                     CONFIG_QUIRE_OVERFLOW, 0);
  localparam ACC_FRAC = QuireDef::getFracBits(CONFIG_POSIT_WIDTH,
                                              CONFIG_POSIT_ES,
                                              CONFIG_QUIRE_OVERFLOW);

  Kulisch #(.ACC_NON_FRAC(ACC_NON_FRAC), .ACC_FRAC(ACC_FRAC)) quireInIf();

  initial begin
    assert($bits(quireInIf.data) == CONFIG_QUIRE_BITS);
  end

  PositPacked #(.WIDTH(CONFIG_POSIT_WIDTH), .ES(CONFIG_POSIT_ES)) positOutIf();

  FieldRead #(.IN(CONFIG_QUIRE_WRAP_BITS),
              .OUT(CONFIG_QUIRE_BITS))
  fra(.in(quireIn),
      .out(quireInIf.data));

  FieldWrite #(.IN(CONFIG_POSIT_WIDTH),
               .OUT(CONFIG_POSIT_WRAP_BITS))
  fw(.in(positOutIf.data),
     .out(positOut));

  QuireToPosit_Impl #(.WIDTH(CONFIG_POSIT_WIDTH),
                      .ES(CONFIG_POSIT_ES),
                      .OVERFLOW(CONFIG_QUIRE_OVERFLOW),
                      .TRAILING_BITS(8),
                      .USE_ADJUST(1),
                      .ADJUST_MUL_SIZE(8))
  q2p(.quireIn(quireInIf),
      .positOut(positOutIf),
      .adjustMul,
      .roundStochastic(roundStochastic[0]),
      .*);
endmodule

module QuireDivide_Instance
  (input [CONFIG_QUIRE_WRAP_BITS-1:0] quireIn,
   input [7:0] div,
   output logic [CONFIG_QUIRE_WRAP_BITS-1:0] quireOut,
   input clock,
   input resetn,
   input ivalid,
   input iready,
   output logic ovalid,
   output logic oready);

  localparam ACC_NON_FRAC = QuireDef::getNonFracBits(CONFIG_POSIT_WIDTH,
                                                     CONFIG_POSIT_ES,
                                                     CONFIG_QUIRE_OVERFLOW, 0);
  localparam ACC_FRAC = QuireDef::getFracBits(CONFIG_POSIT_WIDTH,
                                              CONFIG_POSIT_ES,
                                              CONFIG_QUIRE_OVERFLOW);

  Kulisch #(.ACC_NON_FRAC(ACC_NON_FRAC), .ACC_FRAC(ACC_FRAC)) quireInIf();
  Kulisch #(.ACC_NON_FRAC(ACC_NON_FRAC), .ACC_FRAC(ACC_FRAC)) quireOutIf();

  initial begin
    assert($bits(quireInIf.data) == CONFIG_QUIRE_BITS);
    assert($bits(quireOutIf.data) == CONFIG_QUIRE_BITS);
  end

  FieldRead #(.IN(CONFIG_QUIRE_WRAP_BITS),
              .OUT(CONFIG_QUIRE_BITS))
  fr(.in(quireIn),
     .out(quireInIf.data));

  FieldWrite #(.IN(CONFIG_QUIRE_BITS),
               .OUT(CONFIG_QUIRE_WRAP_BITS))
  fw(.in(quireOutIf.data),
     .out(quireOut));

  always_comb begin
    oready = 1'b1;
    ovalid = 1'b1;
  end

  KulischAccumulatorDivide #(.ACC_NON_FRAC(ACC_NON_FRAC),
                             .ACC_FRAC(ACC_FRAC),
                             .DIV(8))
  kad(.accIn(quireInIf),
      .div,
      .accOut(quireOutIf),
      .clock,
      .reset(~resetn));
endmodule
