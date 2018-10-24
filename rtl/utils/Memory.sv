// Copyright (c) Facebook, Inc. and its affiliates. All Rights Reserved.
// All rights reserved.
//
// This source code is licensed under the license found in the
// LICENSE file in the root directory of this source tree.

// Single port memory
module Memory #(parameter DEPTH=1024, parameter WIDTH=32)
  (output logic [WIDTH-1:0] read,
   input writeEnable,
   input [WIDTH-1:0] write,
   input [$clog2(DEPTH)-1:0] address,
   input clock);
   (* syn_ramstyle ="auto" *) logic [WIDTH-1:0] mem[0:DEPTH-1];

   always_ff @(posedge clock) begin
      if (writeEnable) begin
         mem[address] <= write;
         read <= write;
      end
      else begin
         read <= mem[address];
      end
   end
endmodule

// Dual-port memory
module Memory2 #(parameter DEPTH=1024, parameter WIDTH=32)
  (output logic [WIDTH-1:0] readA,
   input writeEnableA,
   input [WIDTH-1:0] writeA,
   input [$clog2(DEPTH)-1:0] addressA,
   output logic [WIDTH-1:0] readB,
   input writeEnableB,
   input [WIDTH-1:0] writeB,
   input [$clog2(DEPTH)-1:0] addressB,
   input clock);
   (* syn_ramstyle ="auto" *) logic [WIDTH-1:0] mem[0:DEPTH-1];

   always_ff @(posedge clock) begin
      if (writeEnableA) begin
         mem[addressA] <= writeA;
         readA <= writeA;
      end
      else begin
         readA <= mem[addressA];
      end
   end

   always_ff @(posedge clock) begin
      if (writeEnableB) begin
         mem[addressB] <= writeB;
         readB <= writeB;
      end
      else begin
         readB <= mem[addressB];
      end
   end
endmodule
