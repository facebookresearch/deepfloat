// Copyright (c) Facebook, Inc. and its affiliates. All Rights Reserved.
// All rights reserved.
//
// This source code is licensed under the license found in the
// LICENSE file in the root directory of this source tree.


//
// A set of fake top-level modules that provide interface instances to module
// instances that use interfaces, so as to prevent VCS complaining
//

module UsePositDecode();
  PositPacked #(.WIDTH(8), .ES(1)) in();
  PositUnpacked #(.WIDTH(8), .ES(1)) out();

  PositDecode #(.WIDTH(8), .ES(1)) mod(.*);
endmodule

module UsePositEncode();
  PositUnpacked #(.WIDTH(8), .ES(1)) in();
  PositPacked #(.WIDTH(8), .ES(1)) out();

  PositEncode  #(.WIDTH(8), .ES(1)) mod(.*);
endmodule

module UsePositRoundToNearestEven();
  PositUnpacked #(.WIDTH(8), .ES(1)) in();
  logic [1:0] trailingBits;
  logic stickyBit;
  PositUnpacked #(.WIDTH(8), .ES(1)) out();

  PositRoundToNearestEven #(.WIDTH(8), .ES(1)) mod(.*);
endmodule

module UsePositRoundStochastic();
  PositUnpacked #(.WIDTH(8), .ES(1)) in();
  logic [7:0] trailingBits;
  logic stickyBit;
  logic [8:0] randomBits;
  PositUnpacked #(.WIDTH(8), .ES(1)) out();

  PositRoundStochastic #(.WIDTH(8), .ES(1), .TRAILING_BITS(8)) mod(.*);
endmodule

module UsePositRound();
  PositUnpacked #(.WIDTH(8), .ES(1)) in();
  logic [7:0] trailingBits;
  logic stickyBit;
  logic roundStochastic;
  logic clock;
  logic reset;
  PositUnpacked #(.WIDTH(8), .ES(1)) out();

  PositRound #(.WIDTH(8), .ES(1), .TRAILING_BITS(8)) mod(.*);
endmodule

module UsePositAdd();
  PositUnpacked #(.WIDTH(8), .ES(1)) a();
  PositUnpacked #(.WIDTH(8), .ES(1)) b();
  PositUnpacked #(.WIDTH(8), .ES(1)) out();
  logic [1:0] trailingBits;
  logic stickyBit;
  logic subtract;

  PositAdd #(.WIDTH(8), .ES(1)) mod(.*);
endmodule

module UsePositMultiply();
  PositUnpacked #(.WIDTH(8), .ES(1)) a();
  PositUnpacked #(.WIDTH(8), .ES(1)) b();
  PositUnpacked #(.WIDTH(8), .ES(1)) out();
  logic [1:0] trailingBits;
  logic stickyBit;

  PositMultiply #(.WIDTH(8), .ES(1)) mod(.*);
endmodule

module UsePositDivide();
  PositUnpacked #(.WIDTH(8), .ES(1)) a();
  PositUnpacked #(.WIDTH(8), .ES(1)) b();
  PositUnpacked #(.WIDTH(8), .ES(1)) out();
  logic divByZero;
  logic [1:0] trailingBits;
  logic stickyBit;
  logic clock;
  logic reset;

  PositDivide #(.WIDTH(8), .ES(1)) mod(.*);
endmodule

module UsePositCompare();
  PositPacked #(.WIDTH(8), .ES(1)) a();
  PositPacked #(.WIDTH(8), .ES(1)) b();
  Comparison::Type comp;
  logic out;

  PositComparePacked #(.WIDTH(8), .ES(1)) mod(.*);
endmodule

module UsePositMax();
  PositPacked #(.WIDTH(8), .ES(1)) a();
  PositPacked #(.WIDTH(8), .ES(1)) b();
  PositPacked #(.WIDTH(8), .ES(1)) out();

  PositMaxPacked #(.WIDTH(8), .ES(1)) mod(.*);
endmodule

module UsePositMin();
  PositPacked #(.WIDTH(8), .ES(1)) a();
  PositPacked #(.WIDTH(8), .ES(1)) b();
  PositPacked #(.WIDTH(8), .ES(1)) out();

  PositMinPacked #(.WIDTH(8), .ES(1)) mod(.*);
endmodule

module UsePositMultiplyForQuire();
  PositUnpacked #(.WIDTH(8), .ES(1)) a();
  PositUnpacked #(.WIDTH(8), .ES(1)) b();
  logic signed adjustScale;
  logic abIsInf;
  logic abIsZero;
  logic abSign;
  logic [PositDef::getExpProductBits(8, 1)-1:0] abExp;
  logic [PositDef::getFracProductBits(8, 1)-1:0] abFrac;

  PositMultiplyForQuire #(.WIDTH(8),
                          .ES(1),
                          .USE_ADJUST(0),
                          .ADJUST_SCALE_SIZE(1)) mod(.*);
endmodule

module UsePositQuireConvert();
  PositUnpacked #(.WIDTH(8), .ES(1)) in();
  logic adjustScale;
  logic outIsInf;
  logic outIsZero;
  logic outSign;
  logic [PositDef::getExpProductBits(8, 1)-1:0] outExp;
  logic [PositDef::getFracProductBits(8, 1)-1:0] outFrac;

  PositQuireConvert #(.WIDTH(8),
                      .ES(1),
                      .USE_ADJUST(0),
                      .ADJUST_SCALE_SIZE(1)) mod(.*);
endmodule

module UseQuireAdd();
  localparam WIDTH = 8;
  localparam ES = 1;
  localparam OVERFLOW = 0;

  localparam ACC_NON_FRAC = QuireDef::getNonFracBits(WIDTH, ES, OVERFLOW, 0);
  localparam ACC_FRAC = QuireDef::getFracBits(WIDTH, ES, OVERFLOW);

  logic [PositDef::getExpProductBits(WIDTH, ES)-1:0] fixedExpIn;
  logic [1:-(PositDef::getFractionBits(WIDTH, ES) * 2)] fixedValIn;
  logic fixedSignIn;
  logic fixedInfIn;

  Kulisch #(.ACC_NON_FRAC(ACC_NON_FRAC), .ACC_FRAC(ACC_FRAC)) quireIn();
  Kulisch #(.ACC_NON_FRAC(ACC_NON_FRAC), .ACC_FRAC(ACC_FRAC)) quireOut();

  QuireAdd #(.WIDTH(8),
             .ES(1),
             .OVERFLOW(OVERFLOW)) mod (.*);
endmodule

module UseQuireToPosit();
  localparam WIDTH = 8;
  localparam ES = 1;
  localparam OVERFLOW = 0;

  localparam ACC_NON_FRAC = QuireDef::getNonFracBits(WIDTH, ES, OVERFLOW, 0);
  localparam ACC_FRAC = QuireDef::getFracBits(WIDTH, ES, OVERFLOW);

  Kulisch #(.ACC_NON_FRAC(ACC_NON_FRAC), .ACC_FRAC(ACC_FRAC)) in();

  logic signed adjustMul;
  PositUnpacked #(.WIDTH(8), .ES(1)) out();
  logic [1:0] trailingBitsOut;
  logic stickyBitOut;

  QuireToPosit #(.WIDTH(8),
                 .ES(1),
                 .OVERFLOW(OVERFLOW),
                 .TRAILING_BITS(2),
                 .USE_ADJUST(0),
                 .ADJUST_MUL_SIZE(1)) mod(.*);
endmodule

module UsePositFromFloat();
  Float #(.EXP(8), .FRAC(23)) in();
  logic signed expAdjust;
  PositUnpacked #(.WIDTH(8), .ES(0)) out();
  logic [1:0] trailingBits;
  logic stickyBit;

  PositFromFloat #(.POSIT_WIDTH(8),
                   .POSIT_ES(0),
                   .FLOAT_EXP(8),
                   .FLOAT_FRAC(23),
                   .TRAILING_BITS(2),
                   .FTZ_DENORMAL(0),
                   .EXP_ADJUST_BITS(1),
                   .EXP_ADJUST(0)) mod(.*);
endmodule

module UsePositToFloat();
  PositUnpacked #(.WIDTH(8), .ES(0)) in();
  logic signed expAdjust;
  Float #(.EXP(8), .FRAC(23)) out();
  logic [1:0] trailingBitsOut;
  logic stickyBitOut;

  PositToFloat #(.POSIT_WIDTH(8),
                 .POSIT_ES(0),
                 .FLOAT_EXP(8),
                 .FLOAT_FRAC(23),
                 .TRAILING_BITS(2),
                 .EXP_ADJUST_BITS(1),
                 .EXP_ADJUST(0),
                 .SATURATE_TO_MAX_FLOAT(0)) mod(.*);
endmodule

/*
module UsePositLUT_Exp_8_1();
  PositPacked #(.WIDTH(8), .ES(1)) in();
  PositPacked #(.WIDTH(8), .ES(1)) out();

  PositLUT_Exp_8_1 mod(.*);
endmodule

module UsePositLUT_Inv_8_1();
  PositPacked #(.WIDTH(8), .ES(1)) in();
  PositPacked #(.WIDTH(8), .ES(1)) out();

  PositLUT_Inv_8_1 mod(.*);
endmodule

module UsePositLUT_Ln_8_1();
  PositPacked #(.WIDTH(8), .ES(1)) in();
  PositPacked #(.WIDTH(8), .ES(1)) out();

  PositLUT_Ln_8_1 mod(.*);
endmodule

module UsePositLUT_Sigmoid_8_1();
  PositPacked #(.WIDTH(8), .ES(1)) in();
  PositPacked #(.WIDTH(8), .ES(1)) out();

  PositLUT_Sigmoid_8_1 mod(.*);
endmodule

module UsePositLUT_Sqrt_8_1();
  PositPacked #(.WIDTH(8), .ES(1)) in();
  PositPacked #(.WIDTH(8), .ES(1)) out();

  PositLUT_Sqrt_8_1 mod(.*);
endmodule
*/
