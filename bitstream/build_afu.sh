#!/bin/bash
# Copyright (c) Facebook, Inc. and its affiliates. All Rights Reserved.
# All rights reserved.
#
# This source code is licensed under the license found in the
# LICENSE file in the root directory of this source tree.

if [ $# -eq 0 ]
then
    echo "Must specify bitstream to build"
    exit 1
fi

LIB_NAME=$1

if [ ! -d "$LIB_NAME" ]
then
    echo "Directory $LIB_NAME doesn't exist"
    exit 1
fi

echo "**** Compiling design $LIB_NAME"
pushd build_${LIB_NAME}

aoc -report -v ${LIB_NAME}.aoco
#aoc -march=emulator -report -v ${LIB_NAME}.aoco

popd
