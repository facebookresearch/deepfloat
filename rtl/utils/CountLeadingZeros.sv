// Copyright (c) Facebook, Inc. and its affiliates. All Rights Reserved.
// All rights reserved.
//
// This source code is licensed under the license found in the
// LICENSE file in the root directory of this source tree.

module CountLeadingZerosTree #(parameter L=8, parameter R=8)
  (input [L-1:0] left,
   input [R-1:0] right,
   output logic [$clog2(L+R+1)-1:0] out);

  // L is always a power of 2; R might not be
  localparam L2 = L / 2;

  // The new L for the right-hand recursion should be a power of 2 as
  // well
  localparam R2A = Functions::largestPowerOf2Divisor(R);

  // floor(R / 2)
  localparam R2B = R - R2A;

  initial begin
    assert(L > 0);
    assert(R > 0);
    assert($clog2(L) == $clog2(L+1) - 1);
    assert(L >= R);
  end

  logic [$clog2(L+1)-1:0] lCount;
  logic [$clog2(R+1)-1:0] rCount;

  logic [$clog2(L+1)-1:0] rCountExtend;

  genvar i;

  generate
    assign rCountExtend[$clog2(R+1)-1:0] = rCount;

    for (i = $clog2(L+1)-1; i > $clog2(R+1)-1; --i) begin : extend
      assign rCountExtend[i] = 1'b0;
    end

    if (L >= 2) begin : lBranch
      CountLeadingZerosTree #(.L(L2), .R(L2))
      leftCount(left[(L-1)-:L2], left[L2-1:0], lCount);
    end else begin : lLeaf
      always_comb begin
        lCount = ~left[0];
      end
    end

    if (R >= 2) begin : rBranch
      CountLeadingZerosTree #(.L(R2A), .R(R2B))
      leftCount(right[(R-1)-:R2A], right[R2B-1:0], rCount);
    end else begin : rLeaf
      always_comb begin
        rCount = ~right[0];
      end
    end

    if ($clog2(L+1) > 1) begin : makeCount1
      always_comb begin
        if (lCount[$clog2(L+1)-1] && rCountExtend[$clog2(L+1)-1]) begin
          out = {1'b1, {($clog2(L+R+1)-1){1'b0}}};
        end else if (!lCount[$clog2(L+1)-1]) begin
          out = {1'b0, lCount};
        end else begin
          out = {2'b01, rCountExtend[$clog2(L+1)-2:0]};
        end

        // $display("%d %d: left %b right %b lcount %b rcount %b rcountext %b out %b",
        //          L, R, left, right, lCount, rCount, rCountExtend, out);
      end
    end else begin : makeCount2
      always_comb begin
        if (lCount[$clog2(L+1)-1] && rCountExtend[$clog2(L+1)-1]) begin
          out = {1'b1, {($clog2(L+R+1)-1){1'b0}}};
        end else if (!lCount[$clog2(L+1)-1]) begin
          out = {1'b0, lCount};
        end else begin
          out = {2'b01};
        end

        // $display("%d %d: left %b right %b lcount %b rcount %b rcountext %b out %b",
        //          L, R, left, right, lCount, rCount, rCountExtend, out);
      end
    end
  endgenerate
endmodule

// ADD_OFFSET is in effect a constant added to `out`, so as to avoid an
// additional adder in a case where one wants to shift past a leading 1, for
// example
module CountLeadingZeros #(parameter WIDTH=6,
                           parameter ADD_OFFSET=0)
  (input [WIDTH-1:0] in,
   output logic [$clog2(WIDTH+1+ADD_OFFSET)-1:0] out);

  // What's the largest power of 2 divisor of WIDTH?
  localparam L = Functions::largestPowerOf2Divisor(WIDTH + ADD_OFFSET);
  localparam R = WIDTH + ADD_OFFSET - L;

  initial begin
    assert(L >= R);
    assert(L > 0);
    assert(R > 0);
  end

  logic [WIDTH+ADD_OFFSET-1:0] inPad;

  genvar i;
  generate
    for (i = WIDTH+ADD_OFFSET-1; i >= WIDTH; --i) begin : in_pad
      assign inPad[i] = 1'b0;
    end

    assign inPad[WIDTH-1:0] = in;
  endgenerate

  CountLeadingZerosTree #(.L(L), .R(R))
  tree(inPad[(WIDTH+ADD_OFFSET-1)-:L], in[R-1:0], out);
endmodule
