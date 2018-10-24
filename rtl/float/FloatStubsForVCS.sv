// Copyright (c) Facebook, Inc. and its affiliates. All Rights Reserved.
// All rights reserved.
//
// This source code is licensed under the license found in the
// LICENSE file in the root directory of this source tree.

//
// A set of fake top-level modules that provide interface instances to module
// instances that use interfaces, so as to prevent VCS complaining
//

module UseFloatProperties();
  Float #(.EXP(8), .FRAC(23)) in();
  logic isInf;
  logic isNan;
  logic isZero;
  logic isDenormal;

  FloatProperties #(.EXP(8), .FRAC(23)) mod(.*);
endmodule

module UseFloatExpand();
  Float #(.EXP(8), .FRAC(23)) in();
  Float #(.EXP(9), .FRAC(40)) out();
  logic isInf;
  logic isNan;
  logic isZero;
  logic isDenormal;

  FloatExpand #(.EXP_IN(8),
                .FRAC_IN(23),
                .EXP_OUT(9),
                .FRAC_OUT(40)) mod(.*);
endmodule

module UseFloatContract();
  Float #(.EXP(9), .FRAC(40)) in();
  Float #(.EXP(8), .FRAC(23)) out();
  logic [1:0] trailingBitsOut;
  logic stickyBitOut;
  logic isNanOut;

  FloatContract #(.EXP_IN(9),
                  .FRAC_IN(40),
                  .EXP_OUT(8),
                  .FRAC_OUT(23)) mod(.*);
endmodule

module UseFloatRoundToNearestEven();
  Float #(.EXP(9), .FRAC(40)) in();
  logic [1:0] trailingBitsIn;
  logic stickyBitIn;
  logic isNanIn;
  Float #(.EXP(9), .FRAC(40)) out();

  FloatRoundToNearestEven #(.EXP(9),
                            .FRAC(40)) mod(.*);
endmodule

module UseFloatRoundStochastic();
  Float #(.EXP(9), .FRAC(40)) in();
  logic [7:0] trailingBitsIn;
  logic stickyBitIn;
  logic isNanIn;
  logic [7:0] randomBitsIn;
  Float #(.EXP(9), .FRAC(40)) out();

  FloatRoundStochastic #(.EXP(9),
                         .FRAC(40),
                         .ROUND_BITS(8)) mod(.*);
endmodule


module UseFloatAdd();
  Float #(.EXP(9), .FRAC(40)) inA();
  Float #(.EXP(9), .FRAC(40)) inB();
  logic subtract;
  Float #(.EXP(9), .FRAC(40)) out();
  logic [1:0] trailingBits;
  logic stickyBit;
  logic isNan;
  logic reset;
  logic clock;

  FloatAdd #(.EXP_IN_A(9),
             .FRAC_IN_A(40),
             .EXP_IN_B(9),
             .FRAC_IN_B(40),
             .EXP_OUT(9),
             .FRAC_OUT(40),
             .TRAILING_BITS(2)) mod(.*);
endmodule

module UseFloatMultiply();
  Float #(.EXP(9), .FRAC(40)) inA();
  Float #(.EXP(9), .FRAC(40)) inB();
  Float #(.EXP(9), .FRAC(40)) out();
  logic [1:0] trailingBits;
  logic stickyBit;
  logic isNan;
  logic reset;
  logic clock;

  FloatMultiply #(.EXP_IN_A(9),
                  .FRAC_IN_A(40),
                  .EXP_IN_B(9),
                  .FRAC_IN_B(40),
                  .EXP_OUT(9),
                  .FRAC_OUT(40),
                  .TRAILING_BITS(2)) mod(.*);
endmodule

module UseKulischToFloat();
  Kulisch #(.ACC_NON_FRAC(10), .ACC_FRAC(10)) in();
  Float #(.EXP(8), .FRAC(23)) out();

  KulischToFloat #(.ACC_NON_FRAC(10), .ACC_FRAC(10),
                   .EXP(8), .FRAC(23)) mod(.*);
endmodule
