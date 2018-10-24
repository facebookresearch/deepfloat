# Copyright (c) Facebook, Inc. and its affiliates. All Rights Reserved.
# All rights reserved.
#
# This source code is licensed under the license found in the
# LICENSE file in the root directory of this source tree.
import FixedPoint
import math
import argparse
import io

parser = argparse.ArgumentParser(
    description='Generates pow2 and log2 tables for log-linear conversions',
    epilog='', formatter_class=argparse.RawTextHelpFormatter
)
group = parser.add_argument_group('arguments')

def str2bool(v):
    if v.lower() in ('yes', 'true', 't', 'y', '1'):
        return True
    elif v.lower() in ('no', 'false', 'f', 'n', '0'):
        return False
    else:
        raise argparse.ArgumentTypeError('Boolean value expected.')

parser.add_argument("--mem", type=str2bool, nargs='?',
                    const=True, default=False,
                    help="generate memory tables")

group.add_argument('--bits_in', '-bi', metavar='<bits in>', type=int,
                   nargs=1, required=True,
                   help='bits for input')

group.add_argument('--bits_out', '-bo', metavar='<bits out>', type=int,
                   nargs=1, required=True,
                   help='bits for output')

parser.add_argument('--log', type=str2bool, nargs='?',
                    const=True, default=False,
                    help="generate log2 table only")

parser.add_argument('--pow', type=str2bool, nargs='?',
                    const=True, default=False,
                    help="generate pow2 table only")

parser.add_argument('--pow_delta', type=str2bool, nargs='?',
                    const=True, default=False,
                    help="generate pow2 delta table only")

parser.add_argument('--log_delta', type=str2bool, nargs='?',
                    const=True, default=False,
                    help="generate log2 delta table only")

parser.add_argument('--str', type=str2bool, nargs='?',
                    const=True, default=False,
                    help="print to stdout only")

def get_r2ne(x, bits):
    str = x.toBinaryString()
    assert str[1] == '.'

    keep_bit = str[2+bits-1] == '1'
    guard_bit = str[2+bits] == '1'
    round_bit = str[2+bits+1] == '1'
    sticky_bits = str[2+bits+2:].find('1') != -1
    round_down = (not guard_bit) or ((not keep_bit) and guard_bit and (not round_bit) and (not sticky_bits))
    return not round_down

def get_fraction(x, bits=-1):
    str = x.toBinaryString()
    # Find the fixed point
    idx = str.find('.')

    if bits == -1:
        return str[idx+1:]
    else:
        return str[idx+1:idx+1+bits]


args = parser.parse_args()

overlaps = {}

#
# Non-delta
#

def get_pow2_expansion(i, in_bits, out_bits, enable_rounding=True):
    prec_bits = out_bits * 4
    fam20 = FixedPoint.FXfamily(prec_bits)

    x = (FixedPoint.FXnum(i, fam20) / (2 ** in_bits))
    orig_x = x
    orig_str = x.toBinaryString()[2:2+in_bits]
    x = pow(2, x)
    pow2_str = x.toBinaryString()

    keep_bit = pow2_str[2+out_bits-1] == '1'
    guard_bit = pow2_str[2+out_bits] == '1'
    round_bit = pow2_str[2+out_bits+1] == '1'
    sticky_bits = pow2_str[2+out_bits+2:].find('1') != -1

    round_down = (not guard_bit) or ((not keep_bit) and guard_bit and (not round_bit) and (not sticky_bits))

    if (not round_down and enable_rounding):
        add = FixedPoint.FXnum(1, fam20) >> out_bits
        x = x + add

    before_round = pow2_str[2:2+out_bits]
    after_round = x.toBinaryString()[2:2+out_bits]

    is_overlap = False

    if after_round in overlaps:
        is_overlap = True
    else:
        overlaps[after_round] = True

    # can also formulate as what to subtract, excepting 0
#    print(orig_str, (x - (1 + orig_x)).toBinaryString()[2+2:4 + out_bits - 2])

    return orig_str, before_round, after_round, not round_down, is_overlap

def get_log2_expansion(i, in_bits, out_bits, enable_rounding=True):
    prec_bits = out_bits * 4
    fam20 = FixedPoint.FXfamily(prec_bits)

    x = (FixedPoint.FXnum(i, fam20) / (2 ** in_bits))
    orig_str = x.toBinaryString()[2:2+in_bits]
    x = (x + 1).log() / math.log(2)
    pow2_str = x.toBinaryString()

    keep_bit = pow2_str[2+out_bits-1] == '1'
    guard_bit = pow2_str[2+out_bits] == '1'
    round_bit = pow2_str[2+out_bits+1] == '1'
    sticky_bits = pow2_str[2+out_bits+2:].find('1') != -1

    round_down = (not guard_bit) or ((not keep_bit) and guard_bit and (not round_bit) and (not sticky_bits))

    if (not round_down and enable_rounding):
        add = FixedPoint.FXnum(1, fam20) >> out_bits
        x = x + add

    before_round = pow2_str[2:2+out_bits]
    after_round = x.toBinaryString()[2:2+out_bits]

    is_overlap = False

    if after_round in overlaps:
        is_overlap = True
    else:
        overlaps[after_round] = True

    return orig_str, before_round, after_round, not round_down, is_overlap

#
# delta
#

def get_pow2_delta_expansion(i, in_bits, out_bits, enable_rounding=True):
    prec_bits = out_bits * 4
    fam20 = FixedPoint.FXfamily(prec_bits)

    x = (FixedPoint.FXnum(i, fam20) / (2 ** in_bits))
    orig_x = x
    orig_str = x.toBinaryString()[2:2+in_bits]
    pow2_x = pow(2, x)
    pow2_str = x.toBinaryString()

    round_up = get_r2ne(pow2_x, out_bits)

    pow2_round_x = pow2_x
    if (round_up and enable_rounding):
        add = FixedPoint.FXnum(1, fam20) >> out_bits
        pow2_round_x = pow2_x + add

    # As an out_bits-sized fixed point number
    fam_out = FixedPoint.FXfamily(out_bits)
    y = FixedPoint.FXnum(pow2_round_x, fam_out)
    cur = FixedPoint.FXnum(i, fam_out) / (2 ** in_bits)

    # This is what we are encoding, all values except for 0 are negative
    delta_y = y - cur
    delta_y = delta_y << 3

    delta_y_truncated = FixedPoint.FXnum(delta_y, FixedPoint.FXfamily(out_bits-3))
    delta_y_truncated = delta_y_truncated - 7

#    print(y.toBinaryString(), cur.toBinaryString(), (y - cur).toBinaryString(), get_fraction(delta_y_truncated))

    # Now, see if we can recover y from delta_y_truncated
    recover_y = FixedPoint.FXnum(delta_y_truncated, fam_out)
    recover_y = recover_y + 7
    recover_y = recover_y >> 3

    recover_val = cur + recover_y
    assert recover_val == y

    before_round = get_fraction(pow2_x, out_bits)
    after_round = get_fraction(pow2_round_x, out_bits)

    return orig_str, after_round, get_fraction(delta_y_truncated)


def get_log2_delta_expansion(i, in_bits, out_bits, enable_rounding=True):
    prec_bits = out_bits * 4
    fam20 = FixedPoint.FXfamily(prec_bits)

    x = (FixedPoint.FXnum(i, fam20) / (2 ** in_bits))
    orig_x = x
    orig_str = x.toBinaryString()[2:2+in_bits]
    log2_x = (x + 1).log() / math.log(2)
    log2_str = x.toBinaryString()

    round_up = get_r2ne(log2_x, out_bits)

    log2_round_x = log2_x
    if (round_up and enable_rounding):
        add = FixedPoint.FXnum(1, fam20) >> out_bits
        log2_round_x = log2_x + add

    # As an out_bits-sized fixed point number
    fam_out = FixedPoint.FXfamily(out_bits)
    y = FixedPoint.FXnum(log2_round_x, fam_out)
    cur = FixedPoint.FXnum(i, fam_out) / (2 ** in_bits)

    # This is what we are encoding, all values except for 0 are negative
    delta_y = y - cur
    delta_y = delta_y << 3
#    print('cur {} round {} delta {}'.format(cur.toBinaryString(), y.toBinaryString(), delta_y.toBinaryString()))

    delta_y_truncated = FixedPoint.FXnum(delta_y, FixedPoint.FXfamily(out_bits-3))
    delta_y_truncated = delta_y_truncated - 7

    # Now, see if we can recover y from delta_y_truncated
    recover_y = FixedPoint.FXnum(delta_y_truncated, fam_out)
    recover_y = recover_y + 7
    recover_y = recover_y >> 3

    recover_val = cur + recover_y
#    print('here', recover_val.toBinaryString())
    assert recover_val == y

    before_round = get_fraction(log2_x, out_bits)
    after_round = get_fraction(log2_round_x, out_bits)

    return orig_str, after_round, get_fraction(delta_y_truncated)





#
# module generation
#


def gen_pow2(file, gen_mem, in_bits, out_bits):
    if (not gen_mem):
        header = """
module Pow2LUT_{}x{}
  (input [{}:0] in,
   output logic [{}:0] out);

  always_comb begin
    case (in)
""".format(in_bits, out_bits, in_bits-1, out_bits-1)

        file.write(header)

    had_overlap = False

    for i in range(2 ** in_bits):
        in_fixed, before_fixed, out_fixed, r, is_overlap = get_pow2_expansion(i, in_bits, out_bits)

        if (gen_mem):
            file.write(out_fixed)
            file.write('\n')
        else:
            overlap_str = ''
            if (is_overlap and r):
                had_overlap = True
                overlap_str = ' // overlap + round'
            elif (is_overlap):
                had_overlap = True
                overlap_str = ' // overlap'
            elif (r):
                had_overlap = True
                overlap_str = ' // round'

            file.write('      {}\'b{}: out = {}\'b{};{}\n'.format(
                in_bits,
                in_fixed,
                out_bits,
                out_fixed,
                overlap_str))

    if (not gen_mem):
        file.write('      default: out = {}\'b{};\n'.format(out_bits, 'x' * out_bits))
        file.write('    endcase\n')
        file.write('  end\n')
        file.write('endmodule\n')

def gen_log2(file, gen_mem, in_bits, out_bits):
    if (not gen_mem):
        header = """
module Log2LUT_{}x{}
  (input [{}:0] in,
   output logic [{}:0] out);

  always_comb begin
    case (in)
""".format(in_bits, out_bits, in_bits-1, out_bits)

        file.write(header)

    had_overlap = False

    for i in range(2 ** in_bits):
        in_fixed, before_fixed, out_fixed, r, is_overlap = get_log2_expansion(i, in_bits, out_bits, True)

        if (i < 2 ** (in_bits - 1) or out_fixed != ('0' * out_bits)):
            r = False

        if (gen_mem):
            file.write('{}{}\n'.format(int(r), out_fixed))
        else:
            overlap_str = ''
            if (is_overlap and r):
                had_overlap = True
                overlap_str = ' // overlap + round'
            elif (is_overlap):
                had_overlap = True
                overlap_str = ' // overlap'
            elif (r):
                had_overlap = True
                overlap_str = ' // round'

            file.write('      {}\'b{}: out = {}\'b{}{};{}\n'.format(
                in_bits,
                in_fixed,
                out_bits + 1,
                int(r),
                out_fixed,
                overlap_str))

    if (not gen_mem):
        file.write('      default: out = {}\'b{};\n'.format(out_bits + 1, 'x' * (out_bits + 1)))
        file.write('    endcase\n')
        file.write('  end\n')
        file.write('endmodule\n')

def gen_pow2_delta(file, gen_mem, in_bits, out_bits):
    if (not gen_mem):
        header = """
module Pow2DeltaLUT_{}x{}
  (input [{}:0] in,
   output logic [{}:0] out);

  always_comb begin
    case (in)
""".format(in_bits, out_bits, in_bits-1, out_bits-4)

        file.write(header)

    for i in range(2 ** in_bits):
        in_fixed, out_fixed, delta = get_pow2_delta_expansion(i, in_bits, out_bits)

        if (gen_mem):
            file.write(delta)
            file.write('\n')
        else:
            file.write('      {}\'b{}: out = {}\'b{};\n'.format(
                in_bits,
                in_fixed,
                out_bits-3,
                delta))

    if (not gen_mem):
        file.write('      default: out = {}\'b{};\n'.format(out_bits-3, 'x' * (out_bits-3)))
        file.write('    endcase\n')
        file.write('  end\n')
        file.write('endmodule\n')

def gen_log2_delta(file, gen_mem, in_bits, out_bits):
    if (not gen_mem):
        header = """
module Log2DeltaLUT_{}x{}
  (input [{}:0] in,
   output logic [{}:0] out);

  always_comb begin
    case (in)
""".format(in_bits, out_bits, in_bits-1, out_bits-4)

        file.write(header)

    for i in range(2 ** in_bits):
        in_fixed, out_fixed, delta = get_log2_delta_expansion(i, in_bits, out_bits)

        if (gen_mem):
            file.write(delta)
            file.write('\n')
        else:
            file.write('      {}\'b{}: out = {}\'b{};\n'.format(
                in_bits,
                in_fixed,
                out_bits-3,
                delta))

    if (not gen_mem):
        file.write('      default: out = {}\'b{};\n'.format(out_bits-3, 'x' * (out_bits-3)))
        file.write('    endcase\n')
        file.write('  end\n')
        file.write('endmodule\n')


# def gen_pow2_mem(file, in_bits, out_bits):
#     header = """
# module Pow2Mem_{}x{}
#   (input [{}:0] in,
#    output logic [{}:0] out);

#   logic [{}:0] mem[0:(2**{})-1];

#   initial begin
#     $readmemb("pow2_{}x{}.hex", mem);
#   end

#   always_comb begin
#     out = mem[in];
#   end
# endmodule
#     """.format(in_bits, out_bits, in_bits-1, out_bits-1, out_bits-1, in_bits, in_bits, out_bits)

#     file.write(header)

# def gen_log2_mem(file, in_bits, out_bits):
#     header = """
# module Log2Mem_{}x{}
#   (input [{}:0] in,
#    output logic [{}:0] out);

#   logic [{}:0] mem[0:(2**{})-1];

#   initial begin
#     $readmemb("log2_{}x{}.hex", mem);
#   end

#   always_comb begin
#     out = mem[in];
#   end
# endmodule
#     """.format(in_bits, out_bits, in_bits-1, out_bits, out_bits, in_bits, in_bits, out_bits)

#     file.write(header)

in_bits = args.bits_in[0]
out_bits = args.bits_out[0]

def make_file(name):
    if (args.str):
        return io.StringIO()

    return open(name, 'w')

def close_file(f):
    if (args.str):
        print(f.getvalue())
    else:
        f.close()

if (args.pow):
    f = make_file('Pow2LUT_{}x{}.sv'.format(in_bits, out_bits))
    gen_pow2(f, False, in_bits, out_bits)
    close_file(f)

    # if (args.mem):
    #     f = make_file('Pow2Mem_{}x{}.sv'.format(in_bits, out_bits))
    #     gen_pow2_mem(f, in_bits, out_bits)
    #     close_file(f)

    #     f = make_file('pow2_{}x{}.hex'.format(in_bits, out_bits))
    #     gen_pow2(f, True, in_bits, out_bits)
    #     close_file(f)

if (args.pow_delta):
    f = make_file('Pow2DeltaLUT_{}x{}.sv'.format(in_bits, out_bits))
    gen_pow2_delta(f, False, in_bits, out_bits)
    close_file(f)

if (args.log):
    f = make_file('Log2LUT_{}x{}.sv'.format(in_bits, out_bits))
    gen_log2(f, False, in_bits, out_bits)
    close_file(f)

if (args.log_delta):
    f = make_file('Log2DeltaLUT_{}x{}.sv'.format(in_bits, out_bits))
    gen_log2_delta(f, False, in_bits, out_bits)
    close_file(f)

    # if (args.mem):
    #     f = make_file('Log2Mem_{}x{}.sv'.format(in_bits, out_bits))
    #     gen_log2_mem(f, in_bits, out_bits)
    #     close_file(f)

    #     f = make_file('log2_{}x{}.hex'.format(in_bits, out_bits))
    #     gen_log2(f, True, out_bits, in_bits)
    #     close_file(f)
