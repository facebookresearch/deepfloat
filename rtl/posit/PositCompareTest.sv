// Copyright (c) Facebook, Inc. and its affiliates. All Rights Reserved.
// All rights reserved.
//
// This source code is licensed under the license found in the
// LICENSE file in the root directory of this source tree.

module PositCompareTest();
  import Comparison::*;

  localparam WIDTH = 8;
  localparam ES = 1;

  PositPacked #(.WIDTH(WIDTH), .ES(ES)) a();
  PositPacked #(.WIDTH(WIDTH), .ES(ES)) b();
  Comparison::Type comp;

  logic out;

  PositComparePacked #(.WIDTH(WIDTH), .ES(ES))
  pcp(.*);

  integer i;
  integer j;
  bit eq;
  bit lt;
  bit aPos;
  bit bPos;
  bit aInf;
  bit bInf;

  task testCompare(integer i, integer j);
    a.data = i;
    b.data = j;

    eq = (i == j);

    aPos = i < (2 ** (WIDTH - 1));
    bPos = j < (2 ** (WIDTH - 1));

    aInf = i == (2 ** (WIDTH - 1));
    bInf = j == (2 ** (WIDTH - 1));

    lt = (!aPos && bPos) ||
         (aPos && bPos && i < j) ||
         (!aPos && !bPos && i > j);

    comp = EQ;
    #1;
    assert(out == eq);

    comp = NE;
    #1;
    assert(out != eq);

    if (!aInf && !bInf) begin
      comp = LT;
      #1;
      assert(out == lt);

      comp = GT;
      #1;
      assert(out == (!lt && !eq));

      comp = LE;
      #1;
      assert(out == (lt || eq));

      comp = GE;
      #1;
      assert(out == !lt);
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
      assert(out == eq);

      comp = GE;
      #1;
      assert(out == eq);
    end
  endtask

  initial begin
    for (i = 0; i < 2 ** WIDTH; ++i) begin
      for (j = 0; j < 2 ** WIDTH; ++j) begin
        testCompare(i, j);
      end
    end
  end
endmodule
