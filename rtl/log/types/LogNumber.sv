// Copyright (c) Facebook, Inc. and its affiliates. All Rights Reserved.
// All rights reserved.
//
// This source code is licensed under the license found in the
// LICENSE file in the root directory of this source tree.


// A logarithmic number that represents the value (sign * -1) * 2^(logExp.logFrac)
// zero is the value    (M+F+1)'b0111...1
// +/- inf is the value (M+F+1)'b1111...1
interface LogNumber #(parameter M=3,
                      parameter F=4);
  typedef struct packed {
    logic sign;
    logic [M-1:0] logExp;
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
                  import isZeroOrInf,
                  import isZero,
                  import isInf,
                  import signedExponent);

  modport OutputIf(output data,
`ifndef SYNTHESIS
                   import print,
`endif
                   import zero,
                   import inf,
                   import getMax,
                   import isZeroOrInf,
                   import isZero,
                   import isInf,
                   import signedExponent);

  function automatic Type zero();
    Type d;

    d.sign = 1'b0;
    d.logExp = {M{1'b1}};
    d.logFrac = {F{1'b1}};

    return d;
  endfunction

  function automatic Type inf();
    Type d;

    d.sign = 1'b1;
    d.logExp = {M{1'b1}};
    d.logFrac = {F{1'b1}};

    return d;
  endfunction

  function automatic Type getMax(logic sign);
    Type d;

    d.sign = sign;
    d.logExp = {M{1'b1}};
    d.logFrac = {{(F-1){1'b1}}, 1'b0};

    return d;
  endfunction

  function automatic logic isZeroOrInf(Type d);
    return d.logExp == {M{1'b1}} && d.logFrac == {F{1'b1}};
  endfunction

  function automatic logic isZero(Type d);
    return isZeroOrInf(d) && !d.sign;
  endfunction

  function automatic logic isInf(Type d);
    return isZeroOrInf(d) && d.sign;
  endfunction

  function automatic logic signed [M-1:0] signedExponent(Type d);
    return signed'(d.logExp - M'(2 ** (M - 1)));
  endfunction

`ifndef SYNTHESIS
  function automatic string print(Type d);
    if (isZero(d)) begin
      return "zero";
    end else if (isInf(d)) begin
      return "+/- inf";
    end else begin
      return $sformatf("%s(2^%p.b%b) (%p)",
                       d.sign ? "-" : "+",
                       integer'(d.logExp) - (2 ** (M - 1)),
                       d.logFrac,
                       (M+F+1)'(d));
    end
  endfunction
`endif
endinterface
