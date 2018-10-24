// Copyright (c) Facebook, Inc. and its affiliates. All Rights Reserved.
// All rights reserved.
//
// This source code is licensed under the license found in the
// LICENSE file in the root directory of this source tree.

// Does not perform math, but just expands an input posit for use with QuireAdd
module PositQuireConvert #(parameter WIDTH=8,
                           parameter ES=1,
                           parameter USE_ADJUST=0,
                           parameter ADJUST_SCALE_SIZE=1)
  (PositUnpacked.InputIf in,
   input signed [ADJUST_SCALE_SIZE-1:0] adjustScale,
   output logic outIsInf,
   output logic outIsZero,
   output logic outSign,
   output logic [PositDef::getExpProductBits(WIDTH, ES)-1:0] outExp,
   output logic [PositDef::getFracProductBits(WIDTH, ES)-1:0] outFrac);

  localparam LOCAL_FRACTION_BITS = PositDef::getFractionBits(WIDTH, ES);
  localparam LOCAL_UNSIGNED_EXPONENT_BITS = PositDef::getUnsignedExponentBits(WIDTH, ES);
  localparam LOCAL_EXPONENT_BIAS = PositDef::getExponentBias(WIDTH, ES);

  // Size of the product a * b that QuireAdd expects
  localparam LOCAL_EXP_PRODUCT_BITS = PositDef::getExpProductBits(WIDTH, ES);
  localparam LOCAL_FRAC_PRODUCT_BITS = PositDef::getFracProductBits(WIDTH, ES);

  localparam MAX_PRODUCT_EXP = {LOCAL_EXP_PRODUCT_BITS{1'b1}};

  logic signed [LOCAL_EXP_PRODUCT_BITS+1-1:0] newExp;
  logic underflow;
  logic overflow;

  always_comb begin
    // We do not let the adjustment go below 0, or above the largest possible
    // exponent that can fit in the product size
    // FIXME: in either case, maybe we shouldn't do the add? Should this be done
    // in QuireAdd instead?
    if (USE_ADJUST) begin
      newExp = signed'((LOCAL_EXP_PRODUCT_BITS+1)'(in.data.exponent)) +
               signed'((LOCAL_EXP_PRODUCT_BITS+1)'(LOCAL_EXPONENT_BIAS)) +
               (LOCAL_EXP_PRODUCT_BITS+1)'(adjustScale);

      underflow = newExp <
                  signed'((LOCAL_EXP_PRODUCT_BITS+1)'(1'b0));
      overflow = newExp >
                 signed'({1'b0, MAX_PRODUCT_EXP});

      unique if (underflow || in.data.isZero || in.data.isInf) begin
        outExp = LOCAL_EXP_PRODUCT_BITS'(1'b0);
      end else if (overflow) begin
        outExp = MAX_PRODUCT_EXP;
      end else begin
        outExp = newExp[LOCAL_EXP_PRODUCT_BITS-1:0];
      end
    end else begin
      // preserving the same exponent
      if (in.data.isZero || in.data.isInf) begin
        outExp = LOCAL_EXP_PRODUCT_BITS'(1'b0);
      end else begin
        outExp = LOCAL_EXP_PRODUCT_BITS'(in.data.exponent) +
                 LOCAL_EXP_PRODUCT_BITS'(LOCAL_EXPONENT_BIAS);
      end
    end

    outIsInf = in.data.isInf;
    outIsZero = in.data.isZero;
    outSign = in.data.sign;

    // FIXME: handle posit sign / fraction encoding (2s complement)?
    outFrac = (in.data.isZero || in.data.isInf) ?
              LOCAL_FRAC_PRODUCT_BITS'(1'b0) :
              {2'b01, in.data.fraction, LOCAL_FRACTION_BITS'(1'b0)};
  end
endmodule
