// Copyright (c) Facebook, Inc. and its affiliates. All Rights Reserved.
// All rights reserved.
//
// This source code is licensed under the license found in the
// LICENSE file in the root directory of this source tree.

class BitUtils #(parameter N=8);
  // Counts the leading zeros (from msb) in this vector
  static function integer clz(input [N-1:0] v);
    integer i;
    for (i = N - 1; i >= 0; --i) begin
      if (v[i]) begin
        return N - 1 - i;
      end
    end

    return N;
  endfunction
endclass
