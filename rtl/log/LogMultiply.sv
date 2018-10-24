// Copyright (c) Facebook, Inc. and its affiliates. All Rights Reserved.
// All rights reserved.
//
// This source code is licensed under the license found in the
// LICENSE file in the root directory of this source tree.


// If M_OUT <= M, then there is overflow/underflow checking on the output
module LogMultiply #(parameter M=3,
                     parameter F=4,
                     parameter M_OUT=4,
                     parameter SATURATE_MAX=1)
  (LogNumberUnpacked.InputIf a,
   LogNumberUnpacked.InputIf b,
   LogNumberUnpacked.OutputIf c);

  initial begin
    assert(a.M == M);
    assert(a.F == F);
    assert(b.M == M);
    assert(b.F == F);
    assert(c.M == M_OUT);
    assert(c.F == F);

    assert(M_OUT >= M);
  end

  logic sign;

  // Expanded form of a and b for addition (with a carry bit)
  logic signed [M+F-1:0] mulA;
  logic signed [M+F-1:0] mulB;

  // The sum of the above
  logic signed [M+F:0] mul;

  // The output exponent
  logic signed [M_OUT-1:0] logExpOut;

  logic underflow;
  logic overflow;

  generate
    if (M_OUT <= M) begin
      always_comb begin
        // It is necessary to check for log exponent underflow/overflow
        underflow = signed'(mul[M+F:F]) < signed'((M+1)'(-(2 ** (M_OUT-1))));
        overflow = signed'(mul[M+F:F]) >= signed'((M+1)'(2 ** (M_OUT-1)));
      end
    end else begin
      // If M_OUT is larger, then we can hold the largest and smallest possible
      // product
      always_comb begin
        underflow = 1'b0;
        overflow = 1'b0;
      end
    end
  endgenerate

  always_comb begin
    // Resulting sign of the multiply
    sign = a.data.sign ^ b.data.sign;

    mulA = {a.data.signedLogExp, a.data.logFrac};
    mulB = {b.data.signedLogExp, b.data.logFrac};

    mul = (F+M+1)'(mulA) + (F+M+1)'(mulB);

    c.data.isInf = a.data.isInf || b.data.isInf || (!SATURATE_MAX && overflow);
    c.data.isZero = !c.data.isInf &&
                    (a.data.isZero || b.data.isZero || underflow);

    // sign can be garbage if isInf || isZero
    c.data.sign = sign;

    logExpOut = M_OUT'(mul[M+F:F]);

    // signedLogExp and logFrac can be garbage if isInf || isZero
    if (SATURATE_MAX && overflow) begin
      // maximum positive signed exponent
      c.data.signedLogExp = {1'b0, {(M_OUT-1){1'b1}}};
      c.data.logFrac = {F{1'b1}};
    end else begin
      c.data.signedLogExp = logExpOut;
      c.data.logFrac = mul[F-1:0];
    end
  end
endmodule
