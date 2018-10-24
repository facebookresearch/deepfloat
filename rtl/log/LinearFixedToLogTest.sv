// Copyright (c) Facebook, Inc. and its affiliates. All Rights Reserved.
// All rights reserved.
//
// This source code is licensed under the license found in the
// LICENSE file in the root directory of this source tree.

module LinearFixedToLogTestTemplate #(parameter M=3,
                                      parameter F=4,
                                      parameter LOG_TO_LINEAR_BITS=8,
                                      parameter LINEAR_TO_LOG_BITS=8)
  ();
  localparam ACC_NON_FRAC = 1 + ((2 ** (M - 1)) - 1);
  localparam ACC_FRAC = LOG_TO_LINEAR_BITS + (2 ** (M - 1));

  localparam TOTAL_ACC = 1 + ACC_NON_FRAC + ACC_FRAC;

  LogNumber #(.M(M), .F(F)) logIn();
  LogNumberUnpacked #(.M(M), .F(F)) logInDecode();

  LogNumberToLogNumberUnpacked #(.M(M),
                    .F(F))
  dec(.in(logIn),
      .out(logInDecode));

  // For debugging purposes
  Float #(.EXP(8), .FRAC(23)) logInAsFloat();

  LogToFloat #(.M(M),
               .F(F),
               .LOG_TO_LINEAR_BITS(LOG_TO_LINEAR_BITS),
               .EXP(8),
               .FRAC(23))
  l2f(.in(logInDecode),
       .out(logInAsFloat));

  Kulisch #(.ACC_NON_FRAC(ACC_NON_FRAC), .ACC_FRAC(ACC_FRAC)) linearFixed();

  LogToLinearFixed #(.M(M),
                     .F(F),
                     .LOG_TO_LINEAR_BITS(LOG_TO_LINEAR_BITS),
                     .ACC_NON_FRAC(ACC_NON_FRAC),
                     .ACC_FRAC(ACC_FRAC))
  l2lf(.in(logInDecode),
       .out(linearFixed));

  LogNumberUnpacked #(.M(M), .F(F)) logOutDecode();
  logic signed [3:0] adjustExp;

  LinearFixedToLog #(.ACC_NON_FRAC(ACC_NON_FRAC),
                     .ACC_FRAC(ACC_FRAC),
                     .M(M),
                     .F(F),
                     // We don't perform any subsequent rounding here
                     .USE_LOG_TRAILING_BITS(0),
                     .LINEAR_TO_LOG_BITS(LINEAR_TO_LOG_BITS),
                     .USE_ADJUST(1),
                     .ADJUST_EXP_SIZE(4),
                     .SATURATE_MAX(1))
  lf2log(.in(linearFixed),
         .adjustExp(adjustExp),
         .out(logOutDecode),
         .logTrailingBits());

  LogNumber #(.M(M), .F(F)) logOut();

  LogNumberUnpackedToLogNumber #(.M(M),
                                 .F(F))
  enc(.in(logOutDecode),
      .out(logOut));

  Float #(.EXP(8), .FRAC(23)) logOutFloat();

  LogToFloat #(.M(M),
               .F(F),
               .LOG_TO_LINEAR_BITS(LOG_TO_LINEAR_BITS),
               .EXP(8),
               .FRAC(23))
  toFloatA(.in(logOutDecode),
           .out(logOutFloat));

  integer i;

  initial begin
    for (i = 0; i < 2 ** (1+M+F); ++i) begin
      logIn.data = i;
      adjustExp = 4'sd0;

      #1;
      if (logIn.data != logOut.data) begin
        $display("%s (%g) -> %s (%g)",
                 logIn.print(logIn.data),
                 logInAsFloat.toReal(logInAsFloat.data),
                 logOut.print(logOut.data),
                 logOutFloat.toReal(logOutFloat.data));

        assert(logIn.data == logOut.data);
      end
    end
  end
endmodule

module LinearFixedToLogTest ();
  LinearFixedToLogTestTemplate #(.M(5),
                                 .F(4),
                                 .LOG_TO_LINEAR_BITS(8),
                                 .LINEAR_TO_LOG_BITS(8))
  t1();

  LinearFixedToLogTestTemplate #(.M(5),
                                 .F(4),
                                 .LOG_TO_LINEAR_BITS(5),
                                 .LINEAR_TO_LOG_BITS(8))
  t2();
endmodule
