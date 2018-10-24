#!/usr/bin/python
# Copyright (c) Facebook, Inc. and its affiliates. All Rights Reserved.
# All rights reserved.
#
# This source code is licensed under the license found in the
# LICENSE file in the root directory of this source tree.

from __future__ import absolute_import
from __future__ import division
from __future__ import print_function
from __future__ import unicode_literals

import argparse
import re
import os
import glob
import shutil

parser = argparse.ArgumentParser(
    description='Generates XML RTL descriptor file for OpenCL compilation',
    epilog='', formatter_class=argparse.RawTextHelpFormatter
)
requiredNamed = parser.add_argument_group('required named arguments')

requiredNamed.add_argument('--input', '-i', metavar='<input file>', type=str,
                           nargs=1, required=True, help='input file')
requiredNamed.add_argument('--output_xml', '-x', metavar='<output file>', type=str,
                           nargs=1, required=True, help='output file')
requiredNamed.add_argument('--output_rtl', '-t', metavar='<output file>', type=str,
                           nargs=1, required=True, help='output file')
requiredNamed.add_argument('--rtl_root', '-r', metavar='<rtl root>', type=str,
                           nargs=1, required=True, help='rtl root location')
requiredNamed.add_argument('--output_stub', '-s', metavar='<output file>', type=str,
                           nargs=1, required=True, help='output file')

args = parser.parse_args()

input_file = open(args.input[0], 'r')
output_xml = open(args.output_xml[0], 'w')
output_rtl = open(args.output_rtl[0], 'w')
output_stub = open(args.output_stub[0], 'w')

type_width = None
acc_width = None
product_width = None

acc_divide_cycles = None
type_divide_cycles = None

rtl_files = []
stub_files = []

def include_sv_files(file_list, cur_dir=False):
    for filename in file_list:
        if (not cur_dir):
            filename = os.path.join(args.rtl_root[0], filename)
        rtl_files.append(filename)

def include_files(file_list, cur_dir=False):
    for filename in file_list:
        if (not cur_dir):
            filename = os.path.join(args.rtl_root[0], filename)
        shutil.copyfile(filename, os.path.basename(filename))

def include_stub_files(file_list):
    for filename in file_list:
        stub_files.append(filename)

def set_type_width(w):
    # FIXME: huh?
    globals()['type_width'] = w

def set_acc_width(w):
    globals()['acc_width'] = w

def set_product_width(w):
    globals()['product_width'] = w

def set_acc_divide_cycles(c):
    globals()['acc_divide_cycles'] = c

def set_type_divide_cycles(c):
    globals()['type_divide_cycles'] = c

lines = []
doing_python = 0
code_block = ''
comment_indent = ''
RE_PYTHON_BLOCK_BEGIN = re.compile(r"^(\s*)START_PY(\s*)$")
RE_PYTHON_BLOCK_END = re.compile(r'^(\s*)END_PY(\s*)$')

for line in input_file:
    reg0 = re.search(RE_PYTHON_BLOCK_BEGIN, line)
    reg1 = re.search(RE_PYTHON_BLOCK_END, line)
    if doing_python == 0 and reg0:
        doing_python = 1
        code_block = ''
        lines.append(reg0.group(1) + '\n<!-- python -->\n')
        comment_indent = reg0.group(1)
    elif doing_python == 1 and reg1:
        doing_python = 0
        try:
            exec(code_block)
        except Exception:
            print("Error in code:\n" + code_block + "\n")
            raise
        lines.append(reg1.group(1) + '\n<!-- end python -->\n')
    elif doing_python == 1:
        dum = re.sub(r"^(" + comment_indent + r")", r'', line)
        code_block += dum
    else:
        # Main XML block
        line = re.sub('(TYPE_WIDTH)', '{}'.format(type_width), line)
        line = re.sub('(ACC_WIDTH)', '{}'.format(acc_width), line)
        line = re.sub('(PRODUCT_WIDTH)', '{}'.format(product_width), line)
        line = re.sub('(ACC_DIVIDE_CYCLES)', '{}'.format(acc_divide_cycles), line)
        line = re.sub('(TYPE_DIVIDE_CYCLES)', '{}'.format(type_divide_cycles), line)

        lines.append(line)

for line in lines:
    output_xml.write(line)

input_file.close()
output_xml.close()

# write the single RTL file
for filename in rtl_files:
    f = open(filename, 'r')

    output_rtl.write("// ***\n// *** RTL from source file {}\n// ***\n\n".format(filename))
    for line in f:
        output_rtl.write(line)
    f.close()
    output_rtl.write("\n\n");

output_rtl.close()

# write the single stub OpenCL file
for filename in stub_files:
    f = open(filename, 'r')

    output_stub.write("// ***\n// *** OpenCL from source file {}\n// ***\n\n".format(filename))
    for line in f:
        output_stub.write(line)
    f.close()
    output_stub.write("\n\n");

output_stub.close()
