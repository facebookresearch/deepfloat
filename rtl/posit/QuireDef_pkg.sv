// Copyright (c) Facebook, Inc. and its affiliates. All Rights Reserved.
// All rights reserved.
//
// This source code is licensed under the license found in the
// LICENSE file in the root directory of this source tree.

package QuireDef;
  function automatic integer convertOverflow(integer w,
                                             integer es,
                                             integer overflow);
    return (overflow == -1 ? PositDef::getMaxSignedExponent(w, es) : overflow);
  endfunction

  function automatic integer getNonFracBits(integer w,
                                            integer es,
                                            integer overflow,
                                            integer non_frac_reduce);
    // (2 ** es) * (w - 2)
    // counts from 2^0, hence the +1
    return 1 + convertOverflow(w, es, overflow) +
      PositDef::getMaxSignedExponent(w, es) - non_frac_reduce;
  endfunction

  function automatic integer getFracBits(integer w,
                                         integer es,
                                         integer overflow);
    // from 2^-min to -1
    return PositDef::getMaxSignedExponent(w, es) +
      // underflow
      PositDef::getMaxSignedExponent(w, es);
  endfunction

  function automatic integer getFirstRepresentableBit(integer w,
                                                      integer es,
                                                      integer overflow,
                                                      integer non_frac_reduce);
    // -2 for sign and start index
    return KulischDef::getBits(getNonFracBits(w, es, overflow, non_frac_reduce),
                               getFracBits(w, es, overflow)) - 2 -
      convertOverflow(w, es, overflow);
  endfunction

  function automatic integer getLastRepresentableBit(integer w,
                                                     integer es,
                                                     integer overflow,
                                                     integer non_frac_reduce);
    // underflow bit index is this - 1
    return PositDef::getMaxSignedExponent(w, es);
  endfunction

  // Number of bits in the representable portion of the accumulator
  function automatic integer getRepresentableSize(integer w,
                                                  integer es,
                                                  integer overflow,
                                                  integer non_frac_reduce);
    return 1 + PositDef::getMaxSignedExponent(w, es) - non_frac_reduce +
      PositDef::getMaxSignedExponent(w, es);
  endfunction
endpackage
