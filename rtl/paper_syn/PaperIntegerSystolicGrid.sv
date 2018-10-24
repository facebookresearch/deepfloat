// Copyright (c) Facebook, Inc. and its affiliates. All Rights Reserved.
// All rights reserved.
//
// This source code is licensed under the license found in the
// LICENSE file in the root directory of this source tree.

// The grid of systolic PEs receiving input from the shift registers
// holding a tile of A and B, accumulating the products C
module PaperIntegerSystolicGrid #(parameter TILE=32,
                                  parameter WIDTH=8,
                                  parameter ACC=32)
  (// Next column from A being shifted in
   input logic [WIDTH-1:0] aNextIn[0:TILE-1],
   input logic [WIDTH-1:0] bNextIn[0:TILE-1],
   output logic [ACC-1:0] cNextOut[0:TILE-1],

   input enableMul,
   input enableShiftOut,
   input reset,
   input clock);

  // The grid of PEs
  logic [WIDTH-1:0] aOuts [0:TILE*TILE-1];
  logic [WIDTH-1:0] bOuts [0:TILE*TILE-1];
  logic [ACC-1:0] cOuts [0:TILE*TILE-1];

  logic [WIDTH-1:0] aIns[0:TILE*TILE-1];
  logic [WIDTH-1:0] bIns[0:TILE*TILE-1];
  logic [ACC-1:0] cIns[0:TILE*TILE-1];

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
            aIns[i * TILE + j] = aNextIn[0];
            bIns[i * TILE + j] = bNextIn[0];
            cIns[i * TILE + j] = ACC'(1'b0);
          end
        end else if (j == 0) begin
          always_comb begin
            // each row, column 0
            aIns[i * TILE + j] = aNextIn[i];
            bIns[i * TILE + j] = bOuts[(i - 1) * TILE + j];
            cIns[i * TILE + j] = cOuts[(i - 1) * TILE + j];
          end
        end else if (i == 0) begin
          always_comb begin
            // row 0, each column
            aIns[i * TILE + j] = aOuts[i * TILE + (j - 1)];
            bIns[i * TILE + j] = bNextIn[j];
            cIns[i * TILE + j] = ACC'(1'b0);
          end
        end else begin
          always_comb begin
            aIns[i * TILE + j] = aOuts[i * TILE + (j - 1)];
            bIns[i * TILE + j] = bOuts[(i - 1) * TILE + j];
            cIns[i * TILE + j] = cOuts[(i - 1) * TILE + j];
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
        PaperIntegerSystolicPE #(.WIDTH(WIDTH),
                                 .ACC(ACC))
        unit(.aOut(aOuts[i * TILE + j]),
             .bOut(bOuts[i * TILE + j]),
             .cOut(cOuts[i * TILE + j]),
             // shift from col - 1 to col ( > )
             .aIn(aIns[i * TILE + j]),
             // shift from row - 1 to row ( V )
             .bIn(bIns[i * TILE + j]),
             // shift from row - 1 to row ( V )
             .cIn(cIns[i * TILE + j]),
             .enableMul(enableMul),
             .enableShiftOut(enableShiftOut),
             .reset(reset),
             .clock(clock));
      end
    end
  endgenerate

  generate
    for (j = 0; j < TILE; ++j) begin : genJ2
      always_comb begin
        // this is registered in the PE
        cNextOut[j] = cOuts[(TILE - 1) * TILE + j];
      end
    end
  endgenerate
endmodule
