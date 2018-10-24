// Copyright (c) Facebook, Inc. and its affiliates. All Rights Reserved.
// All rights reserved.
//
// This source code is licensed under the license found in the
// LICENSE file in the root directory of this source tree.

// FIXME: this is not much of a test
// Can compare against machine reals instead
module QuireDivideTest();
  bit clock;
  bit reset;

  localparam WIDTH = 8;
  localparam ES = 1;
  localparam OVERFLOW = 0;

  localparam ACC_NON_FRAC = QuireDef::getNonFracBits(WIDTH, ES, OVERFLOW, 0);
  localparam ACC_FRAC = QuireDef::getFracBits(WIDTH, ES, OVERFLOW);

  Kulisch #(.ACC_NON_FRAC(ACC_NON_FRAC), .ACC_FRAC(ACC_FRAC)) quireIn();
  Kulisch #(.ACC_NON_FRAC(ACC_NON_FRAC), .ACC_FRAC(ACC_FRAC)) quireOut();

  logic [7:0] div;

  KulischAccumulatorDivide #(.ACC_NON_FRAC(ACC_NON_FRAC),
                             .ACC_FRAC(ACC_FRAC),
                             .DIV(8))
  divider(.accIn(quireIn),
          .div,
          .accOut(quireOut),
          .clock,
          .reset);

  integer i;
  localparam STAGES = KulischDef::getBits(ACC_NON_FRAC, ACC_FRAC) + 2;

  // clock generator
  initial begin : clockgen
    clock <= 1'b0;
    forever #5 clock = ~clock;
  end

  initial begin
    reset = 1;
    @(posedge clock);
    reset = 0;

    quireIn.data = quireIn.make(1'b0, // isInf
                                1'b0, // isOverflow
                                1'b0, // overflowSign
                                4'd11, // nonfrac
                                1'b0); // frac

    div = 8'd3;

    for (i = 0; i < STAGES; ++i) begin
      @(posedge clock);
      #1;

      // Fill the pipeline with garbage
      quireIn.data = $random;
      div = $random;
    end

    #1;

    // should be 0000000000011.101010101010101010101010
    assert(quireOut.getNonFracBits(quireOut.data) == 2'b11);
    assert(quireOut.getFracBits(quireOut.data) == 24'b101010101010101010101010);

    // Let us exit
    disable clockgen;
  end
endmodule
