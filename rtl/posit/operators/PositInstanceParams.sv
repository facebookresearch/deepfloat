// Copyright (c) Facebook, Inc. and its affiliates. All Rights Reserved.
// All rights reserved.
//
// This source code is licensed under the license found in the
// LICENSE file in the root directory of this source tree.


/*

//
// (7, 1)-posit
//

// how large the CPU size is to wrap a posit
parameter CONFIG_POSIT_WRAP_BITS = 8;
parameter CONFIG_POSIT_WIDTH = 7;
parameter CONFIG_POSIT_ES = 1;

parameter CONFIG_QUIRE_OVERFLOW = 0;
// how large the CPU size is to wrap a quire
parameter CONFIG_QUIRE_WRAP_BITS = 64;
parameter CONFIG_QUIRE_BITS = 35;

parameter CONFIG_POSIT_PRODUCT_WRAP_BITS = 32;
parameter CONFIG_POSIT_PRODUCT_FRAC_BITS = 8;
parameter CONFIG_POSIT_PRODUCT_EXP_BITS = 6;

*/

/*

//
// (8, 0)-posit
//

// how large the CPU size is to wrap a posit
parameter CONFIG_POSIT_WRAP_BITS = 8;
parameter CONFIG_POSIT_WIDTH = 8;
parameter CONFIG_POSIT_ES = 0;

parameter CONFIG_QUIRE_OVERFLOW = 0;
// how large the CPU size is to wrap a quire
parameter CONFIG_QUIRE_WRAP_BITS = 32;
parameter CONFIG_QUIRE_BITS = 23;

parameter CONFIG_POSIT_PRODUCT_WRAP_BITS = 32;
parameter CONFIG_POSIT_PRODUCT_FRAC_BITS = 12;
parameter CONFIG_POSIT_PRODUCT_EXP_BITS = 5;

*/

//
// (8, 1)-posit
//

// how large the CPU size is to wrap a posit
parameter CONFIG_POSIT_WRAP_BITS = 8;
parameter CONFIG_POSIT_WIDTH = 8;
parameter CONFIG_POSIT_ES = 1;

parameter CONFIG_QUIRE_OVERFLOW = 0;
// how large the CPU size is to wrap a quire
parameter CONFIG_QUIRE_WRAP_BITS = 64;
parameter CONFIG_QUIRE_BITS = 41;

parameter CONFIG_POSIT_PRODUCT_WRAP_BITS = 32;
parameter CONFIG_POSIT_PRODUCT_FRAC_BITS = 10;
parameter CONFIG_POSIT_PRODUCT_EXP_BITS = 6;

/*

//
// (8, 2)-posit
//

// how large the CPU size is to wrap a posit
parameter CONFIG_POSIT_WRAP_BITS = 8;
parameter CONFIG_POSIT_WIDTH = 8;
parameter CONFIG_POSIT_ES = 2;

parameter CONFIG_QUIRE_N = 64;
// how large the CPU size is to wrap a quire
parameter CONFIG_QUIRE_WRAP_BITS = 128;
parameter CONFIG_QUIRE_BITS = 107;

parameter CONFIG_POSIT_PRODUCT_WRAP_BITS = 32;
parameter CONFIG_POSIT_PRODUCT_FRAC_BITS = 8;
parameter CONFIG_POSIT_PRODUCT_EXP_BITS = 7;

*/

/*

//
// (9, 1)-posit
//

// how large the CPU size is to wrap a posit
parameter CONFIG_POSIT_WRAP_BITS = 16;
parameter CONFIG_POSIT_WIDTH = 9;
parameter CONFIG_POSIT_ES = 1;

parameter CONFIG_QUIRE_OVERFLOW = 0;
// how large the CPU size is to wrap a quire
parameter CONFIG_QUIRE_WRAP_BITS = 64;
parameter CONFIG_QUIRE_BITS = 47;

parameter CONFIG_POSIT_PRODUCT_WRAP_BITS = 32;
parameter CONFIG_POSIT_PRODUCT_FRAC_BITS = 12;
parameter CONFIG_POSIT_PRODUCT_EXP_BITS = 6;

*/

/*

//
// (11, 1)-posit
//

// how large the CPU size is to wrap a posit
parameter CONFIG_POSIT_WRAP_BITS = 16;
parameter CONFIG_POSIT_WIDTH = 11;
parameter CONFIG_POSIT_ES = 1;

parameter CONFIG_QUIRE_OVERFLOW = 0;
// how large the CPU size is to wrap a quire
parameter CONFIG_QUIRE_WRAP_BITS = 64;
parameter CONFIG_QUIRE_BITS = 59;

parameter CONFIG_POSIT_PRODUCT_WRAP_BITS = 32;
parameter CONFIG_POSIT_PRODUCT_FRAC_BITS = 16;
parameter CONFIG_POSIT_PRODUCT_EXP_BITS = 7;

*/

//
// general
//

parameter CONFIG_POSIT_PRODUCT_BITS = (CONFIG_POSIT_PRODUCT_FRAC_BITS +
                                       CONFIG_POSIT_PRODUCT_EXP_BITS +
                                       3);
