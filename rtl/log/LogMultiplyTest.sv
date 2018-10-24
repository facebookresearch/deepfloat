// Copyright (c) Facebook, Inc. and its affiliates. All Rights Reserved.
// All rights reserved.
//
// This source code is licensed under the license found in the
// LICENSE file in the root directory of this source tree.

module LogMultiplyTestTemplate #(parameter M=3,
                                 parameter F=4,
                                 parameter LOG_TO_LINEAR_BITS=8)
  ();
  localparam ACC_NON_FRAC = 1 + ((2 ** (M - 1)) - 1);
  localparam ACC_FRAC = LOG_TO_LINEAR_BITS + (2 ** (M - 1));

  localparam TOTAL_ACC = 1 + ACC_NON_FRAC + ACC_FRAC;

  LogNumber #(.M(M), .F(F)) logA();
  LogNumberUnpacked #(.M(M), .F(F)) logADecode();

  LogNumber #(.M(M), .F(F)) logB();
  LogNumberUnpacked #(.M(M), .F(F)) logBDecode();

  LogNumberToLogNumberUnpacked #(.M(M),
                    .F(F))
  propsA(.in(logA),
         .out(logADecode));

  LogNumberToLogNumberUnpacked #(.M(M),
                    .F(F))
  propsB(.in(logB),
         .out(logBDecode));

  LogNumberUnpacked #(.M(M), .F(F)) logCDecode();

  LogMultiply #(.M(M),
                .F(F),
                .M_OUT(M))
  mul(.a(logADecode),
      .b(logBDecode),
      .c(logCDecode));

  // Re-encode C as some values may not be representable in the output
  LogNumber #(.M(M), .F(F)) logC();
  LogNumberUnpacked #(.M(M), .F(F)) logCRoundedDecode();

  LogNumberUnpackedToLogNumber #(.M(M),
                                 .F(F))
  encC(.in(logCDecode),
       .out(logC));

  LogNumberToLogNumberUnpacked #(.M(M),
                                 .F(F))
  decC(.in(logC),
       .out(logCRoundedDecode));

  Float #(.EXP(8), .FRAC(23)) floatOut();

  LogToFloat #(.M(M),
               .F(F),
               .LOG_TO_LINEAR_BITS(LOG_TO_LINEAR_BITS),
               .EXP(8),
               .FRAC(23))
  l2f(.in(logCRoundedDecode),
      .out(floatOut));

  Float #(.EXP(8), .FRAC(23)) floatA();

  LogToFloat #(.M(M),
               .F(F),
               .LOG_TO_LINEAR_BITS(LOG_TO_LINEAR_BITS),
               .EXP(8),
               .FRAC(23))
  toFloatA(.in(logADecode),
           .out(floatA));

  Float #(.EXP(8), .FRAC(23)) floatB();

  LogToFloat #(.M(M),
               .F(F),
               .LOG_TO_LINEAR_BITS(LOG_TO_LINEAR_BITS),
               .EXP(8),
               .FRAC(23))
  toFloatB(.in(logBDecode),
           .out(floatB));

  integer i;
  integer j;

  real floatReps[$];

  // map real to index
  integer realToIndex[*];

  real prev;
  real next;

  real mulResult;
  real correctResult;

  integer idx;

  initial begin
    // collect and sort all float representations
    for (i = 0; i < 2 ** (M+F+1); ++i) begin
      logA.data = i;
      #1;
      floatReps.push_back(floatA.toReal(floatA.data));
    end

    floatReps.sort();

    for (i = 0; i < floatReps.size(); ++i) begin
      realToIndex[$realtobits(floatReps[i])] = i;
    end

    // Try all pairs of multiplication arguments
    for (i = 0; i < 2 ** (M+F+1); ++i) begin
      for (j = 0; j < 2 ** (M+F+1); ++j) begin
        logA.data = i;
        logB.data = j;

        #1;

        mulResult = floatOut.toReal(floatOut.data);
        correctResult = floatA.toReal(floatA.data) *
                        floatB.toReal(floatB.data);

        idx = realToIndex[$realtobits(mulResult)];

        if (idx == 0) begin
          // This is the smallest negative value
          prev = -1.0e9;
          next = floatReps[1];

        end else if (idx == (2 ** (M+F+1) - 2)) begin
          // This is the largest positive value
          prev = floatReps[idx - 1];
          next = 1.0e9;

        end else if (idx == (2 ** (M+F+1) - 1)) begin
          // This is inf
          assert(floatOut.isInf(floatOut.data));

          // The correct result can be -inf or nan (0 x inf)
          // whereas we just have +/- inf
          assert($realtobits(mulResult) == $realtobits(correctResult) ||
                 $realtobits(-mulResult) == $realtobits(correctResult) ||
                 (floatA.isInf(floatA.data) || floatB.isInf(floatB.data)));

          continue;
        end else begin
          prev = floatReps[idx - 1];
          next = floatReps[idx + 1];
        end

        assert(prev <= correctResult);
        assert(correctResult <= next);
        assert((mulResult >= 0 && correctResult >= 0) ||
               (mulResult < 0 && correctResult < 0) ||
               // our zero has no sign
               (mulResult == 0));

        // $display("log %s (%d) x %s (%d) -> %s (%d) lin (%g)",
        //          logADecode.print(logADecode.data), logA.data,
        //          logBDecode.print(logBDecode.data), logB.data,
        //          logCDecode.print(logCDecode.data), logC.data,
        //          floatOut.toReal(floatOut.data));
        // $display("log %g x %g -> %g (vs %g)",
        //          floatA.toReal(floatA.data),
        //          floatB.toReal(floatB.data),
        //          floatOut.toReal(floatOut.data),
        //          floatA.toReal(floatA.data) * floatB.toReal(floatB.data));
      end
    end
  end
endmodule

module LogMultiplyTest();
  LogMultiplyTestTemplate #(.M(3), .F(4), .LOG_TO_LINEAR_BITS(8)) t1();
endmodule
