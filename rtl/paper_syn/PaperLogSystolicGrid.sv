// Copyright (c) Facebook, Inc. and its affiliates. All Rights Reserved.
// All rights reserved.
//
// This source code is licensed under the license found in the
// LICENSE file in the root directory of this source tree.

// The grid of systolic PEs receiving input from the shift registers
// holding a tile of A and B, accumulating the products C
module PaperLogSystolicGrid_Sub #(parameter WIDTH=8,
                                  parameter LS=1,
                                  parameter OVERFLOW_DETECTION=0,
                                  parameter NON_FRAC_REDUCE=0,
                                  parameter LOG_TO_LINEAR_BITS=5,
                                  parameter TILE=4)
  (// Next column from A being shifted in
   LogNumberUnpacked.InputIf aNextIn[0:TILE-1],
   LogNumberUnpacked.InputIf bNextIn[0:TILE-1],
   Kulisch.OutputIf cNextOut[0:TILE-1],

   input enableMul,
   input enableShiftOut,
   input reset,
   input clock);

  localparam ACC_NON_FRAC = LogDef::getAccNonFracTapered(WIDTH, LS);
  localparam ACC_FRAC = LogDef::getAccFracTapered(WIDTH, LS);

  localparam M = PositDef::getSignedExponentBits(WIDTH, LS);
  localparam F = PositDef::getFractionBits(WIDTH, LS);

  // The grid of PEs
  LogNumberUnpacked #(.M(M), .F(F)) aOuts[0:TILE*TILE-1]();
  LogNumberUnpacked #(.M(M), .F(F)) bOuts[0:TILE*TILE-1]();
  Kulisch #(.ACC_NON_FRAC(ACC_NON_FRAC), .ACC_FRAC(ACC_FRAC)) cOuts[0:TILE*TILE-1]();

  LogNumberUnpacked #(.M(M), .F(F)) aIns[0:TILE*TILE-1]();
  LogNumberUnpacked #(.M(M), .F(F)) bIns[0:TILE*TILE-1]();
  Kulisch #(.ACC_NON_FRAC(ACC_NON_FRAC), .ACC_FRAC(ACC_FRAC)) cIns[0:TILE*TILE-1]();

  genvar i;
  genvar j;

  generate
    // row
    for (i = 0; i < TILE; ++i) begin
      // column
      for (j = 0; j < TILE; ++j) begin

        if (i == 0 && j == 0) begin
          always_comb begin
            // row 0, colum 0
            aIns[i * TILE + j].data = aNextIn[0].data;
            bIns[i * TILE + j].data = bNextIn[0].data;
            cIns[i * TILE + j].data = cIns[i * TILE + j].zero();
          end
        end else if (j == 0) begin
          always_comb begin
            // each row, column 0
            aIns[i * TILE + j].data = aNextIn[i].data;
            bIns[i * TILE + j].data = bOuts[(i - 1) * TILE + j].data;
            cIns[i * TILE + j].data = cOuts[(i - 1) * TILE + j].data;
          end
        end else if (i == 0) begin
          always_comb begin
            // row 0, each column
            aIns[i * TILE + j].data = aOuts[i * TILE + (j - 1)].data;
            bIns[i * TILE + j].data = bNextIn[j].data;
            cIns[i * TILE + j].data = cIns[i * TILE + j].zero();
          end
        end else begin
          always_comb begin
            aIns[i * TILE + j].data = aOuts[i * TILE + (j - 1)].data;
            bIns[i * TILE + j].data = bOuts[(i - 1) * TILE + j].data;
            cIns[i * TILE + j].data = cOuts[(i - 1) * TILE + j].data;
          end
        end
      end
    end
  endgenerate

  generate
    // Row-major indexing
    // A is along rows (i), B is along columns (j)
    for (i = 0; i < TILE; ++i) begin : genI
      for (j = 0; j < TILE; ++j) begin : genJ
        PaperLogSystolicPE #(.WIDTH(WIDTH),
                             .LS(LS),
                             .OVERFLOW_DETECTION(OVERFLOW_DETECTION),
                             .NON_FRAC_REDUCE(NON_FRAC_REDUCE),
                             .LOG_TO_LINEAR_BITS(LOG_TO_LINEAR_BITS))
        unit(.aOut(aOuts[i * TILE + j]),
             .bOut(bOuts[i * TILE + j]),
             .cOut(cOuts[i * TILE + j]),
             // shift from col - 1 to col ( > )
             .aIn(aIns[i * TILE + j]),
             // shift from row - 1 to row ( V )
             .bIn(bIns[i * TILE + j]),
             // shift from row - 1 to row ( V )
             .cIn(cIns[i * TILE + j]),
             .enableMul,
             .enableShiftOut,
             .reset,
             .clock);
      end
    end
  endgenerate

  generate
    for (j = 0; j < TILE; ++j) begin : genJ2
      always_comb begin
        // this is registered in the PE
        cNextOut[j].data = cOuts[(TILE - 1) * TILE + j].data;
      end
    end
  endgenerate
endmodule

// This time, without interfaces
module PaperLogSystolicGrid #(parameter WIDTH=8,
                              parameter LS=1,
                              parameter OVERFLOW_DETECTION=0,
                              parameter NON_FRAC_REDUCE=0,
                              parameter LOG_TO_LINEAR_BITS=5,
                              parameter LINEAR_TO_LOG_BITS=5,
                              parameter TILE=32)
  (input logic [WIDTH-1:0] aNextIn[0:TILE-1],
   input logic [WIDTH-1:0] bNextIn[0:TILE-1],
   output logic [WIDTH-1:0] cNextOut[0:TILE-1],

   input enableMul,
   input enableShiftOut,
   input reset,
   input clock);

  localparam ACC_NON_FRAC = LogDef::getAccNonFracTapered(WIDTH, LS) - NON_FRAC_REDUCE;
  localparam ACC_FRAC = LogDef::getAccFracTapered(WIDTH, LS);

  localparam M = PositDef::getSignedExponentBits(WIDTH, LS);
  localparam F = PositDef::getFractionBits(WIDTH, LS);

  LogNumberCompact #(.WIDTH(WIDTH), .LS(LS)) aInLC[0:TILE-1]();
  LogNumberCompact #(.WIDTH(WIDTH), .LS(LS)) bInLC[0:TILE-1]();

  LogNumberUnpacked #(.M(M), .F(F)) aInUP[0:TILE-1]();
  LogNumberUnpacked #(.M(M), .F(F)) bInUP[0:TILE-1]();

  Kulisch #(.ACC_NON_FRAC(ACC_NON_FRAC), .ACC_FRAC(ACC_FRAC)) cOut[0:TILE-1]();
  LogNumberCompact #(.WIDTH(WIDTH), .LS(LS)) cOutLC[0:TILE-1]();

  genvar i;
  generate
    for (i = 0; i < TILE; ++i) begin
      always_comb begin
        aInLC[i].data = aNextIn[i];
        bInLC[i].data = bNextIn[i];
        cNextOut[i] = cOutLC[i].data;
      end

      LogCompactToLogUnpacked #(.WIDTH(WIDTH),
                                .LS(LS))
      lc2lua(.in(aInLC[i]),
             .out(aInUP[i]));

      LogCompactToLogUnpacked #(.WIDTH(WIDTH),
                                .LS(LS))
      lc2lub(.in(bInLC[i]),
             .out(bInUP[i]));

      LinearFixedToLogCompact #(.WIDTH(WIDTH),
                                .LS(LS),
                                .OVERFLOW_DETECTION(OVERFLOW_DETECTION),
                                .NON_FRAC_REDUCE(NON_FRAC_REDUCE),
                                .LINEAR_TO_LOG_BITS(LINEAR_TO_LOG_BITS),
                                .USE_ADJUST(0))
      lf2lc(.in(cOut[i]),
            .adjustExp(),
            .out(cOutLC[i]));
    end
  endgenerate

  PaperLogSystolicGrid_Sub #(.WIDTH(WIDTH),
                             .LS(LS),
                             .OVERFLOW_DETECTION(OVERFLOW_DETECTION),
                             .NON_FRAC_REDUCE(NON_FRAC_REDUCE),
                             .LOG_TO_LINEAR_BITS(LOG_TO_LINEAR_BITS),
                             .TILE(TILE))
  grid(.aNextIn(aInUP),
       .bNextIn(bInUP),
       .cNextOut(cOut),
       .enableMul,
       .enableShiftOut,
       .reset,
       .clock);
endmodule
