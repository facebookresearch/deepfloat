// Copyright (c) Facebook, Inc. and its affiliates. All Rights Reserved.
// All rights reserved.
//
// This source code is licensed under the license found in the
// LICENSE file in the root directory of this source tree.


//
// A set of fake top-level modules that provide interface instances to module
// instances that use interfaces, so as to prevent VCS complaining
//

module UseLogNumberUnpackedToLogNumber();
  LogNumberUnpacked #(.M(3), .F(4)) in();
  LogNumber #(.M(3), .F(4)) out();

  LogNumberUnpackedToLogNumber #(.M(3), .F(4)) mod(.*);
endmodule

module UseLogNumberToLogNumberUnpacked();
  LogNumber #(.M(3), .F(4)) in();
  LogNumberUnpacked #(.M(3), .F(4)) out();

  LogNumberToLogNumberUnpacked #(.M(3), .F(4)) mod(.*);
endmodule

module UseLogToLinearFixed();
  LogNumberUnpacked #(.M(3), .F(4)) in();
  Kulisch #(.ACC_NON_FRAC(10), .ACC_FRAC(10)) out();

  LogToLinearFixed #(.M(3), .F(4), .LOG_TO_LINEAR_BITS(8),
                     .ACC_NON_FRAC(10), .ACC_FRAC(10)) mod(.*);
endmodule

module UseLogCompare();
  import Comparison::*;

  LogNumberUnpacked #(.M(3), .F(4)) a();
  LogNumberUnpacked #(.M(3), .F(4)) b();
  logic out;

  LogCompare #(.M(3), .F(4)) mod(.a, .b, .comp(EQ), .out);
endmodule

module UseLinearFixedToLog();
  Kulisch #(.ACC_NON_FRAC(10), .ACC_FRAC(10)) in();
  LogNumberUnpacked #(.M(3), .F(4)) out();

  LinearFixedToLog #(.ACC_NON_FRAC(10), .ACC_FRAC(10),
                     .M(3), .F(4), .LINEAR_TO_LOG_BITS(8))
  mod(.adjustExp(),
      .logTrailingBits(),
      .*);
endmodule

module UseLinearFixedToLogCompact();
  localparam WIDTH = 8;
  localparam LS = 1;

  localparam ACC_NON_FRAC = LogDef::getAccNonFracTapered(WIDTH, LS);
  localparam ACC_FRAC = LogDef::getAccFracTapered(WIDTH, LS);

  Kulisch #(.ACC_NON_FRAC(ACC_NON_FRAC), .ACC_FRAC(ACC_FRAC)) in();
  LogNumberCompact #(.WIDTH(WIDTH), .LS(LS)) out();

  LinearFixedToLogCompact #(.WIDTH(WIDTH),
                            .LS(LS))
  lf2lc(.in,
        .adjustExp(),
        .out);
endmodule

module UseFloatSignedNarrow();
  FloatSigned #(.EXP(8), .FRAC(10)) in();
  FloatSigned #(.EXP(8), .FRAC(8)) out();

  FloatSignedNarrow #(.IN_FRAC(10),
                      .OUT_FRAC(8),
                      .EXP(8))
  fsn(.in,
      .inTrailingBits(2'b0),
      .inStickyBit(1'b0),
      .out,
      .outTrailingBits(),
      .outStickyBit());
endmodule
