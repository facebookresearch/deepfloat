// Copyright (c) Facebook, Inc. and its affiliates. All Rights Reserved.
// All rights reserved.
//
// This source code is licensed under the license found in the
// LICENSE file in the root directory of this source tree.
#pragma once

namespace facebook {

constexpr int kWidth = 8;
constexpr int kES = 1;

template <int Width>
struct FloatType;

template <>
struct FloatType<7> {
  typedef unsigned char T;

  static constexpr T kZero = 0;
  static constexpr T kOne = 0x20;
  static constexpr T kMax = 0x3f;
  static constexpr T kInf = 0x40;
  static constexpr T kMin = 0x01;

  static constexpr T neg(T v) { return v ^ kInf; }
};

template <>
struct FloatType<8> {
  typedef unsigned char T;

  static constexpr T kZero = 0;
  static constexpr T kOne = 0x40;
  static constexpr T kMax = 0x7f;
  static constexpr T kInf = 0x80;
  static constexpr T kMin = 0x01;

  static constexpr T neg(T v) { return v ^ kInf; }
};

template <>
struct FloatType<9> {
  typedef unsigned short T;

  static constexpr T kZero = 0;
  static constexpr T kOne = 0x80;
  static constexpr T kMax = 0xff;
  static constexpr T kInf = 0x100;
  static constexpr T kMin = 0x01;

  static constexpr T neg(T v) { return v ^ kInf; }
};

template <>
struct FloatType<11> {
  typedef unsigned short T;

  static constexpr T kZero = 0;
  static constexpr T kOne = 0x200;
  static constexpr T kMax = 0x3ff;
  static constexpr T kInf = 0x400;
  static constexpr T kMin = 0x001;

  static constexpr T neg(T v) { return v ^ kInf; }
};


typedef unsigned char OpType;
typedef unsigned char DeviceBool;

constexpr DeviceBool kDeviceFalse = 0;
constexpr DeviceBool kDeviceTrue = 1;

constexpr DeviceBool toDeviceBool(bool v) {
  return v ? kDeviceTrue : kDeviceFalse;
}

/// Pointwise function options
/// FIXME: remove
constexpr OpType kVectorOp = 0;
constexpr OpType kDeviceScalarOp = 1;
constexpr OpType kHostScalarOp = 2;

/// Math operations
/// FIXME: remove
constexpr OpType kMathOp_Add = 0;
constexpr OpType kMathOp_Sub = 1;
constexpr OpType kMathOp_Mul = 2;
constexpr OpType kMathOp_Div = 3;
constexpr OpType kMathOp_Min = 4;
constexpr OpType kMathOp_Max = 5;

/// Comparison options
/// FIXME: remove
constexpr OpType kComp_EQ = 0;
constexpr OpType kComp_NE = 1;
constexpr OpType kComp_LT = 2;
constexpr OpType kComp_LE = 3;
constexpr OpType kComp_GT = 4;
constexpr OpType kComp_GE = 5;

} // namespace
