// Copyright (c) Facebook, Inc. and its affiliates. All Rights Reserved.
// All rights reserved.
//
// This source code is licensed under the license found in the
// LICENSE file in the root directory of this source tree.

module LogPropertiesInstance #(parameter WIDTH=8,
                               parameter LS=1)
  ();

  localparam ACC_NON_FRAC = LogDef::getAccNonFracTapered(WIDTH, LS);
  localparam ACC_FRAC = LogDef::getAccFracTapered(WIDTH, LS);

  localparam M = PositDef::getSignedExponentBits(WIDTH, LS);
  localparam F = PositDef::getFractionBits(WIDTH, LS);

  Kulisch #(.ACC_NON_FRAC(ACC_NON_FRAC), .ACC_FRAC(ACC_FRAC)) accDef();
  LogNumberUnpacked #(.M(M), .F(F)) logDef();

  initial begin
    $write("[[%p, %p], [log M %p F %p up size %p, acc fp bits %p, acc div cycles %p, acc total bits %p]\n",
           WIDTH, LS,
           M, F,
           $bits(logDef.data),
           // total bits in fixed point accumulator
           KulischDef::getBits(ACC_NON_FRAC, ACC_FRAC),
           // fixed point div time
           KulischDef::getBits(ACC_NON_FRAC, ACC_FRAC) + 2,
           // total Kulisch bits
           $bits(accDef.data));
  end
endmodule

module LogProperties();
  LogPropertiesInstance #(.WIDTH(8), .LS(0)) p8_0();
  LogPropertiesInstance #(.WIDTH(8), .LS(1)) p8_1();
  LogPropertiesInstance #(.WIDTH(8), .LS(2)) p8_2();
  LogPropertiesInstance #(.WIDTH(10), .LS(0)) p10_0();
  LogPropertiesInstance #(.WIDTH(10), .LS(1)) p10_1();
  LogPropertiesInstance #(.WIDTH(12), .LS(0)) p12_0();
  LogPropertiesInstance #(.WIDTH(12), .LS(1)) p12_1();
  LogPropertiesInstance #(.WIDTH(14), .LS(0)) p14_0();
  LogPropertiesInstance #(.WIDTH(14), .LS(1)) p14_1();
  LogPropertiesInstance #(.WIDTH(16), .LS(0)) p16_0();
  LogPropertiesInstance #(.WIDTH(16), .LS(1)) p16_1();
  LogPropertiesInstance #(.WIDTH(32), .LS(1)) p32_1();
  LogPropertiesInstance #(.WIDTH(32), .LS(2)) p32_2();

  LogPropertiesInstance #(.WIDTH(64), .LS(1)) p64_1();
  LogPropertiesInstance #(.WIDTH(64), .LS(2)) p64_2();
  LogPropertiesInstance #(.WIDTH(64), .LS(3)) p64_3();
endmodule
