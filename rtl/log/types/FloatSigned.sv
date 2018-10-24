// Copyright (c) Facebook, Inc. and its affiliates. All Rights Reserved.
// All rights reserved.
//
// This source code is licensed under the license found in the
// LICENSE file in the root directory of this source tree.


// An expanded floating-point format without special field encodings, and one
// where the exponent is signed
interface FloatSigned #(parameter EXP=8,
                        parameter FRAC=23);
  typedef struct packed {
    logic sign;
    logic isInf;
    logic isZero;

    // The actual signed exponent 2^exp
    // If isInf || isZero, then this can be garbage
    logic signed [EXP-1:0] exp;

    // Significand with leading 1 (1.bbbb....)
    // If isInf || isZero, then this can be garbage
    logic [FRAC-1:0] frac;
  } Type;

  Type data;

  modport InputIf(input data,
`ifndef SYNTHESIS
                  import print,
`endif
                  import zero,
                  import inf,
                  import getMaxExp,
                  import getMaxFrac,
                  import getMax);

  modport OutputIf(output data,
`ifndef SYNTHESIS
                   import print,
`endif
                   import zero,
                   import inf,
                   import getMaxExp,
                   import getMaxFrac,
                   import getMax);

  function automatic Type zero(logic sign);
    Type d;
    d.sign = sign;
    d.isInf = 1'b0;
    d.isZero = 1'b1;

    d.exp = EXP'(1'b0);
    d.frac = FRAC'(1'b0);

    return d;
  endfunction

  function automatic Type inf(logic sign);
    Type d;
    d.sign = sign;
    d.isInf = 1'b1;
    d.isZero = 1'b0;

    d.exp = EXP'(1'b0);
    d.frac = FRAC'(1'b0);

    return d;
  endfunction

  function automatic logic signed [EXP-1:0] getMaxExp();
    return {1'b0, {(EXP-1){1'b1}}};
  endfunction

  function automatic logic [FRAC-1:0] getMaxFrac();
    return {FRAC{1'b1}};
  endfunction

  function automatic Type getMax(logic sign);
    Type d;
    d.sign = sign;
    d.isInf = 1'b0;
    d.isZero = 1'b0;

    d.exp = {1'b0, {(EXP-1){1'b1}}};
    d.frac = {FRAC{1'b1}};

    return d;
  endfunction

`ifndef SYNTHESIS
  function automatic string print(Type v);
    if (v.isInf) begin
      return $sformatf("[%sinf]",
                       v.sign ? "-" : "+");
    end else if (v.isZero) begin
      return "0";
    end else begin
      return $sformatf("[%sexp %p frac %b]",
                       v.sign ? "-" : "+",
                       v.exp,
                       v.frac);
    end
  endfunction
`endif
endinterface
