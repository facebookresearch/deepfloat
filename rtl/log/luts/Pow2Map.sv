// Copyright (c) Facebook, Inc. and its affiliates. All Rights Reserved.
// All rights reserved.
//
// This source code is licensed under the license found in the
// LICENSE file in the root directory of this source tree.

// Performs the log -> linear mapping
module Pow2Map #(parameter IN=4,
                 parameter OUT=8)
  (input [IN-1:0] in,
   output logic [OUT-1:0] out);

  // // Synopsys DW option: less efficient for smaller sizes
  // logic [OUT-1:0] inPad;
  // ZeroPadRight #(.IN_WIDTH(IN),
  //                .OUT_WIDTH(OUT))
  // zpr(.in(in),
  //     .out(inPad));

  // DW_exp2 #(OUT, 2, 1)
  // pow2(.a(inPad),
  //      .z(out));

// `ifdef TOOL_QUARTUS
//   // Use an explicit memory LUT for the FPGA
//   Pow2Mem #(.IN(IN),
//             .OUT(OUT))
//   pow2(.in(in),
//        .out(out));
// `else

  generate
    if (IN < 10) begin
      Pow2LUT #(.IN(IN),
                .OUT(OUT))
      pow2(.*);
    end else begin
      Pow2DeltaLUT #(.IN(IN),
                     .OUT(OUT))
      pow2(.*);
    end
  endgenerate

// `endif
endmodule
