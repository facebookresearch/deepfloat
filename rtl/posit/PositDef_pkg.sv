// Copyright (c) Facebook, Inc. and its affiliates. All Rights Reserved.
// All rights reserved.
//
// This source code is licensed under the license found in the
// LICENSE file in the root directory of this source tree.

package PositDef;
  function automatic integer getMaxRegimeFieldSize(integer w, integer es);
    return w - 1;
  endfunction

  function automatic integer getMaxSignedRegime(integer w, integer es);
    return getMaxRegimeFieldSize(w, es) - 1;
  endfunction

  function automatic integer getMinSignedRegime(integer w, integer es);
    return -getMaxSignedRegime(w, es);
  endfunction

  // Number of bits to encode the regime in signed form
  // i.e., signed regime is from -15 .. 15 => clog2(15 + 1) + 1 -> 5 bits
  // -16 .. 16 => clog2(16 + 1) -> 6 bits
  function automatic integer getSignedRegimeBits(integer w, integer es);
    return Functions::clog2(getMaxSignedRegime(w, es) + 1) + 1;
  endfunction

  // Number of bits to encode the regime with bias
  // The 000... regime encoding case is not a valid regime. The unsigned case
  // takes the same number of bits as the signed case
  function automatic integer getUnsignedRegimeBits(integer w, integer es);
    return getSignedRegimeBits(w, es);
  endfunction

  // Maximum zero-based regime value
  // i.e., the regime with MAX_SIGNED_EXPONENT / MAX_UNSIGNED_EXPONENT
  function automatic integer getMaxUnsignedRegime(integer w, integer es);
    return getMaxSignedRegime(w, es) * 2;
  endfunction

  // Minimum zero-based regime value
  // i.e., the regime with MIN_SIGNED_EXPONENT
  function automatic integer getMinUnsignedRegime(integer w, integer es);
    return 0;
  endfunction

  // Minimum and maximum exponent representable by this posit type
  // e.g., WIDTH = 8 => -2^1 * 6 = -12
  // (all 7 0s is either zero or +/- inf)
  function automatic integer getMinSignedExponent(integer w, integer es);
    return (2 ** es) * getMinSignedRegime(w, es);
  endfunction

  // e.g., WIDTH = 8 => 2^1 * 6 = 12
  function automatic integer getMaxSignedExponent(integer w, integer es);
    return (2 ** es) * getMaxSignedRegime(w, es);
  endfunction

  function automatic integer getMinUnsignedExponent(integer w, integer es);
    return 0;
  endfunction

  function automatic integer getMaxUnsignedExponent(integer w, integer es);
    return (2 ** es) * getMaxUnsignedRegime(w, es);
  endfunction

  // Bias to add to convert a signed exponent to an unsigned
  // exponent, or to subtract for converting an unsigned exponent to
  // a signed exponent
  function automatic integer getExponentBias(integer w, integer es);
    return (2 ** es) * getMaxSignedRegime(w, es);
  endfunction

  // Number of bits to maintain our exponent count including the bias
  // ES always defines the low order bits
  function automatic integer getUnsignedExponentBits(integer w, integer es);
    return getUnsignedRegimeBits(w, es) + es;
  endfunction

  // If we were to represent our exponent as a signed number, this is
  // the number of bits we need to represent it
  function automatic integer getSignedExponentBits(integer w, integer es);
    return getUnsignedExponentBits(w, es);
  endfunction

  // Maximum fraction bits is WIDTH - 1 - 2 - ES
  // (-1 sign bit, -2 regime encoding, -ES field width)
  // If this is 0 (the posit type is too small to possess a
  // fraction), just use 1
  function automatic integer getFractionBits(integer w, integer es);
    return (w - 1 - 2 - es) <= 0 ? 1 : (w - 1 - 2 - es);
  endfunction

  // For code that is agnostic to ES == 0
  function automatic integer getESBits(integer w, integer es);
    return es > 1 ? es : 1;
  endfunction

  // Number of bits that represent the product of two posit fractions with a
  // leading 1 (used for quire accumulation)
  // FIXME: if the max exponent * 2 can fit in the same number of bits, we
  // don't need to make this a bit larger
  function automatic integer getExpProductBits(integer w, integer es);
    return getUnsignedExponentBits(w, es) + 1;
  endfunction

  function automatic integer getFracProductBits(integer w, integer es);
    return (getFractionBits(w, es) + 1) * 2;
  endfunction

  // The size in bits of an unpacked posit
  function automatic integer getUnpackedStructSize(integer w, integer es);
    // isZero, isInf, sign
    return 3 + getUnsignedExponentBits(w, es) + getFractionBits(w, es);
  endfunction
endpackage
