// Copyright (c) Facebook, Inc. and its affiliates. All Rights Reserved.
// All rights reserved.
//
// This source code is licensed under the license found in the
// LICENSE file in the root directory of this source tree.

//
// A set of fake top-level modules that provide interface instances to module
// instances that use interfaces, so as to prevent VCS complaining
//

module UseKulischAccumulatorAdd();
  localparam ACC_NON_FRAC = 8;
  localparam ACC_FRAC = 8;

  Kulisch #(.ACC_NON_FRAC(ACC_NON_FRAC), .ACC_FRAC(ACC_FRAC)) a();
  Kulisch #(.ACC_NON_FRAC(ACC_NON_FRAC), .ACC_FRAC(ACC_FRAC)) b();
  Kulisch #(.ACC_NON_FRAC(ACC_NON_FRAC), .ACC_FRAC(ACC_FRAC)) out();

  KulischAccumulatorAdd #(.ACC_NON_FRAC(ACC_NON_FRAC),
                          .ACC_FRAC(ACC_FRAC))
  add(.*);
endmodule

module UseKulischAccumulatorDivide();
  localparam ACC_NON_FRAC = 8;
  localparam ACC_FRAC = 8;

  Kulisch #(.ACC_NON_FRAC(ACC_NON_FRAC), .ACC_FRAC(ACC_FRAC)) accIn();
  Kulisch #(.ACC_NON_FRAC(ACC_NON_FRAC), .ACC_FRAC(ACC_FRAC)) accOut();

  logic [7:0] div;
  logic clock;
  logic reset;

  KulischAccumulatorDivide #(.ACC_NON_FRAC(ACC_NON_FRAC),
                             .ACC_FRAC(ACC_FRAC),
                             .DIV(8))
  add(.*);
endmodule
