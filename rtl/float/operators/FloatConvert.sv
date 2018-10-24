// Copyright (c) Facebook, Inc. and its affiliates. All Rights Reserved.
// All rights reserved.
//
// This source code is licensed under the license found in the
// LICENSE file in the root directory of this source tree.


module FloatContract_Impl #(parameter EXP_IN=8,
                            parameter FRAC_IN=23,
                            parameter EXP_OUT=4,
                            parameter FRAC_OUT=3,
                            parameter SATURATE_TO_MAX_FLOAT=1)
  (Float.InputIf in,
   Float.OutputIf out,
   input clock,
   input resetn,
   input ivalid,
   input iready,
   output logic ovalid,
   output logic oready);

  initial begin
    assert(in.EXP == EXP_IN);
    assert(in.FRAC == FRAC_IN);
    assert(out.EXP == EXP_OUT);
    assert(out.FRAC == FRAC_OUT);
  end

  // 1. Narrow float
  Float #(.EXP(EXP_OUT), .FRAC(FRAC_OUT)) unrounded();
  Float #(.EXP(EXP_OUT), .FRAC(FRAC_OUT)) unroundedReg();

  logic [1:0] trailingBits;
  logic [1:0] trailingBitsReg;
  logic stickyBit;
  logic stickyBitReg;
  logic isNan;
  logic isNanReg;

  FloatContract #(.EXP_IN(EXP_IN),
                  .FRAC_IN(FRAC_IN),
                  .EXP_OUT(EXP_OUT),
                  .FRAC_OUT(FRAC_OUT),
                  .TRAILING_BITS(2),
                  .SATURATE_TO_MAX_FLOAT(SATURATE_TO_MAX_FLOAT))
  fc(.in(in),
     .out(unrounded),
     .trailingBitsOut(trailingBits),
     .stickyBitOut(stickyBit),
     .isNanOut(isNan));

  // 2. r2ne
  Float #(.EXP(EXP_OUT), .FRAC(FRAC_OUT)) rounded();

  FloatRoundToNearestEven #(.EXP(EXP_OUT),
                            .FRAC(FRAC_OUT))
  r2ne(.in(unroundedReg),
       .trailingBitsIn(trailingBitsReg),
       .stickyBitIn(stickyBitReg),
       .isNanIn(isNanReg),
       .out(rounded));

  always_comb begin
    oready = 1'b1;
    ovalid = 1'b1;
  end

  always_ff @(posedge clock) begin
    if (!resetn) begin
      // 1.
      unroundedReg.data <= out.getZero(1'b0);
      trailingBitsReg <= 2'b0;
      stickyBitReg <= 1'b0;
      isNanReg <= 1'b0;

      // 2.
      out.data <= out.getZero(1'b0);
    end
    else begin
      // 1.
      unroundedReg.data <= unrounded.data;
      trailingBitsReg <= trailingBits;
      stickyBitReg <= stickyBit;
      isNanReg <= isNan;

      // 2.
      out.data <= rounded.data;
    end
  end
endmodule

module FloatExpand_Impl #(parameter EXP_IN=4,
                          parameter FRAC_IN=3,
                          parameter EXP_OUT=8,
                          parameter FRAC_OUT=23)
  (Float.InputIf in,
   Float.OutputIf out,
   input clock,
   input resetn,
   input ivalid,
   input iready,
   output logic ovalid,
   output logic oready);

  initial begin
    assert(in.EXP == EXP_IN);
    assert(in.FRAC == FRAC_IN);
    assert(out.EXP == EXP_OUT);
    assert(out.FRAC == FRAC_OUT);
  end

  Float #(.EXP(EXP_OUT), .FRAC(FRAC_OUT)) expand();

  FloatExpand #(.EXP_IN(EXP_IN),
                .FRAC_IN(FRAC_IN),
                .EXP_OUT(EXP_OUT),
                .FRAC_OUT(FRAC_OUT))
  fe(.in(in),
     .out(expand),
     .isInf(),
     .isNan(),
     .isZero(),
     .isDenormal());

  always_comb begin
    oready = 1'b1;
    ovalid = 1'b1;
  end

  always_ff @(posedge clock) begin
    if (!resetn) begin
      // 1
      out.data <= out.getZero(1'b0);
    end
    else begin
      // 1
      out.data <= expand.data;
    end
  end
endmodule

module FloatContract_4_3
  (input [31:0] floatIn,
   output logic [7:0] floatOut,
   input clock,
   input resetn,
   input ivalid,
   input iready,
   output logic ovalid,
   output logic oready);
  Float #(.EXP(8), .FRAC(23)) in();
  Float #(.EXP(4), .FRAC(3)) out();

  always_comb begin
    in.data = floatIn;
    floatOut = out.data;
  end

  FloatContract_Impl #(.EXP_IN(8),
                       .FRAC_IN(23),
                       .EXP_OUT(4),
                       .FRAC_OUT(3),
                       .SATURATE_TO_MAX_FLOAT(1))
  fc(.*);
endmodule

module FloatContract_3_4
  (input [31:0] floatIn,
   output logic [7:0] floatOut,
   input clock,
   input resetn,
   input ivalid,
   input iready,
   output logic ovalid,
   output logic oready);
  Float #(.EXP(8), .FRAC(23)) in();
  Float #(.EXP(3), .FRAC(4)) out();

  always_comb begin
    in.data = floatIn;
    floatOut = out.data;
  end

  FloatContract_Impl #(.EXP_IN(8),
                       .FRAC_IN(23),
                       .EXP_OUT(3),
                       .FRAC_OUT(4),
                       .SATURATE_TO_MAX_FLOAT(1))
  fc(.*);
endmodule

module FloatExpand_4_3
  (input [7:0] floatIn,
   output logic [31:0] floatOut,
   input clock,
   input resetn,
   input ivalid,
   input iready,
   output logic ovalid,
   output logic oready);
  Float #(.EXP(4), .FRAC(3)) in();
  Float #(.EXP(8), .FRAC(23)) out();

  always_comb begin
    in.data = floatIn;
    floatOut = out.data;
  end

  FloatExpand_Impl #(.EXP_IN(4),
                     .FRAC_IN(3),
                     .EXP_OUT(8),
                     .FRAC_OUT(23))
  fe(.*);
endmodule

module FloatExpand_3_4
  (input [7:0] floatIn,
   output logic [31:0] floatOut,
   input clock,
   input resetn,
   input ivalid,
   input iready,
   output logic ovalid,
   output logic oready);
  Float #(.EXP(3), .FRAC(4)) in();
  Float #(.EXP(8), .FRAC(23)) out();

  always_comb begin
    in.data = floatIn;
    floatOut = out.data;
  end

  FloatExpand_Impl #(.EXP_IN(3),
                     .FRAC_IN(4),
                     .EXP_OUT(8),
                     .FRAC_OUT(23))
  fe(.*);
endmodule
