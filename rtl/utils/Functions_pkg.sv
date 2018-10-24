// Copyright (c) Facebook, Inc. and its affiliates. All Rights Reserved.
// All rights reserved.
//
// This source code is licensed under the license found in the
// LICENSE file in the root directory of this source tree.

//
// A collection of functions for operating on synthesis-time constants
//

package Functions;
  // DC doesn't support $clog2 in constant functions
  function automatic integer clog2(input integer a);
    if (a <= 2) begin
      return 1;
    end else if (a <= 4) begin
      return 2;
    end else if (a <= 8) begin
      return 3;
    end else if (a <= 16) begin
      return 4;
    end else if (a <= 32) begin
      return 5;
    end else if (a <= 64) begin
      return 6;
    end else if (a <= 128) begin
      return 7;
    end else if (a <= 256) begin
      return 8;
    end else if (a <= 512) begin
      return 9;
    end else if (a <= 1024) begin
      return 10;
    end else if (a <= 2048) begin
      return 11;
    end else if (a <= 4096) begin
      return 12;
    end else if (a <= 8192) begin
      return 13;
    end else if (a <= 16384) begin
      return 14;
    end else if (a <= 32768) begin
      return 15;
    end else if (a <= 65536) begin
      return 16;
    end else if (a <= 131072) begin
      return 17;
    end else if (a <= 262144) begin
      return 18;
    end else if (a <= 524288) begin
      return 19;
    end else if (a <= 1048576) begin
      return 20;
    end else if (a <= 2097152) begin
      return 21;
    end else if (a <= 4194304) begin
      return 22;
    end else if (a <= 8388608) begin
      return 23;
    end else if (a <= 16777216) begin
      return 24;
    end else if (a <= 33554432) begin
      return 25;
    end else if (a <= 67108864) begin
      return 26;
    end else if (a <= 134217728) begin
      return 27;
    end else if (a <= 268435456) begin
      return 28;
    end else if (a <= 536870912) begin
      return 29;
    end else if (a <= 1073741824) begin
      return 30;
    end else if (a <= 2147483647) begin
      return 31;
    end else begin
      return -1;
    end
  endfunction

  function automatic integer getMax(input integer a, input integer b);
    return a >= b ? a : b;
  endfunction

  function automatic integer getMin(input integer a, input integer b);
    return a < b ? a : b;
  endfunction

  function automatic integer largestPowerOf2Divisor(input integer a);
    return 2 ** (clog2(a) - 1);
  endfunction

  function automatic integer isPowerOf2(input integer a);
    return ((a - 1) & a) == 0;
  endfunction
endpackage
