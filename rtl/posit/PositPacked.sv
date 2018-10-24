// Copyright (c) Facebook, Inc. and its affiliates. All Rights Reserved.
// All rights reserved.
//
// This source code is licensed under the license found in the
// LICENSE file in the root directory of this source tree.

interface PositPacked #(parameter WIDTH=8,
                        parameter ES=1);
  // Packed form of a posit
  typedef struct packed {
    logic [WIDTH-1:0] bits;
  } Packed;

  Packed data;

  modport InputIf (input data, import zeroPacked, import infPacked);
  modport OutputIf (output data, import zeroPacked, import infPacked);

  //
  // Utility functions
  //

  // Returns a packed posit with value 0
  function automatic Packed zeroPacked();
    Packed v;
    v.bits = {WIDTH{1'b0}};

    return v;
  endfunction

  // Returns a packed posit with value 1
  function automatic Packed onePacked(logic sign);
    Packed v;
    v.bits = {sign, 1'b1, (WIDTH-2)'(1'b0)};

    return v;
  endfunction

  // Returns a packed posit with value +/- inf
  function automatic Packed infPacked();
    Packed v;
    v.bits = {1'b1, {WIDTH-1{1'b0}}};

    return v;
  endfunction

  // Returns the largest (pos) or smallest (neg) packed posit with the given
  // sign
  function automatic Packed maxPacked(logic sign);
    Packed v;
    v.bits = sign ? {WIDTH{1'b1}} : {1'b0, {WIDTH-1{1'b1}}};

    return v;
  endfunction

  function automatic logic isInfPacked(Packed v);
    return v == {1'b1, {(WIDTH-1){1'b0}}};
  endfunction
endinterface
