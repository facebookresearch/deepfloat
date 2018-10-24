// Copyright (c) Facebook, Inc. and its affiliates. All Rights Reserved.
// All rights reserved.
//
// This source code is licensed under the license found in the
// LICENSE file in the root directory of this source tree.


// A logarithmic number that represents the value (sign * -1) *
// 2^(logExp.logFrac) encoded using a posit-like Golomb-Rice prefix-free code
interface LogNumberCompact #(parameter WIDTH=8,
                             parameter LS=1);
  // Packed form of a log compact number
  typedef struct packed {
    logic [WIDTH-1:0] bits;
  } Type;

  Type data;

  modport InputIf (input data, import zero, import inf);
  modport OutputIf (output data, import zero, import inf);

  // Returns a LogCompact with value 0
  function automatic Type zero();
    Type v;
    v.bits = {WIDTH{1'b0}};

    return v;
  endfunction

  // Returns a LogCompact with value 1
  function automatic Type one(logic sign);
    Type v;
    v.bits = {sign, 1'b1, (WIDTH-2)'(1'b0)};

    return v;
  endfunction

  // Returns a LogCompact with value +/- inf
  function automatic Type inf();
    Type v;
    v.bits = {1'b1, {WIDTH-1{1'b0}}};

    return v;
  endfunction
endinterface
