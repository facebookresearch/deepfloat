// Copyright (c) Facebook, Inc. and its affiliates. All Rights Reserved.
// All rights reserved.
//
// This source code is licensed under the license found in the
// LICENSE file in the root directory of this source tree.


module LogComp_Instance
  (input logic [CONFIG_LOG_WRAP_BITS-1:0] a,
   input logic [CONFIG_LOG_WRAP_BITS-1:0] b,
   input logic [7:0] comp,
   output logic [7:0] boolOut,
   input clock,
   input resetn,
   input ivalid,
   input iready,
   output logic ovalid,
   output logic oready);

  LogNumberCompact #(.WIDTH(CONFIG_LOG_WIDTH), .LS(CONFIG_LOG_LS)) aIf();
  LogNumberCompact #(.WIDTH(CONFIG_LOG_WIDTH), .LS(CONFIG_LOG_LS)) bIf();

  FieldRead #(.IN(CONFIG_LOG_WRAP_BITS),
              .OUT(CONFIG_LOG_WIDTH))
  fra(.in(a),
      .out(aIf.data));

  FieldRead #(.IN(CONFIG_LOG_WRAP_BITS),
              .OUT(CONFIG_LOG_WIDTH))
  frb(.in(b),
      .out(bIf.data));

  LogComp_Impl #(.WIDTH(CONFIG_LOG_WIDTH),
                   .LS(CONFIG_LOG_LS))
  lc(.inA(aIf),
     .inB(bIf),
     .*);
endmodule
