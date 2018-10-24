// Copyright (c) Facebook, Inc. and its affiliates. All Rights Reserved.
// All rights reserved.
//
// This source code is licensed under the license found in the
// LICENSE file in the root directory of this source tree.


module LogToFloat_Instance
  (input logic [CONFIG_LOG_WRAP_BITS-1:0] vIn,
   output logic [31:0] floatOut,
   input clock,
   input resetn,
   input ivalid,
   input iready,
   output logic ovalid,
   output logic oready);

  LogNumberCompact #(.WIDTH(CONFIG_LOG_WIDTH), .LS(CONFIG_LOG_LS)) vInIf();

  always_comb begin
    vInIf.data.bits = vIn;
  end

  LogToFloat_Impl #(.WIDTH(CONFIG_LOG_WIDTH),
                    .LS(CONFIG_LOG_LS))
  l2f(.vIn(vInIf),
      .floatOut,
      .clock,
      .resetn,
      .ivalid,
      .iready,
      .ovalid,
      .oready);
endmodule

module FloatToLog_Instance
  (input [31:0] floatIn,
   output logic [CONFIG_LOG_WRAP_BITS-1:0] vOut,
   input clock,
   input resetn,
   input ivalid,
   input iready,
   output logic ovalid,
   output logic oready);

  LogNumberCompact #(.WIDTH(CONFIG_LOG_WIDTH), .LS(CONFIG_LOG_LS)) vOutIf();

  FieldWrite #(.IN(CONFIG_LOG_WIDTH),
               .OUT(CONFIG_LOG_WRAP_BITS))
  fw(.in(vOutIf.data),
     .out(vOut));

  FloatToLog_Impl #(.WIDTH(CONFIG_LOG_WIDTH),
                    .LS(CONFIG_LOG_LS))
  l2p(.floatIn,
      .vOut(vOutIf),
      .clock,
      .resetn,
      .ivalid,
      .iready,
      .ovalid,
      .oready);
endmodule
