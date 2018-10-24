// Copyright (c) Facebook, Inc. and its affiliates. All Rights Reserved.
// All rights reserved.
//
// This source code is licensed under the license found in the
// LICENSE file in the root directory of this source tree.

// Definitions and parameters for log floating point
package LogDef;
  // FIXME: run_dc flow encounters packages in alphabetic order it seems, so
  // PositDef is not encountered yet, so we repeat this here
  function automatic integer getMaxSignedExponent_HACK(integer w, integer ls);
    // PositDef::getMaxSignedExponent(w, ls)
    return (2 ** ls) * (w - 2);
  endfunction

  // Number of non-fractional bits in the posit-tapered log float Kulisch
  // accumulator
  function automatic integer getAccNonFracTapered(integer w, integer ls);
    // 2^0 is on the non-fractional size, then 2^1 -> 2^n for the rest

    // return 1 + PositDef::getMaxSignedExponent(w, ls);
    return 1 + getMaxSignedExponent_HACK(w, ls);
  endfunction

  // Number of fractional bits in the posit-tapered log float Kulisch
  // accumulator
  function automatic integer getAccFracTapered(integer w, integer ls);
    // Precision to hold the smallest product
    // FIXME: after the log -> linear conversion, we actually have
    // F bits of linear precision before this. We are effectively truncating
    // this here. But does this really matter, because the error is so small?
    // return PositDef::getMaxSignedExponent(w, ls) * 2;
    return getMaxSignedExponent_HACK(w, ls) * 2;
  endfunction

  // Number of non-fractional bits in the non-tapered log float Kulisch
  // accumulator
  function automatic integer getAccNonFrac(integer e, integer f);
    // 2^0 is on the non-fractional size, then 2^1 -> 2^n for the rest

    // two's complement largest positive integer
    return 1 + (2 ** (e - 1) - 1);
  endfunction

  // Number of fractional bits in the non-tapered log float Kulisch
  // accumulator
  function automatic integer getAccFrac(integer e, integer f);
    // Precision to hold the smallest product
    // FIXME: after the log -> linear conversion, we actually have
    // F bits of linear precision before this. We are effectively truncating
    // this here

    // two's complement smallest negative integer, doubled
    return (2 ** (e - 1)) * 2;
  endfunction
endpackage
