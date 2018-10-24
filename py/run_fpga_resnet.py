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

import fpga
import fpga_resnet
import torch
from torch.utils.cpp_extension import CppExtension, BuildExtension
import torchvision.models as models
import validate

aocx_file = 'loglib'

ext, dev = fpga.init_fpga(aocx_file)

class FpgaNN():
    def __init__(self, model, mul_factor=1.0):
        self.model = model
        self.output_p = None
        self.mul_factor = mul_factor

    def forward(self, input):
        input_p = ext.to_posit(*dev, input)
        self.output_p = self.model.forward(*dev, input_p)

        # FIXME: attempt to fix d2h copy assert
        dev[2].blockingWait()
        return ext.to_float(*dev, self.output_p).mul_(self.mul_factor)

    def forward_p(self, input):
        input_p = ext.to_posit(*dev, input)
        self.output_p = self.model.forward(*dev, input_p)

    def forward_f(self):
        return ext.to_float(*dev, self.output_p).mul_(self.mul_factor)

def get_fpga_mods(model):
    def append_mod(mods, m, name):
        mods.append([name, m])

    mods = []

    for m, name in zip([model.conv1, model.maxpool],
                       ['conv1', 'maxpool']):
        append_mod(mods, m, name)

    for layer, layer_name in zip([model.layer1, model.layer2, model.layer3, model.layer4],
                                 ['layer1', 'layer2', 'layer3', 'layer4']):
        for idx, seq in enumerate(layer):
            for m, name in zip([seq.conv1, seq.conv2],
                               ['conv1', 'conv2']):
                append_mod(mods, m,
                           '{}.{}.{}'.format(layer_name, idx, name))

            if (hasattr(seq, 'conv3')):
                append_mod(mods, seq.conv3,
                           '{}.{}.{}'.format(layer_name, idx, 'conv3'))

            if (seq.downsample):
                append_mod(mods, seq.downsample,
                           '{}.{}.{}.0'.format(layer_name, idx, 'downsample'))

            append_mod(mods, seq.add,
                       '{}.{}.{}'.format(layer_name, idx, 'add'))

    for m, name in zip([model.avgpool, model.fc], ['avgpool', 'fc']):
        append_mod(mods, m, name)

    return mods

cpu_model = models.resnet50(True)
cpu_model.eval()

fc_n_scale = -4

fpga_model = fpga_resnet.resnet50(ext, *dev)
fpga_model.fc.setOutputScale(fc_n_scale)

fpga_resnet.fuse_resnet_params(ext, dev, cpu_model, fpga_model, fc_mul=1.0)

loader = validate.make_loader(batch_size=16, random=False)

scale = 2.0 ** fc_n_scale
mod = FpgaNN(fpga_model, 1.0 / scale)

print('ResNet-50 {}:'.format(aocx_file))
validate.validate(loader,
                  limit=None,
                  fpga_h=mod,
#                  reference_model=cpu_model)
                  reference_model=None)
