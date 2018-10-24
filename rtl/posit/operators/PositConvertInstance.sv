// Copyright (c) Facebook, Inc. and its affiliates. All Rights Reserved.
// All rights reserved.
//
// This source code is licensed under the license found in the
// LICENSE file in the root directory of this source tree.


module PositToFloat_Instance
  (input logic [CONFIG_POSIT_WRAP_BITS-1:0] positIn,
   input logic signed [7:0] expAdjust,
   output logic [31:0] floatOut,
   input clock,
   input resetn,
   input ivalid,
   input iready,
   output logic ovalid,
   output logic oready);

  PositPacked #(.WIDTH(CONFIG_POSIT_WIDTH), .ES(CONFIG_POSIT_ES)) positInIf();

  FieldRead #(.IN(CONFIG_POSIT_WRAP_BITS),
              .OUT(CONFIG_POSIT_WIDTH))
  fr(.in(positIn),
     .out(positInIf.data));

  // Use a narrower expAdjust
  PositToFloat_Impl #(.WIDTH(CONFIG_POSIT_WIDTH),
                      .ES(CONFIG_POSIT_ES),
                      .EXP_ADJUST_BITS(4),
                      .EXP_ADJUST(1))
  p2f(.positIn(positInIf),
      .expAdjust(expAdjust[3:0]),
      .floatOut,
      .clock,
      .resetn,
      .ivalid,
      .iready,
      .ovalid,
      .oready);
endmodule

module FloatToPosit_Instance
  (input [31:0] floatIn,
   input logic signed [7:0] expAdjust,
   output logic [CONFIG_POSIT_WRAP_BITS-1:0] positOut,
   input clock,
   input resetn,
   input ivalid,
   input iready,
   output logic ovalid,
   output logic oready);

  PositPacked #(.WIDTH(CONFIG_POSIT_WIDTH), .ES(CONFIG_POSIT_ES)) positOutIf();

  FieldWrite #(.IN(CONFIG_POSIT_WIDTH),
               .OUT(CONFIG_POSIT_WRAP_BITS))
  fw(.in(positOutIf.data),
     .out(positOut));

  // Use a narrower expAdjust
  FloatToPosit_Impl #(.WIDTH(CONFIG_POSIT_WIDTH),
                      .ES(CONFIG_POSIT_ES),
                      .EXP_ADJUST_BITS(4),
                      .EXP_ADJUST(1))
  f2p(.floatIn,
      .expAdjust(expAdjust[3:0]),
      .positOut(positOutIf),
      .clock,
      .resetn,
      .ivalid,
      .iready,
      .ovalid,
      .oready);
endmodule
