# Copyright (c) Facebook, Inc. and its affiliates. All Rights Reserved.
# All rights reserved.
#
# This source code is licensed under the license found in the
# LICENSE file in the root directory of this source tree.

import torch
import math
from torch.utils.cpp_extension import CppExtension, BuildExtension

def inspect(name, ext, context, program, queue, x):
    return
#    f = ext.to_float(context, program, queue, x).abs_()
#    print('{}: mean {} max {}'.format(name, f.mean(), f.max()))

class Sequential():
    def __init__(self, *args):
        self.modules = [*args]

    def __len__(self):
        return len(self.modules)

    def __getitem__(self, idx):
        return self.modules[idx]

    def add(self, *args):
        for a in arg:
            self.modules.append(a)

    def forward(self, context, program, queue, x):
        for m in self.modules:
            x = m.forward(context, program, queue, x)
        return x

class BasicBlock():
    expansion = 1

    def __init__(self, ext, context, program, queue,
                 inplanes, planes, stride=1, downsample=None):
        self.ext = ext
        self.conv1 = ext.Conv2d(context, program, queue,
                                inplanes, planes,
                                3, stride,
                                1, 1,
                                False, 0, 0)
        self.relu1 = ext.ReLU(context, program, queue)
        self.conv2 = ext.Conv2d(context, program, queue,
                                planes, planes,
                                3, 1,
                                1, 1,
                                False, 0, 0)
        self.relu2 = ext.ReLU(context, program, queue)
        self.downsample = downsample
        self.stride = stride
        self.add = ext.Add(context, program, queue, 0, 0, 0)

    def forward(self, context, program, queue, x):
        residual = x
        ext = self.ext

        out = self.conv1.forward(context, program, queue, x)
        inspect("conv1", ext, context, program, queue, out)
        out = self.relu1.forward(context, program, queue, out)
        inspect("relu1", ext, context, program, queue, out)
        out = self.conv2.forward(context, program, queue, out)
        inspect("conv2", ext, context, program, queue, out)

        if self.downsample is not None:
            residual = self.downsample.forward(context, program, queue, x)
            inspect("residual downsample", ext, context, program, queue, residual)

        self.add.setAdd(residual)
#        inspect("residual", ext, context, program, queue, residual)
        out = self.add.forward(context, program, queue, out)
#        inspect("add", ext, context, program, queue, out)
        out = self.relu2.forward(context, program, queue, out)
        inspect("relu2", ext, context, program, queue, out)

        return out


class Bottleneck():
    expansion = 4

    def __init__(self, ext, context, program, queue,
                 inplanes, planes, stride=1, downsample=None):
        self.ext = ext
        self.conv1 = ext.Conv2d(context, program, queue,
                                inplanes, planes,
                                1, 1,
                                0, 0,
                                False, 0, 0)
        self.relu1 = ext.ReLU(context, program, queue)
        self.conv2 = ext.Conv2d(context, program, queue,
                                planes, planes,
                                3, stride,
                                1, 1,
                                False, 0, 0)
        self.relu2 = ext.ReLU(context, program, queue)
        self.conv3 = ext.Conv2d(context, program, queue,
                                planes, planes * self.expansion,
                                1, 1,
                                0, 0,
                                False, 0, 0)
        self.relu3 = ext.ReLU(context, program, queue)
        self.downsample = downsample
        self.stride = stride
        self.add = ext.Add(context, program, queue, 0, 0, 0)

    def forward(self, context, program, queue, x):
        residual = x
        ext = self.ext

        out = self.conv1.forward(context, program, queue, x)
        inspect("bottleneck conv1", ext, context, program, queue, out)
        out = self.relu1.forward(context, program, queue, out)
        inspect("bottleneck relu1", ext, context, program, queue, out)

        out = self.conv2.forward(context, program, queue, out)
        inspect("bottleneck conv2", ext, context, program, queue, out)
        out = self.relu2.forward(context, program, queue, out)
        inspect("bottleneck relu2", ext, context, program, queue, out)

        out = self.conv3.forward(context, program, queue, out)
        inspect("bottleneck conv3", ext, context, program, queue, out)

        if self.downsample is not None:
            residual = self.downsample.forward(context, program, queue, x)
            inspect("residual downsample", ext, context, program, queue, residual)

        self.add.setAdd(residual)
        out = self.add.forward(context, program, queue, out)
        inspect("bottleneck add", ext, context, program, queue, out)
        out = self.relu3.forward(context, program, queue, out)
        inspect("bottleneck relu3", ext, context, program, queue, out)

        return out

class ResNet():
    def __init__(self, ext, context, program, queue,
                 block, layers, num_classes=1000):
        self.inplanes = 64
        self.ext = ext

        self.conv1 = ext.Conv2d(context, program, queue,
                                3, 64,
                                7, 2,
                                3, 3, False, 0, 0)
        self.relu = ext.ReLU(context, program, queue)
        self.maxpool = ext.Pool2d(context, program, queue,
                                  3, 2, 1, 1, ext.PoolOp.Max, 0, 0)
        self.layer1 = self._make_layer(ext, context, program, queue,
                                       block, 64, layers[0])
        self.layer2 = self._make_layer(ext, context, program, queue,
                                       block, 128, layers[1], stride=2)
        self.layer3 = self._make_layer(ext, context, program, queue,
                                       block, 256, layers[2], stride=2)
        self.layer4 = self._make_layer(ext, context, program, queue,
                                       block, 512, layers[3], stride=2)
        self.avgpool = ext.Pool2d(context, program, queue,
                                  7, 1, 0, 0, ext.PoolOp.Avg, 0, 0)
        self.view = ext.View(context, program, queue,
                             [[0], [1, 2, 3]])
        self.fc = ext.Linear(context, program, queue,
                             512 * block.expansion, num_classes, True, 0, 0)

    def _make_layer(self, ext, context, program, queue,
                    block, planes, blocks, stride=1):
        downsample = None
        if stride != 1 or self.inplanes != planes * block.expansion:
            downsample = ext.Conv2d(context, program, queue,
                                    self.inplanes, planes * block.expansion,
                                    1, stride, 0, 0,
                                    False, 0, 0)

        layers = []
        layers.append(block(ext, context, program, queue,
                            self.inplanes, planes, stride, downsample))
        self.inplanes = planes * block.expansion
        for i in range(1, blocks):
            layers.append(block(ext, context, program, queue,
                                self.inplanes, planes))

        return Sequential(*layers)

    def forward(self, context, program, queue, x):
        ext = self.ext
        inspect("input", ext, context, program, queue, x)
        x = self.conv1.forward(context, program, queue, x)
        inspect("conv1", ext, context, program, queue, x)
        x = self.relu.forward(context, program, queue, x)
        inspect("relu1", ext, context, program, queue, x)
        x = self.maxpool.forward(context, program, queue, x)
        inspect("maxpool", ext, context, program, queue, x)

        x = self.layer1.forward(context, program, queue, x)
        inspect("layer1 out", ext, context, program, queue, x)
        x = self.layer2.forward(context, program, queue, x)
        inspect("layer2 out", ext, context, program, queue, x)
        x = self.layer3.forward(context, program, queue, x)
        inspect("layer3 out", ext, context, program, queue, x)
        x = self.layer4.forward(context, program, queue, x)
        inspect("layer4 out", ext, context, program, queue, x)

        x = self.avgpool.forward(context, program, queue, x)
        inspect("avgpool out", ext, context, program, queue, x)
        x = self.view.forward(context, program, queue, x)
        inspect("view out", ext, context, program, queue, x)
        x = self.fc.forward(context, program, queue, x)
        inspect("fc out", ext, context, program, queue, x)

        return x

def resnet18(ext, context, program, queue, pretrained=False, **kwargs):
    model = ResNet(ext, context, program, queue, BasicBlock, [2, 2, 2, 2], **kwargs)
    return model

def resnet34(ext, context, program, queue, pretrained=False, **kwargs):
    model = ResNet(ext, context, program, queue, BasicBlock, [3, 4, 6, 3], **kwargs)
    return model

def resnet50(ext, context, program, queue, pretrained=False, **kwargs):
    model = ResNet(ext, context, program, queue, Bottleneck, [3, 4, 6, 3], **kwargs)
    return model

def resnet101(ext, context, program, queue, pretrained=False, **kwargs):
    model = ResNet(ext, context, program, queue, Bottleneck, [3, 4, 23, 3], **kwargs)
    return model

def resnet152(ext, context, program, queue, pretrained=False, **kwargs):
    model = ResNet(ext, context, program, queue, Bottleneck, [3, 8, 36, 3], **kwargs)
    return model

def fuse_bn(conv, bn):
    conv_w = conv.weight.clone()
    conv_b = None
    if (conv.bias):
        conv_b = conv.bias.clone()
    else:
        conv_b = torch.FloatTensor(conv_w.size(0)).zero_()

    for c in range(conv_w.size(0)):
        bn_mean = bn.running_mean[c]
        bn_var = bn.running_var[c]
        bn_weight = bn.weight[c]
        bn_bias = bn.bias[c]

        inv_var = 1.0 / math.sqrt(bn_var + 1e-5)

        conv_w[c].mul_(bn_weight * inv_var)
        conv_b[c].add_(-bn_mean * inv_var * bn_weight + bn_bias)

    return conv_w, conv_b

def apply_params(ext, dev, w, b, m):
    w_p = ext.to_posit(*dev, w)
    b_p = ext.to_posit(*dev, b)
    m.setWeight(*dev, w_p)
    m.setBias(*dev, b_p)

def fuse_apply_params(ext, dev, conv, bn, out_conv, w_scale=1.0, b_scale=1.0):
    w, b = fuse_bn(conv, bn)
#    w.mul_(w_scale)
#    b.mul_(b_scale)

    apply_params(ext, dev, w, b, out_conv)

def fuse_resnet_params(ext, dev, m_in, m_out, fc_mul=1.0):
    fuse_apply_params(ext, dev, m_in.conv1, m_in.bn1, m_out.conv1)

    for seq_in, seq_out in zip([m_in.layer1, m_in.layer2, m_in.layer3, m_in.layer4],
                               [m_out.layer1, m_out.layer2, m_out.layer3, m_out.layer4]):
        for bb_in, bb_out in zip(seq_in, seq_out):
            fuse_apply_params(ext, dev, bb_in.conv1, bb_in.bn1, bb_out.conv1)
            fuse_apply_params(ext, dev, bb_in.conv2, bb_in.bn2, bb_out.conv2)

            if (hasattr(bb_in, 'conv3')):
                fuse_apply_params(ext, dev, bb_in.conv3, bb_in.bn3, bb_out.conv3)
            if (bb_in.downsample):
                fuse_apply_params(ext, dev, bb_in.downsample[0],
                                  bb_in.downsample[1],
                                  bb_out.downsample)

    apply_params(ext, dev,
                 m_in.fc.weight.mul(fc_mul),
                 m_in.fc.bias.mul(fc_mul), m_out.fc)

def gather_act(ext, dev, model):
    def append_act(ext, dev, acts, m):
        acts.append(m.getInput())

    acts = []
    for m in [model.conv1, model.relu, model.maxpool]:
        append_act(ext, dev, acts, m)

    for l in [model.layer1, model.layer2, model.layer3, model.layer4]:
        for s in l:
            for m in [s.conv1, s.relu1, s.conv2, s.relu2]:
                append_act(ext, dev, acts, m)
            if (hasattr(s, 'conv3')):
                append_act(ext, act, acts, s.conv3)
            if (s.downsample):
                append_act(ext, act, acts, s.downsample)
            append_act(ext, act, acts, s.add)

    for m in [model.avgpool, model.fc]:
        append_act(ext, dev, acts, m)

    return acts
