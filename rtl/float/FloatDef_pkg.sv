// Copyright (c) Facebook, Inc. and its affiliates. All Rights Reserved.
// All rights reserved.
//
// This source code is licensed under the license found in the
// LICENSE file in the root directory of this source tree.

package FloatDef;
  // The actual (signed) exponent that this float represents is
  // exponent - EXP_BIAS
  function automatic integer getExpBias(integer e, integer f);
    return (2 ** (e - 1)) - 1;
  endfunction

  // The minimum biased unsigned exponent representable
  function automatic integer getMinUnsignedNormalExp(integer e, integer f);
    return 1;
  endfunction

  // The minimum signed exponent representable as a normal float
  function automatic integer getMinSignedNormalExp(integer e, integer f);
    return getMinUnsignedNormalExp(e, f) - getExpBias(e, f);
  endfunction

  // The minimum signed exponent representable as a subnormal float
  function automatic integer getMinSignedSubnormalExp(integer e, integer f);
    return getMinSignedNormalExp(e, f) - (f - 1);
  endfunction

  // The maximum unsigned exponent representable
  function automatic integer getMaxUnsignedExp(integer e, integer f);
    return (2 ** e) - 2;
  endfunction

  // The maximum signed exponent representable
  function automatic integer getMaxSignedExp(integer e, integer f);
    return getMaxUnsignedExp(e, f) - getExpBias(e, f);
  endfunction
endpackage
