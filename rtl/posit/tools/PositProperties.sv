// Copyright (c) Facebook, Inc. and its affiliates. All Rights Reserved.
// All rights reserved.
//
// This source code is licensed under the license found in the
// LICENSE file in the root directory of this source tree.

module PositPropertiesInstance #(parameter WIDTH=8,
                                 parameter ES=1,
                                 parameter OVERFLOW=0,
                                 parameter FRAC_REDUCE=0)
  ();

  localparam ACC_NON_FRAC = QuireDef::getNonFracBits(WIDTH, ES,
                                                     OVERFLOW, FRAC_REDUCE);
  localparam ACC_FRAC = QuireDef::getFracBits(WIDTH, ES, OVERFLOW);


  Kulisch #(.ACC_NON_FRAC(ACC_NON_FRAC), .ACC_FRAC(ACC_FRAC)) accDef();
  PositUnpacked #(.WIDTH(WIDTH), .ES(ES)) positDef();

  initial begin
    $write("[[%p, %p], [posit up size %p, frac prod %p, exp prod %p, pdiv %p, qb %p, qdiv %p, totalq %p]\n",
           WIDTH, ES,
           $bits(positDef.data),
           PositDef::getFracProductBits(WIDTH, ES),
           PositDef::getExpProductBits(WIDTH, ES),
           3 + 2 * PositDef::getFractionBits(WIDTH, ES) + 2 + 1,
           // total bits in fixed point accumulator
           KulischDef::getBits(ACC_NON_FRAC,
                               ACC_FRAC),
           // fixed point div time
           KulischDef::getBits(ACC_NON_FRAC, ACC_FRAC) + 2,
           // total Kulisch bits
           $bits(accDef.data));
  end
endmodule

module PositProperties();
  localparam OVERFLOW = 0;

  PositPropertiesInstance #(.WIDTH(4), .ES(0), .OVERFLOW(OVERFLOW)) p4_0();
  PositPropertiesInstance #(.WIDTH(4), .ES(1), .OVERFLOW(OVERFLOW)) p4_1();
  PositPropertiesInstance #(.WIDTH(5), .ES(0), .OVERFLOW(OVERFLOW)) p5_0();
  PositPropertiesInstance #(.WIDTH(5), .ES(1), .OVERFLOW(OVERFLOW)) p5_1();
  PositPropertiesInstance #(.WIDTH(6), .ES(0), .OVERFLOW(OVERFLOW)) p6_0();
  PositPropertiesInstance #(.WIDTH(6), .ES(1), .OVERFLOW(OVERFLOW)) p6_1();
  PositPropertiesInstance #(.WIDTH(7), .ES(0), .OVERFLOW(OVERFLOW)) p7_0();
  PositPropertiesInstance #(.WIDTH(7), .ES(1), .OVERFLOW(OVERFLOW)) p7_1();
  PositPropertiesInstance #(.WIDTH(8), .ES(0), .OVERFLOW(OVERFLOW)) p8_0();
  PositPropertiesInstance #(.WIDTH(8), .ES(1), .OVERFLOW(OVERFLOW)) p8_1();
  PositPropertiesInstance #(.WIDTH(8), .ES(2), .OVERFLOW(OVERFLOW)) p8_2();
  PositPropertiesInstance #(.WIDTH(9), .ES(0), .OVERFLOW(OVERFLOW)) p9_0();
  PositPropertiesInstance #(.WIDTH(9), .ES(1), .OVERFLOW(OVERFLOW)) p9_1();
  PositPropertiesInstance #(.WIDTH(10), .ES(0), .OVERFLOW(OVERFLOW)) p10_0();
  PositPropertiesInstance #(.WIDTH(10), .ES(1), .OVERFLOW(OVERFLOW)) p10_1();
  PositPropertiesInstance #(.WIDTH(11), .ES(0), .OVERFLOW(OVERFLOW)) p11_0();
  PositPropertiesInstance #(.WIDTH(11), .ES(1), .OVERFLOW(OVERFLOW)) p11_1();
  PositPropertiesInstance #(.WIDTH(12), .ES(0), .OVERFLOW(OVERFLOW)) p12_0();
  PositPropertiesInstance #(.WIDTH(12), .ES(1), .OVERFLOW(OVERFLOW)) p12_1();
  PositPropertiesInstance #(.WIDTH(14), .ES(0), .OVERFLOW(OVERFLOW)) p14_0();
  PositPropertiesInstance #(.WIDTH(14), .ES(1), .OVERFLOW(OVERFLOW)) p14_1();
  PositPropertiesInstance #(.WIDTH(16), .ES(0), .OVERFLOW(OVERFLOW)) p16_0();
  PositPropertiesInstance #(.WIDTH(16), .ES(1), .OVERFLOW(OVERFLOW)) p16_1();
  PositPropertiesInstance #(.WIDTH(32), .ES(1), .OVERFLOW(OVERFLOW)) p32_1();
  PositPropertiesInstance #(.WIDTH(32), .ES(2), .OVERFLOW(OVERFLOW)) p32_2();
  PositPropertiesInstance #(.WIDTH(64), .ES(1), .OVERFLOW(OVERFLOW)) p64_1();
  PositPropertiesInstance #(.WIDTH(64), .ES(2), .OVERFLOW(OVERFLOW)) p64_2();
  PositPropertiesInstance #(.WIDTH(64), .ES(3), .OVERFLOW(OVERFLOW)) p64_3();
endmodule
