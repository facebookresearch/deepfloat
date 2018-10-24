// Copyright (c) Facebook, Inc. and its affiliates. All Rights Reserved.
// All rights reserved.
//
// This source code is licensed under the license found in the
// LICENSE file in the root directory of this source tree.

// Performs posit multiplication in preparation for use in a quire
module PositMultiplyForQuire #(parameter WIDTH=8,
                               parameter ES=1,
                               parameter USE_ADJUST=0,
                               parameter ADJUST_SCALE_SIZE=1)
  (PositUnpacked.InputIf a,
   PositUnpacked.InputIf b,
   input signed [ADJUST_SCALE_SIZE-1:0] adjustScale,
   output logic abIsInf,
   output logic abIsZero,
   output logic abSign,
   output logic [PositDef::getExpProductBits(WIDTH, ES)-1:0] abExp,
   output logic [PositDef::getFracProductBits(WIDTH, ES)-1:0] abFrac);

  initial begin
    assert(a.WIDTH == b.WIDTH);
    assert(a.WIDTH == WIDTH);
    assert(a.ES == b.ES);
    assert(a.ES == ES);
  end

  localparam LOCAL_FRACTION_BITS = PositDef::getFractionBits(WIDTH, ES);
  localparam LOCAL_UNSIGNED_EXPONENT_BITS = PositDef::getUnsignedExponentBits(WIDTH, ES);

  // Size of the product a * b
  localparam LOCAL_EXP_PRODUCT_BITS = PositDef::getExpProductBits(WIDTH, ES);
  localparam LOCAL_FRAC_PRODUCT_BITS = PositDef::getFracProductBits(WIDTH, ES);

  localparam LOCAL_QUIRE_MAX_UNSIGNED_EXP = PositDef::getMaxUnsignedExponent(WIDTH, ES) * 2;

  logic signed [LOCAL_EXP_PRODUCT_BITS+1-1:0] newExp;
  logic underflow;
  logic overflow;

  always_comb begin
    abIsInf = a.data.isInf || b.data.isInf;
    abIsZero = !abIsInf && (a.data.isZero || b.data.isZero);
    abSign = a.data.sign ^ b.data.sign;

    // We do not let the adjustment go below 0, or above QUIRE_MAX_UNSIGNED_EXP
    // FIXME: in either case, maybe we shouldn't do the add? Should this be done
    // in QuireAdd instead?
    if (USE_ADJUST) begin
      newExp = signed'((LOCAL_EXP_PRODUCT_BITS+1)'(a.data.exponent)) +
               signed'((LOCAL_EXP_PRODUCT_BITS+1)'(b.data.exponent)) +
               (LOCAL_EXP_PRODUCT_BITS+1)'(adjustScale);

      underflow = newExp <
                  signed'((LOCAL_EXP_PRODUCT_BITS+1)'(1'b0));
      overflow = newExp >
                 signed'((LOCAL_EXP_PRODUCT_BITS+1)'(LOCAL_QUIRE_MAX_UNSIGNED_EXP));

      unique if (underflow || abIsZero || abIsInf) begin
        abExp = LOCAL_EXP_PRODUCT_BITS'(1'b0);
      end else if (overflow) begin
        abExp = unsigned'(LOCAL_EXP_PRODUCT_BITS'(LOCAL_QUIRE_MAX_UNSIGNED_EXP));
      end else begin
        abExp = unsigned'(newExp[LOCAL_EXP_PRODUCT_BITS-1:0]);
      end
    end else begin
      if (abIsInf || abIsZero) begin
        abExp = LOCAL_EXP_PRODUCT_BITS'(1'b0);
      end else begin
        abExp = LOCAL_EXP_PRODUCT_BITS'(a.data.exponent) +
                LOCAL_EXP_PRODUCT_BITS'(b.data.exponent);
      end
    end

    // FIXME: handle posit sign / fraction encoding (2s complement)?
    abFrac = (abIsZero || abIsInf) ?
             LOCAL_FRAC_PRODUCT_BITS'(1'b0) :
             {1'b1, a.data.fraction} * {1'b1, b.data.fraction};
  end
endmodule
