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
import torch.nn as nn
import torch.utils.data
import torch.utils.data.distributed
import torchvision.transforms as transforms
import torchvision.datasets as datasets
import torchvision.models as models

class AverageMeter(object):
    """Computes and stores the average and current value"""
    def __init__(self):
        self.reset()

    def reset(self):
        self.val = 0
        self.avg = 0
        self.sum = 0
        self.count = 0

    def update(self, val, n=1):
        self.val = val
        self.sum += val * n
        self.count += n
        self.avg = self.sum / self.count

def accuracy(output, target, topk=(1,)):
    """Computes the precision@k for the specified values of k"""
    maxk = max(topk)
    batch_size = target.size(0)

    _, pred = output.topk(maxk, 1, True, True)
    pred = pred.t()
    correct = pred.eq(target.view(1, -1).expand_as(pred))

    res = []
    for k in topk:
        correct_k = correct[:k].view(-1).float().sum(0, keepdim=True)
        res.append(correct_k.mul_(100.0 / batch_size))
    return res

def validate(val_loader, limit, fpga_h=None, reference_model=None):
    batch_time = AverageMeter()
    losses = AverageMeter()
    top1 = AverageMeter()
    top5 = AverageMeter()
    end = time.time()

    ref_batch_time = AverageMeter()
    ref_losses = AverageMeter()
    ref_top1 = AverageMeter()
    ref_top5 = AverageMeter()
    ref_end = time.time()

    limit = limit or -1

    criterion = nn.CrossEntropyLoss()

    count = 0
    for i, (input, target) in enumerate(val_loader):
        count = count + 1
        if (count > limit and not (limit == -1)):
            break

        if (fpga_h):
            end = time.time()
#            fpga_h.forward_p(input)

        if (reference_model):
            ref_end = time.time()
            ref_output = reference_model.forward(input)
#            ref_target_var = torch.autograd.Variable(target, volatile=True)
            ref_target_var = torch.autograd.Variable(target)
            ref_loss = criterion(ref_output, ref_target_var)

            prec1, prec5 = accuracy(ref_output, target, topk=(1, 5))
            ref_losses.update(ref_loss.item(), input.size(0))
            ref_top1.update(prec1[0], input.size(0))
            ref_top5.update(prec5[0], input.size(0))

            # measure elapsed time
            ref_batch_time.update(time.time() - ref_end)

            print('CPU float32:       [{0}/{1}]\t'
                  'Time {batch_time.val:.3f} ({batch_time.avg:.3f})\t'
                  'Loss {loss.val:.4f} ({loss.avg:.4f})\t'
                  'Prec@1 {top1.val:.3f} ({top1.avg:.3f})\t'
                  'Prec@5 {top5.val:.3f} ({top5.avg:.3f})'.format(
                      (i + 1) * val_loader.batch_size,
                      len(val_loader) * val_loader.batch_size,
                      batch_time=ref_batch_time, loss=ref_losses,
                      top1=ref_top1, top5=ref_top5))
            sys.stdout.flush()

        if (fpga_h):

#            output = fpga_h.forward_f()
            output = fpga_h.forward(input)
#            target_var = torch.autograd.Variable(target, volatile=True)
            target_var = torch.autograd.Variable(target)
            loss = criterion(output, target_var)

            prec1, prec5 = accuracy(output, target, topk=(1, 5))
            losses.update(loss.item(), input.size(0))
            top1.update(prec1[0], input.size(0))
            top5.update(prec5[0], input.size(0))

            # measure elapsed time
            batch_time.update(time.time() - end)

            print('FPGA: [{0}/{1}]\t'
                  'Time {batch_time.val:.3f} ({batch_time.avg:.3f})\t'
                  'Loss {loss.val:.4f} ({loss.avg:.4f})\t'
                  'Prec@1 {top1.val:.3f} ({top1.avg:.3f})\t'
                  'Prec@5 {top5.val:.3f} ({top5.avg:.3f})'.format(
                      (i + 1) * val_loader.batch_size,
                      len(val_loader) * val_loader.batch_size,
                      batch_time=batch_time, loss=losses,
                      top1=top1, top5=top5))
            sys.stdout.flush()

#    return top1.avg.item(), top5.avg.item()

def make_loader(batch_size, random=False, seed=1):
    valdir = '/home/jhj/imagenet/data/local/packages/ai-group.imagenet-full-size/prod/imagenet_full_size/val'

    normalize = transforms.Normalize(mean=[0.485, 0.456, 0.406],
                                     std=[0.229, 0.224, 0.225])

    dataset = datasets.ImageFolder(valdir, transforms.Compose([
        transforms.Resize(256),
        transforms.CenterCrop(224),
        transforms.ToTensor(),
        normalize,
    ]))

    sampler = None
    if random:
        sampler = torch.utils.data.RandomSampler(dataset)
        torch.manual_seed(seed)

    return torch.utils.data.DataLoader(
        dataset,
        sampler=sampler,
        batch_size=batch_size,
        shuffle=False,
        num_workers=0)

def sample_loader(loader):
    for (input, target) in loader:
        return input, target
