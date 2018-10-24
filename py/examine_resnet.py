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
import validate

import torch
import torch.nn as nn
import torchvision.models as models
import torchvision.models.resnet as resnet

# def fuse_bn(conv, bn):
#     conv_w = conv.weight.clone()
#     conv_b = None
#     if (conv.bias):
#         conv_b = conv.bias.clone()
#     else:
#         conv_b = torch.FloatTensor(conv_w.size(0)).zero_()

#     for c in range(conv_w.size(0)):
#         bn_mean = bn.running_mean[c]
#         bn_var = bn.running_var[c]
#         bn_weight = bn.weight[c]
#         bn_bias = bn.bias[c]

#         inv_var = 1.0 / math.sqrt(bn_var + 1e-5)

#         conv_w[c].mul_(bn_weight * inv_var)
#         conv_b[c].add_(-bn_mean * inv_var * bn_weight + bn_bias)

#     return conv_w, conv_b

# def fuse_resnet_params(m):
#     convs = []

#     convs.append([m.conv1, m.bn1])
#     for seq in [m.layer1, m.layer2, m.layer3, m.layer4]:
#         for bb in seq:
#             convs.append([bb.conv1, bb.bn1])
#             convs.append([bb.conv2, bb.bn2])
#             if (bb.conv3):
#                 convs.append([bb.conv3, bb.bn3])
#             if (bb.downsample):
#                 convs.append([bb.downsample[0], bb.downsample[1]])

#     params = []
#     for c in convs:
#         w, b = fuse_bn(c[0], c[1])
#         params.append(['conv', [w, b]])

#     params.append(['fc', [m.fc.weight, m.fc.bias]])
#     return params

# def orig_resnet_params(m):
#     modules = []

#     modules.extend([['conv', m.conv1], ['bn', m.bn1]])
#     for seq in [m.layer1, m.layer2, m.layer3, m.layer4]:
#         for bb in seq:
#             modules.extend([['conv', bb.conv1], ['bn', bb.bn1]])
#             modules.extend([['conv', bb.conv2], ['bn', bb.bn2]])
#             if (bb.conv3):
#                 modules.extend([['conv', bb.conv3], ['bn', bb.bn3]])
#             if (bb.downsample):
#                 modules.extend([['conv', bb.downsample[0]], ['bn', bb.downsample[1]]])
#     modules.append(['fc', m.fc])

#     params = []
#     for m in modules:
#         if (m[0] == 'conv'):
#             if (m[1].bias != None):
#                 params.append([m[0], [m[1].weight,
#                                       m[1].bias]])
#             else:
#                 params.append([m[0], [m[1].weight]])
#         elif (m[0] == 'bn'):
#             params.append([m[0], [m[1].running_mean,
#                                   m[1].running_var,
#                                   m[1].weight,
#                                   m[1].bias]])
#         elif (m[0] == 'fc'):
#             params.append([m[0], [m[1].weight,
#                                   m[1].bias]])
#     return params

# destructiely updates conv
def fuse_bn(conv, bn):
    conv_w = conv.weight
    conv_b = None
    if (conv.bias):
        conv_b = conv.bias
    else:
        conv_b = torch.FloatTensor(conv_w.size(0)).zero_()
        conv.bias = torch.nn.Parameter(conv_b)

    for c in range(conv_w.size(0)):
        bn_mean = bn.running_mean[c]
        bn_var = bn.running_var[c]
        bn_weight = bn.weight[c]
        bn_bias = bn.bias[c]

        inv_var = 1.0 / math.sqrt(bn_var + 1e-5)

        conv_w[c].mul_(bn_weight * inv_var)
        conv_b[c].add_(-bn_mean * inv_var * bn_weight + bn_bias)

# param_stats = []
# act_stats = []

# def get_stats(t):
#     t_abs = t.abs()
#     t_sort = t_abs.view(t_abs.nelement()).sort()[0]
#     num = t_sort.nelement()

#     return [t_sort[int(0.5 * num)].item(),
#             t_sort[int(0.9 * num)].item(),
#             t_sort[int(0.95 * num)].item(),
#             t_sort[int(0.99 * num)].item(),
#             t_sort[int(0.995 * num)].item(),
#             t_sort[int(0.999 * num)].item(),
#             t_sort[-1].item()]

# def print_act(name, t):
#     act_stats.append([name, get_stats(t)])

# def print_params(name, m):
#     w = get_stats(m.weight)

#     b = None
#     if m.bias is not None:
#         b = get_stats(m.bias)
#     param_stats.append([name, w, b])

def new_forward(self, x):
    residual = x

    out = self.conv1(x)
    out = self.relu(out)

    out = self.conv2(out)
    out = self.relu(out)

    if (hasattr(self, 'conv3')):
        out = self.conv3(out)

    if self.downsample is not None:
        residual = self.downsample[0](x)

    out += residual
    out = self.relu(out)

    return out

def new_resnet_forward(self, x):
    x = self.conv1(x)
    x = self.relu(x)
    x = self.maxpool(x)

    x = self.layer1(x)
    x = self.layer2(x)
    x = self.layer3(x)
    x = self.layer4(x)

    x = self.avgpool(x)
    x = x.view(x.size(0), -1)
    x = self.fc(x)

    return x

def fuse_resnet_params(m):
    resnet.Bottleneck.forward = new_forward
    resnet.ResNet.forward = new_resnet_forward

    m.fused = True
    fuse_bn(m.conv1, m.bn1)
    del m.bn1
    for seq in [m.layer1, m.layer2, m.layer3, m.layer4]:
        seq.fused = True
        for bb in seq:
            bb.fused = True
            fuse_bn(bb.conv1, bb.bn1)
            del bb.bn1
            fuse_bn(bb.conv2, bb.bn2)
            del bb.bn2
            if (hasattr(bb, 'conv3')):
                fuse_bn(bb.conv3, bb.bn3)
                del bb.bn3
            if (bb.downsample):
                fuse_bn(bb.downsample[0], bb.downsample[1])
                del bb.downsample[1]
