// Copyright (c) Facebook, Inc. and its affiliates. All Rights Reserved.
// All rights reserved.
//
// This source code is licensed under the license found in the
// LICENSE file in the root directory of this source tree.

interface Kulisch #(parameter ACC_NON_FRAC=13,
                    parameter ACC_FRAC=12);
  typedef struct packed {
    // Is the accumulator at inf?
    logic isInf;

    // Has the accumulator overflowed?
    logic isOverflow;

    // If we've overflowed, this is the sign that we had before overflowing
    logic overflowSign;

    // Fixed-point
    logic signed [KulischDef::getBits(ACC_NON_FRAC, ACC_FRAC)-1:0] bits;
  } Type;

  Type data;

  modport InputIf(input data,
`ifndef SYNTHESIS
                  import printBits,
                  import print,
`endif
                  import zero,
                  import getSign,
                  import getNonFracBits,
                  import setNonFracBits,
                  import getFracBits,
                  import make);

  modport OutputIf(output data,
`ifndef SYNTHESIS
                   import printBits,
                   import print,
`endif
                   import zero,
                   import getSign,
                   import getNonFracBits,
                   import setNonFracBits,
                   import getFracBits,
                   import make);

  function automatic Type zero();
    localparam BITS = KulischDef::getBits(ACC_NON_FRAC, ACC_FRAC);

    Type q;

    q.isInf = 1'b0;
    q.isOverflow = 1'b0;
    q.overflowSign = 1'b0;

    q.bits = BITS'(1'b0);

    return q;
  endfunction

  function automatic logic getSign(Type q);
    localparam BITS = KulischDef::getBits(ACC_NON_FRAC, ACC_FRAC);

    return q.bits[BITS-1];
  endfunction

  // Returns the non-fractional digits, including the sign (2s complement)
  function automatic
    logic [KulischDef::getNonFracBits(ACC_NON_FRAC, ACC_FRAC)-1:0]
      getNonFracBits(Type q);
    return q.bits[KulischDef::getBits(ACC_NON_FRAC, ACC_FRAC)-1:
                  KulischDef::getFirstFractionalBit(ACC_NON_FRAC,
                                                    ACC_FRAC)+1];
  endfunction

  function automatic
    Type setNonFracBits(Type q,
                        logic [KulischDef::getNonFracBits(ACC_NON_FRAC,
                                                          ACC_FRAC)-1:0] v);
    Type nq;
    nq.bits = q.bits;
    nq.bits[KulischDef::getBits(ACC_NON_FRAC,
                                ACC_FRAC)-1:
            KulischDef::getFirstFractionalBit(ACC_NON_FRAC,
                                              ACC_FRAC)+1] = v;

    return nq;
  endfunction

  function automatic
    logic [KulischDef::getFracBits(ACC_NON_FRAC, ACC_FRAC)-1:0]
      getFracBits(Type q);
    return q.bits[KulischDef::getFirstFractionalBit(ACC_NON_FRAC,
                                                    ACC_FRAC):0];
  endfunction

  function automatic
    Type make(logic isInf,
              logic isOverflow,
              logic overflowSign,
              logic [KulischDef::getNonFracBits(ACC_NON_FRAC,
                                                ACC_FRAC)-1:0] nonFrac,
              logic [KulischDef::getFracBits(ACC_NON_FRAC,
                                             ACC_FRAC)-1:0] frac);
    Type q;

    q.isInf = isInf;
    q.isOverflow = isOverflow;
    q.overflowSign = overflowSign;
    q.bits[KulischDef::getBits(ACC_NON_FRAC,
                               ACC_FRAC)-1:
           KulischDef::getFirstFractionalBit(ACC_NON_FRAC,
                                             ACC_FRAC)+1] = nonFrac;
    q.bits[KulischDef::getFirstFractionalBit(ACC_NON_FRAC,
                                             ACC_FRAC):0] = frac;

    return q;
  endfunction

`ifndef SYNTHESIS
  function automatic
    string printBits(logic [KulischDef::getBits(ACC_NON_FRAC,
                                                ACC_FRAC)-1:0] bits);
    localparam BITS = KulischDef::getBits(ACC_NON_FRAC, ACC_FRAC);

    bit [BITS-1:0] pos;
    bit sign = bits[BITS-1];

    pos = sign ? -bits : bits;

    return $sformatf("%s%b.%b (raw %b.%b)",
                     sign ? "-" : "+",
                     // non-frac
                     pos[BITS-2:KulischDef::getFirstFractionalBit(ACC_NON_FRAC,
                                                                  ACC_FRAC)+1],
                     // frac
                     pos[KulischDef::getFirstFractionalBit(ACC_NON_FRAC,
                                                           ACC_FRAC):0],
                     // raw non-frac
                     bits[BITS-1:KulischDef::getFirstFractionalBit(ACC_NON_FRAC,
                                                                   ACC_FRAC)+1],
                     // raw frac
                     bits[KulischDef::getFirstFractionalBit(ACC_NON_FRAC,
                                                            ACC_FRAC):0]);
  endfunction

  function automatic string print(Type q);
    string overflowStr;

    overflowStr = q.isOverflow ? $sformatf(" (%s ovf)",
                                           q.overflowSign ? "-" : "+") :
                  "";

    if (q.isInf) begin
      return $sformatf("+/- inf");
    end

    return $sformatf("%s%s",
                     printBits(q.bits),
                     overflowStr);
  endfunction
`endif
endinterface
