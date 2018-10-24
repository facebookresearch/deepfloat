// Copyright (c) Facebook, Inc. and its affiliates. All Rights Reserved.
// All rights reserved.
//
// This source code is licensed under the license found in the
// LICENSE file in the root directory of this source tree.


class Calc #(parameter WIDTH=8,
             parameter ES=1);
  virtual function real runCalc(input real v);
  endfunction

  virtual function Posit #(.WIDTH(WIDTH), .ES(ES))::Packed cleanup(
    input Posit #(.WIDTH(WIDTH), .ES(ES))::Packed in,
    input Posit #(.WIDTH(WIDTH), .ES(ES))::Packed out);
  endfunction
endclass

class LnCalc #(parameter WIDTH=8,
                parameter ES=1)
  extends Calc #(.WIDTH(WIDTH), .ES(ES));

  function real runCalc (input real v);
    return $ln(v);
  endfunction

  function Posit #(.WIDTH(WIDTH), .ES(ES))::Packed cleanup(
    input Posit #(.WIDTH(WIDTH), .ES(ES))::Packed in,
    input Posit #(.WIDTH(WIDTH), .ES(ES))::Packed out);
    return out;
  endfunction
endclass

class ExpCalc #(parameter WIDTH=8,
                parameter ES=1)
  extends Calc #(.WIDTH(WIDTH), .ES(ES));

  function real runCalc (input real v);
    return $exp(v);
  endfunction

  function Posit #(.WIDTH(WIDTH), .ES(ES))::Packed cleanup(
    input Posit #(.WIDTH(WIDTH), .ES(ES))::Packed in,
    input Posit #(.WIDTH(WIDTH), .ES(ES))::Packed out);
    // We don't overflow finite values to +/- inf (even though `real` does)
      if (!Posit #(.WIDTH(WIDTH), .ES(ES))::isInfPacked(in) &&
          Posit #(.WIDTH(WIDTH), .ES(ES))::isInfPacked(out)) begin
        return Posit #(.WIDTH(WIDTH), .ES(ES))::maxPacked(1'b0);
      end

    return out;
  endfunction
endclass

class SqrtCalc #(parameter WIDTH=8,
                parameter ES=1)
  extends Calc #(.WIDTH(WIDTH), .ES(ES));

  function real runCalc (input real v);
    return $sqrt(v);
  endfunction

  function Posit #(.WIDTH(WIDTH), .ES(ES))::Packed cleanup(
    input Posit #(.WIDTH(WIDTH), .ES(ES))::Packed in,
    input Posit #(.WIDTH(WIDTH), .ES(ES))::Packed out);
    return out;
  endfunction
endclass

class InvCalc #(parameter WIDTH=8,
                parameter ES=1)
  extends Calc #(.WIDTH(WIDTH), .ES(ES));

  function real runCalc (input real v);
    return 1.0 / v;
  endfunction

  function Posit #(.WIDTH(WIDTH), .ES(ES))::Packed cleanup(
    input Posit #(.WIDTH(WIDTH), .ES(ES))::Packed in,
    input Posit #(.WIDTH(WIDTH), .ES(ES))::Packed out);
    return out;
  endfunction
endclass

class SigmoidCalc #(parameter WIDTH=8,
                    parameter ES=1)
  extends Calc #(.WIDTH(WIDTH), .ES(ES));

  function real runCalc (input real v);
    return 1.0 / (1.0 + $exp(-v));
  endfunction

  function Posit #(.WIDTH(WIDTH), .ES(ES))::Packed cleanup(
    input Posit #(.WIDTH(WIDTH), .ES(ES))::Packed in,
    input Posit #(.WIDTH(WIDTH), .ES(ES))::Packed out);
      if (Posit #(.WIDTH(WIDTH), .ES(ES))::isInfPacked(in)) begin
        return Posit #(.WIDTH(WIDTH), .ES(ES))::infPacked();
      end
    return out;
  endfunction
endclass


// Generates a lookup table for arbitrary functions by using double-precision
// IEEE floating point
 module PositLUTGenerator #(parameter WIDTH=8,
                            parameter ES=1)
  ();
  localparam FLOAT_FRAC = 52;
  localparam FLOAT_EXP = 11;
  localparam TRAILING_BITS = 2;

  Posit #(.WIDTH(WIDTH), .ES(ES))::Packed pIn;
  Posit #(.WIDTH(WIDTH), .ES(ES))::Unpacked upIn;

  Float #(.EXP(FLOAT_EXP), .FRAC(FLOAT_FRAC))::def fIn;
  Float #(.EXP(FLOAT_EXP), .FRAC(FLOAT_FRAC))::def fOut;

  Posit #(.WIDTH(WIDTH), .ES(ES))::Unpacked upOut;
  logic [TRAILING_BITS-1:0] trailingBits;
  logic stickyBit;

  Posit #(.WIDTH(WIDTH), .ES(ES))::Unpacked upOutRounded;
  Posit #(.WIDTH(WIDTH), .ES(ES))::Packed pOut;
  Posit #(.WIDTH(WIDTH), .ES(ES))::Packed pOutClean;

  PositDecode #(.WIDTH(WIDTH),
                .ES(ES))
  dec(.in(pIn),
      .out(upIn));

  PositToFloat #(.POSIT_WIDTH(WIDTH),
                 .POSIT_ES(ES),
                 .FLOAT_EXP(FLOAT_EXP),
                 .FLOAT_FRAC(FLOAT_FRAC),
                 .TRAILING_BITS(TRAILING_BITS))
  p2f(.in(upIn),
      .expAdjust(1'b0),
      .out(fIn),
      .trailingBitsOut(),
      .stickyBitOut());

  PositFromFloat #(.POSIT_WIDTH(WIDTH),
                   .POSIT_ES(ES),
                   .FLOAT_EXP(FLOAT_EXP),
                   .FLOAT_FRAC(FLOAT_FRAC),
                   .TRAILING_BITS(TRAILING_BITS))
  f2p(.in(fOut),
      .expAdjust(1'b0),
      .out(upOut),
      .trailingBits,
      .stickyBit);

  PositRoundToNearestEven #(.WIDTH(WIDTH),
                            .ES(ES))
  r2ne(.in(upOut),
       .trailingBits,
       .stickyBit,
       .out(upOutRounded));

  PositEncode #(.WIDTH(WIDTH),
                .ES(ES))
  enc(.in(upOutRounded),
      .out(pOut));

  integer file;
  integer i;
  real inV;
  real outV;
  LnCalc #(.WIDTH(WIDTH), .ES(ES)) lnCalc = new;
  ExpCalc #(.WIDTH(WIDTH), .ES(ES)) expCalc = new;
  SqrtCalc #(.WIDTH(WIDTH), .ES(ES)) sqrtCalc = new;
  InvCalc #(.WIDTH(WIDTH), .ES(ES)) invCalc = new;
  SigmoidCalc #(.WIDTH(WIDTH), .ES(ES)) sigmoidCalc = new;

  task doCalc(input Calc c, integer file, bit logOn);
    for (i = 0; i < 2 ** WIDTH; ++i) begin
      pIn = i;
      #1;

      inV = $bitstoreal(fIn);
      outV = c.runCalc(inV);
      fOut = $realtobits(outV);

      #1;
      pOutClean = c.cleanup(pIn, pOut);

      $fdisplay(file, "%h", pOutClean);

      if (logOn) begin
        $display("got %d -> %f -> %f -> %d",
                 i, inV, outV, pOutClean);
        pIn = pOutClean;

        #1;
        if ($bitstoreal(fIn) != $bitstoreal(fOut)) begin
          $display("*** different (%f vs %f)",
                   $bitstoreal(fIn), $bitstoreal(fOut));
        end
      end
    end
  endtask

  initial begin
    $display("*** Generating (8, 1) ln(x)");
    file = $fopen("ln8_1.hex", "w");
    doCalc(lnCalc, file, 1'b0);
    $fclose(file);

    $display("*** Generating (8, 1) exp(x)");
    file = $fopen("exp8_1.hex", "w");
    doCalc(expCalc, file, 1'b0);
    $fclose(file);

    $display("*** Generating (8, 1) sqrt(x)");
    file = $fopen("sqrt8_1.hex", "w");
    doCalc(sqrtCalc, file, 1'b0);
    $fclose(file);

    $display("*** Generating (8, 1) 1/x");
    file = $fopen("inv8_1.hex", "w");
    doCalc(invCalc, file, 1'b0);
    $fclose(file);

    $display("*** Generating (8, 1) sigmoid(x)");
    file = $fopen("sigmoid8_1.hex", "w");
    doCalc(sigmoidCalc, file, 1'b1);
    $fclose(file);
  end
endmodule
