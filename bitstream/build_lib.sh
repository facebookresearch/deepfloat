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
USE_EMULATOR=$2

if [ ! -d "$LIB_NAME" ]
then
    echo "Directory $LIB_NAME doesn't exist"
    exit 1
fi

echo "**** Deleting build directory build_$LIB_NAME"
rm -rf build_${LIB_NAME}
echo "**** Creating build directory build_$LIB_NAME"
mkdir -p build_${LIB_NAME}

cp ${LIB_NAME}/*.cl build_${LIB_NAME}/
cp ${LIB_NAME}/*.h build_${LIB_NAME}/

pushd build_${LIB_NAME}

echo "**** Copying and flattening dependent RTL and OpenCL"
../build_xml.py -i ../${LIB_NAME}/${LIB_NAME}.pxml --output_xml ${LIB_NAME}.xml --output_rtl ${LIB_NAME}.sv --rtl_root ../../rtl --output_stub ${LIB_NAME}_stub.cl

echo "**** Building $LIB_NAME.aoco"
aocl library hdl-comp-pkg ${LIB_NAME}.xml -o ${LIB_NAME}_tmp.aoco

echo "**** Building $LIB_NAME.aoclib"
aocl library create -name ${LIB_NAME} -o ${LIB_NAME}.aoclib ${LIB_NAME}_tmp.aoco


if [ -z "$USE_EMULATOR" ]
then
    echo "**** Compiling $LIB_NAME kernel library (non-emulated)"
    aoc -report -v -I $ALTERAOCLSDKROOT/include/kernel_headers -l ${LIB_NAME}.aoclib -c ${LIB_NAME}.cl -o ${LIB_NAME}.aoco
else
    echo "**** Compiling $LIB_NAME kernel library (emulated)"
    aoc -march=emulator -report -v -I $ALTERAOCLSDKROOT/include/kernel_headers -l ${LIB_NAME}.aoclib -c ${LIB_NAME}.cl -o ${LIB_NAME}.aoco
fi

popd
