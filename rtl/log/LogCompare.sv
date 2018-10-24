// Copyright (c) Facebook, Inc. and its affiliates. All Rights Reserved.
// All rights reserved.
//
// This source code is licensed under the license found in the
// LICENSE file in the root directory of this source tree.


module LogCompare #(parameter M=3,
                    parameter F=4)
  (LogNumberUnpacked.InputIf a,
   LogNumberUnpacked.InputIf b,
   input Comparison::Type comp,
   output logic out);

  import Comparison::*;

  initial begin
    assert(a.M == M);
    assert(a.F == F);
    assert(b.M == M);
    assert(b.F == F);
  end

  logic aIsNeg;
  logic bIsNeg;

  logic abEqBits;
  logic abLtBits;
  logic abNotInf;
  logic abLt;
  logic abGt;

  always_comb begin
    aIsNeg = a.data.sign;
    bIsNeg = b.data.sign;

    abEqBits = (a.data == b.data);

    abLtBits = ((a.data.signedLogExp < b.data.signedLogExp) ||
                ((a.data.signedLogExp == b.data.signedLogExp) &&
                 (a.data.logFrac < b.data.logFrac))) &&
               (!a.data.isZero && !b.data.isZero) ||
               (a.data.isZero && !bIsNeg && !b.data.isZero) ||
               (b.data.isZero && aIsNeg && !a.data.isZero);
    // +/- inf is non-comparable except for ==, !=
    abNotInf = !a.data.isInf && !b.data.isInf;

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
