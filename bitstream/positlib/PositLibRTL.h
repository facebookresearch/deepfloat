// Copyright (c) Facebook, Inc. and its affiliates. All Rights Reserved.
// All rights reserved.
//
// This source code is licensed under the license found in the
// LICENSE file in the root directory of this source tree.

#ifndef __POSIT_LIB_RTL__
#define __POSIT_LIB_RTL__

#define TYPE_WIDTH 8
#define TYPE_ES 1

#if TYPE_WIDTH <= 8
typedef unsigned char FloatType;
#elif TYPE_WIDTH <= 16
typedef unsigned short FloatType;
#else
#error Unhandled width
#endif

typedef unsigned char OpType;
typedef unsigned char DeviceBool;

#define kDeviceFalse 0
#define kDeviceTrue 1

#define kVectorOp 0
#define kDeviceScalarOp 1
#define kHostScalarOp 2

#define kAdd 0
#define kSub 1
#define kMul 2
#define kDiv 3
#define kMin 4
#define kMax 5

// matches Comparison_pkg.sv
#define kComp_EQ 0
#define kComp_NE 1
#define kComp_LT 2
#define kComp_LE 3
#define kComp_GT 4
#define kComp_GE 5

#if TYPE_WIDTH == 7

// (7, e)-posit
#define kZeroValue (FloatType) 0
#define kMaxValue (FloatType) 0x3f
#define kInfValue (FloatType) 0x40
#define kMinValue (FloatType) 0x01
#define kLowestValue (FloatType) 0x7f

#elif TYPE_WIDTH == 8

// (8, e)-posit
#define kZeroValue (FloatType) 0
#define kMaxValue (FloatType) 0x7f
#define kInfValue (FloatType) 0x80
#define kMinValue (FloatType) 0x01
#define kLowestValue (FloatType) 0xff

#elif TYPE_WIDTH == 9

// (9, e)-posit
#define kZeroValue (FloatType) 0
#define kMaxValue (FloatType) 0x00ff
#define kInfValue (FloatType) 0x0100
#define kMinValue (FloatType) 0x0001
#define kLowestValue (FloatType) 0x01ff

#elif TYPE_WIDTH == 11

// (11, e)-posit
#define kZeroValue (FloatType) 0
#define kMaxValue (FloatType) 0x03ff
#define kInfValue (FloatType) 0x0400
#define kMinValue (FloatType) 0x0001
#define kLowestValue (FloatType) 0x07ff

#else
#error Unhandled
#endif

// FIXME: this is based on our current inversion of the standard
// posit layout in RTL
#define NEG_FLOAT(X) (kInfValue ^ X)

#if (TYPE_WIDTH == 8) && (TYPE_ES == 0)

typedef unsigned int Product;
typedef unsigned int Accumulator;
#define ACC_ZERO(a) a = (Accumulator) 0

#elif TYPE_WIDTH <= 11

typedef unsigned int Product;
typedef unsigned long Accumulator;
#define ACC_ZERO(a) a = (Accumulator) 0

#else
#error Unhandled
#endif

#endif
