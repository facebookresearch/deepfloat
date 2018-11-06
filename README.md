This repository contains the SystemVerilog RTL, C++, HLS (Intel FPGA OpenCL to wrap RTL code) and Python needed to reproduce the numerical results in "Rethinking floating point for deep learning" [1].

There are two types of floating point implemented:

- N-bit (N, l, alpha, beta, gamma) log with ELMA [1]
- N-bit (N, s) (linear) posit [2]

with partial implementation of IEEE-style (e, s) floating point (likely quite buggy) and non-posit tapered log.

8-bit (8, 1, 5, 5, 7) log is the format described in "Rethinking floating point for deep learning", shown within to be more energy efficient than int8/32 integer multiply-add at 28 nm and an effective drop-in replacement for IEEE 754 binary32 single precision floating point via round to nearest even for CNN inference on ResNet-50 on ImageNet.

[1] Johnson, J. "[Rethinking floating point for deep learning.](https://arxiv.org/abs/1811.01721)" (2018). https://arxiv.org/abs/1811.01721

[2] Gustafson, J. and Yonemoto, I. "[Beating floating point at its own game: Posit arithmetic.](https://dl.acm.org/citation.cfm?id=3148220)" Supercomputing Frontiers and Innovations 4.2 (2017): 71-86.

# Requirements

You will need:

- a PyTorch CPU installation
- a C++11-compatible compiler to use to generate a [PyTorch C++ extension module](https://pytorch.org/tutorials/advanced/cpp_extension.html)
- the ImageNet ILSVRC12 image validation set
- an Intel OpenCL for FPGA compatible board
- a Quartus Prime Pro installation with the Intel OpenCL for FPGA compiler

`rtl` contains the SystemVerilog modules needed for the design.

`bitstream` contains the OpenCL that wraps the RTL modules.

`cpp` contains host CPU-side code for interacting with the FPGA OpenCL design.

`py` contains the top-level functionality to compile the CPU code and run networks.

# Flow

In `bitstream`, run

`./build_lib.sh <design>`

followed by

`./build_afu.sh <design>` (this will take several hours to synthesize the FPGA design)

where `<design>` is one of `loglib` or `positlib`. The `aoc`/`aocl` tools, Quartus, Quartus license file, OpenCL BSP etc. must be in your path/environment. `loglib` is configured to generate a design with 8-bit (8, 1, 5, 5, 7) log arithmetic, and `positlib` is configured to generate a design with 8-bit (8, 1) posit arithmetic by default.

The `aoc` build seems to require a Python 2.x interpreter in the path, otherwise it will fail.

Update the `aocx_file` in `py/run_fpga_resnet.py` to your choice of design.

Update `valdir` towards the end of `py/validate.py` to point to a Torch dataset loader compatible installation of the ImageNet validation set.

Using a python environment with PyTorch available, in `py` run:

`python run_fpga_resnet.py`

If successful, this will run the complete validation set against the FPGA design. This requires a Python 3.x interpreter.

# RTL comments

The modules used by the OpenCL design reside in `rtl/log/operators` and `rtl/posit/operators`. You can see how they are assembled here.

`rtl/paper_syn` contains the modules used in the paper's 28 nm synthesis results (`Paper*Top.sv` are the top-level modules). `Waves_*.sv` are the testbench programs used to generate switching activity for power analysis output.

You will have to provide your own Synopsys Design Compiler scripts/flow/cell libraries/PDK/etc. for synthesis, as we are not allowed to share details on which 28 nm semiconductor process was used or our Design Compiler synthesis scripts.

# Other comments

The posit encoding implemented herein implements negative values with a sign bit rather than two's complement encoding. It is a TODO to change it, but the cost either way is largely dwarfed by other concerns in my opinion.

The FPGA design itself is not super flexible yet to support different bit widths than 8. `loglib` is restricted to N <= 8 bits at the moment, while `positlib` should be ok for N <= 16 bits, though some of the larger designs may run into FPGA resource issues if synthesized for the FPGA.

# Contributions

This repo currently exists as a proof of concept. Contributions may be considered, but the design is mostly that which is needed to reproduce the results from the paper.

# License

This code is licensed under [CC-BY-NC 4.0](https://creativecommons.org/licenses/by-nc/4.0/).

This code also includes and uses the [Single Python Fixed-Point Module](https://github.com/rwpenney/spfpm) for LUT SystemVerilog log-to-linear and linear-to-log mapping module generation in `rtl/log/luts`, which is licensed by the [Python-2.4.2 license](http://www.python.org/psf/license).
