// Copyright (c) Facebook, Inc. and its affiliates. All Rights Reserved.
// All rights reserved.
//
// This source code is licensed under the license found in the
// LICENSE file in the root directory of this source tree.


// A logarithmic number that represents the value (sign * -1) * 2^(logExp.logFrac)
interface LogNumberUnpacked #(parameter M=3,
                              parameter F=4);
  typedef struct packed {
    logic sign;
    logic isInf;
    logic isZero;

    // A signed exponent
    // If isInf || isZero, then this can be garbage
    logic signed [M-1:0] signedLogExp;

    // If isInf || isZero, then this can be garbage
    logic [F-1:0] logFrac;
  } Type;

  Type data;

  modport InputIf(input data,
`ifndef SYNTHESIS
                  import print,
`endif
                  import zero,
                  import inf,
                  import getMax,
                  import biasedExponent);

  modport OutputIf(output data,
`ifndef SYNTHESIS
                   import print,
`endif
                   import zero,
                   import inf,
                   import getMax,
                   import biasedExponent);

  function automatic Type zero();
    Type d;

    d.sign = 1'b0;
    d.isInf = 1'b0;
    d.isZero = 1'b1;
    d.signedLogExp = M'(1'b0);
    d.logFrac = F'(1'b0);

    return d;
  endfunction

  function automatic Type inf();
    Type d;

    d.sign = 1'b0;
    d.isInf = 1'b1;
    d.isZero = 1'b0;
    d.signedLogExp = M'(1'b0);
    d.logFrac = F'(1'b0);

    return d;
  endfunction

  function automatic Type getMax(logic sign);
    Type d;

    d.sign = sign;
    d.isInf = 1'b0;
    d.isZero = 1'b0;

    // The truncation to the true representable number happens in the log
    // encoder
    d.signedLogExp = {1'b0, {(M-1){1'b1}}};
    d.logFrac = {F{1'b1}};

    return d;
  endfunction

  function automatic logic [M-1:0] biasedExponent(Type d);
    return unsigned'(d.signedLogExp) + unsigned'(M'(2 ** (M - 1)));
  endfunction

`ifndef SYNTHESIS
  function automatic string print(Type d);
    if (d.isZero) begin
      return "zero";
    end else if (d.isInf) begin
      return "+/- inf";
    end else begin
      return $sformatf("%s2^%p.b%b",
                       d.sign ? "-" : "+",
                       d.signedLogExp,
                       d.logFrac);
    end
  endfunction
`endif
endinterface
