// Copyright (c) Facebook, Inc. and its affiliates. All Rights Reserved.
// All rights reserved.
//
// This source code is licensed under the license found in the
// LICENSE file in the root directory of this source tree.

package KulischDef;
  function automatic integer getBits(integer nonFrac,
                                     integer frac);
    // +1 for the sign bit
    return 1 + nonFrac + frac;
  endfunction

  function automatic integer getNonFracBits(integer nonFrac,
                                            integer frac);
    return 1 + nonFrac;
  endfunction

  function automatic integer getFracBits(integer nonFrac,
                                         integer frac);
    return frac;
  endfunction

  // Index of the first fractional bit
  function automatic integer getFirstFractionalBit(integer nonFrac,
                                                   integer frac);
    return frac - 1;
  endfunction

  // Returns the size in bits of the total accumulator struct
  function automatic integer getStructSize(integer nonFrac,
                                           integer frac);
    // isInf, isOverflow, overflowSign
    return 3 + getBits(nonFrac, frac);
  endfunction
endpackage
