// Copyright (c) Facebook, Inc. and its affiliates. All Rights Reserved.
// All rights reserved.
//
// This source code is licensed under the license found in the
// LICENSE file in the root directory of this source tree.

module LogCompareTest();
  import Comparison::*;

  localparam M = 2;
  localparam F = 4;
  localparam LOG_TO_LINEAR_BITS = 8;

  LogNumber #(.M(M), .F(F)) logA();
  LogNumberUnpacked #(.M(M), .F(F)) logADecoded();

  LogNumberToLogNumberUnpacked #(.M(M),
                                 .F(F))
  decA(.in(logA),
       .out(logADecoded));

  LogNumber #(.M(M), .F(F)) logB();
  LogNumberUnpacked #(.M(M), .F(F)) logBDecoded();

  LogNumberToLogNumberUnpacked #(.M(M),
                                 .F(F))
  decB(.in(logB),
       .out(logBDecoded));

  Comparison::Type comp;
  logic out;

  LogCompare #(.M(M),
               .F(F))
  lc(.a(logADecoded),
     .b(logBDecoded),
     .comp(comp),
     .out(out));

  Float #(.EXP(8), .FRAC(23)) floatA();
  Float #(.EXP(8), .FRAC(23)) floatB();

  LogToFloat #(.M(M),
               .F(F),
               .LOG_TO_LINEAR_BITS(LOG_TO_LINEAR_BITS),
               .EXP(8),
               .FRAC(23))
  l2fa(.in(logADecoded),
       .out(floatA));

  LogToFloat #(.M(M),
               .F(F),
               .LOG_TO_LINEAR_BITS(LOG_TO_LINEAR_BITS),
               .EXP(8),
               .FRAC(23))
  l2fb(.in(logBDecoded),
       .out(floatB));

  integer i;
  integer j;
  bit testComp;

  initial begin

    for (i = 0; i < 2 ** (M+F+1); ++i) begin
      for (j = 0; j < 2 ** (M+F+1); ++j) begin
        logA.data = i;
        logB.data = j;

        comp = EQ;
        #1;
        testComp = (floatA.toReal(floatA.data) ==
                    floatB.toReal(floatB.data));
        assert(out == testComp);

        comp = NE;
        #1;
        testComp = (floatA.toReal(floatA.data) !=
                    floatB.toReal(floatB.data));
        assert(out == testComp);

        if (!logA.isInf(logA.data) && !logB.isInf(logB.data)) begin
          comp = LT;
          #1;
          testComp = (floatA.toReal(floatA.data) <
                      floatB.toReal(floatB.data));
          assert(out == testComp);

          comp = GT;
          #1;
          testComp = (floatA.toReal(floatA.data) >
                      floatB.toReal(floatB.data));
          assert(out == testComp);

          comp = LE;
          #1;
          testComp = (floatA.toReal(floatA.data) <=
                      floatB.toReal(floatB.data));
          assert(out == testComp);

          comp = GE;
          #1;
          testComp = (floatA.toReal(floatA.data) >=
                      floatB.toReal(floatB.data));
          assert(out == testComp);
        end
        else begin
          comp = LT;
          #1;
          assert(!out);

          comp = GT;
          #1;
          assert(!out);

          comp = LE;
          #1;
          testComp = (floatA.toReal(floatA.data) ==
                      floatB.toReal(floatB.data));
          assert(out == testComp);

          comp = GE;
          #1;
          testComp = (floatA.toReal(floatA.data) ==
                      floatB.toReal(floatB.data));
          assert(out == testComp);
        end
      end
    end
  end
endmodule
