# Copyright (c) Facebook, Inc. and its affiliates. All Rights Reserved.
# All rights reserved.
#
# This source code is licensed under the license found in the
# LICENSE file in the root directory of this source tree.

import argparse
import os
import shutil
import time
import glob
import subprocess
import sys
import math

import torch
from torch.utils.cpp_extension import CppExtension, BuildExtension

def init_fpga(aocx_file, dir='../bitstream'):
    files = []
    files.extend(glob.glob('../cpp/utils/*.cpp'))
    files.extend(glob.glob('../cpp/ops/*.cpp'))
    files.extend(glob.glob('../cpp/layers/*.cpp'))
    files.append('../cpp/PythonInterface.cpp')

    aocl_compile_conf = subprocess.check_output(
        ['aocl', 'compile-config']).decode('utf-8').strip()
    aocl_link_conf = subprocess.check_output(
        ['aocl', 'link-config']).decode('utf-8').strip()

    ext = torch.utils.cpp_extension.load(
        name='fpga_extension',
        sources=files,
        extra_cflags=[aocl_compile_conf, '-g'],
        extra_ldflags=[aocl_link_conf],
        extra_include_paths=['../cpp/'],
        verbose=False)

    dev = ext.fpga_init(dir, aocx_file)

    return ext, dev
