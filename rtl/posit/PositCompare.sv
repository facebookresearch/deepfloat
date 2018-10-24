// Copyright (c) Facebook, Inc. and its affiliates. All Rights Reserved.
// All rights reserved.
//
// This source code is licensed under the license found in the
// LICENSE file in the root directory of this source tree.

module PositComparePacked #(parameter WIDTH=8,
                            parameter ES=1)
  (PositPacked.InputIf a,
   PositPacked.InputIf b,
   input Comparison::Type comp,
   output logic out);

  import Comparison::*;

  // +/- inf is non-comparable except for ==, !=
  logic aIsNegOrInf;
  logic bIsNegOrInf;

  logic aIsInf;
  logic bIsInf;

  logic aIsNeg;
  logic bIsNeg;

  logic abEqBits;
  logic abLtBits;
  logic abNotInf;
  logic abLt;
  logic abGt;

  always_comb begin
    aIsNegOrInf = a.data.bits[WIDTH-1];
    bIsNegOrInf = b.data.bits[WIDTH-1];

    aIsInf = aIsNegOrInf && ~(|a.data.bits[WIDTH-2:0]);
    bIsInf = bIsNegOrInf && ~(|b.data.bits[WIDTH-2:0]);

    aIsNeg = aIsNegOrInf && !aIsInf;
    bIsNeg = bIsNegOrInf && !bIsInf;

    abEqBits = (a.data.bits == b.data.bits);
    abLtBits = a.data.bits < b.data.bits;
    abNotInf = !aIsInf && !bIsInf;

    abLt = // a neg, b pos
           // a pos, b pos, a < b
           // a neg, b neg, a > b (true for my inversion of posit layout)
           ((aIsNeg && !bIsNeg) ||
            (!aIsNeg && !bIsNeg && abLtBits) ||
            (aIsNeg && bIsNeg && !abLtBits && !abEqBits)) &&
           abNotInf;

    abGt = ((!aIsNeg && bIsNeg) ||
            (!aIsNeg && !bIsNeg && !abLtBits && !abEqBits) ||
            (aIsNeg && bIsNeg && abLtBits)) &&
           abNotInf;

    case (comp)
      NE: begin
        out = !abEqBits;
      end
      GT: begin
        out = abGt;
      end
      GE: begin
        // handles inf == inf
        out = abGt || abEqBits;
      end
      LT: begin
        out = abLt;
      end
      LE: begin
        // handles inf == inf
        out = abLt || abEqBits;
      end
      default:
      EQ: begin
        out = abEqBits;
      end
    endcase
 end
endmodule
