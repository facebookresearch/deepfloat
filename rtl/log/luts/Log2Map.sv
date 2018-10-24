// Copyright (c) Facebook, Inc. and its affiliates. All Rights Reserved.
// All rights reserved.
//
// This source code is licensed under the license found in the
// LICENSE file in the root directory of this source tree.

// Performs the linear -> log mapping
module Log2Map #(parameter IN=8,
                 parameter OUT=4)
  (input [IN-1:0] in,
   output logic [OUT:0] out);

// `ifdef TOOL_QUARTUS
//   // Use an explicit memory LUT for the FPGA
//   Log2Mem #(.IN(IN),
//             .OUT(OUT))
//   log2(.in(in),
//        .out(out));
// `else

  generate
    if (IN < 10) begin
      Log2LUT #(.IN(IN),
                .OUT(OUT))
      log2(.*);
    end else begin
      Log2DeltaLUT #(.IN(IN),
                     .OUT(OUT))
      log2(.*);
    end
  endgenerate

// `endif
endmodule
