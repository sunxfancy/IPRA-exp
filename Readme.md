IPRA Experiments
=========================


## Clone the repo

This project contains submodules, please run:

```sh
git clone --recursive git@github.com:sunxfancy/IPRA-exp.git
```

or after clone, run:
```sh
git submodule update --init --recursive
```

## Install tools

Required tools:
SingularityCE - installing it following the documentation: [https://docs.sylabs.io/guides/3.11/user-guide/](https://docs.sylabs.io/guides/3.11/user-guide/)

## Build Project
1. run `make singularity/image` to build the image, you may need the root privileges
2. run `./make` to build the clang compiler, autofdo and some small tools
3. run `./make benchmarks/${bench}/${target}` can build the specific target of one of the benchmarks
4. run `./make benchmarks/${bench}/${target}.bench` can run the bench for this target
5. run `./make benchmarks/${bench}/${target}.regprof3` can run the register and spill code profiling for this target

E.g. Run the clang benchmark register and spill code profiling for thin-lto build with all features eanbled (Threshold for hot function = 3, Callsite Cold Ratio = 20):

```
./make benchmarks/clang/pgo-full-bfdoipra6.3-20.regprof3
```

## Quickly Reproducing the Benchmarks

Run `./make benchmarks` to run all benchmarks

## Benchmark Output

There are two folder will be generated: `build` and `tmp`. In the `build/benchmarks` folder, you will see the benchmarks result:
1. `<target>.bench` the result of `perf stat` after running 5 times
2. `<target>.regprof3` the result of push pop countings and spill code size

You can use the python script in `benchmarks/report.ipynb` to view those data quickly, by running `./make jupyter` to start a jupyter session.


## How to use the compiler

After build the compiler, there is a folder `install/llvm` contains the clang compiler. The specific compiler flags:
1. `-mllvm -fdo-ipra` to enable FDOIPRA
2. `-mllvm -fdoipra-both-hot=false` to control applying optimzaiton for function which entry is hot or having hot loop in its body. When it is `false`, means only apply to function which entry is hot. (Default: true)
3. `-fdoipra-cc=1` to enable optimaztion for Cold Callsite and Cold Callee (Default: true)
4. `-fdoipra-ch=1` to enable optimaztion for Cold Callsite and Hot Callee  (Default: false)
5. `-fdoipra-hc=1` to enable optimaztion for Hot Callsite and Cold Callee  (Default: false)
6. `-fdoipra-ccr=10` to setup the Callsite Cold Ratio  (Default: 10.0)

There should be a 3-steps build:
1. Build the pgo-full version: instrumentation using `-fprofile-generate`, profiling and then rebuild the PGO with FullLTO
2. Using perf to collect the sampling data and convert the profile using `hot-list-creator` to generate a hot function list.
3. Build the final binary 

You can checkout the small example here: [how-to-use/build.mk](https://github.com/sunxfancy/IPRA-exp/blob/main/example/how-to-use/build.mk)

## Available Benchmarks

1. clang
2. gcc
3. mysql
4. leveldb

## Available Targets

1. `pgo-full`        PGO + FullLTO build, the baseline
2. `pgo-full-ipra`   PGO + IPRA + FullLTO build, the existing solution

*the following 3 are applying optimazition for function which entry is hot*:

3. `pgo-full-fdoipra`  PGO + FullLTO with ColdCallSite-ColdCallee using no_caller_saved_registers attributes
4. `pgo-full-fdoipra2`  PGO + FullLTO with ColdCallSite-ColdCallee and ColdCallsite-HotCallee using no_caller_saved_registers attributes and a proxy call
5. `pgo-full-fdoipra3`  PGO + FullLTO with ColdCallSite-ColdCallee, ColdCallsite-HotCallee and indirect calls using no_caller_saved_registers attributes and a proxy call

*the following 3 are applying optimzaiton for function which entry is hot or having hot loop in its body*:

6. `pgo-full-bfdoipra`  PGO + FullLTO with ColdCallSite-ColdCallee using no_caller_saved_registers attributes
7. `pgo-full-bfdoipra2`  PGO + FullLTO with ColdCallSite-ColdCallee and ColdCallsite-HotCallee using no_caller_saved_registers attributes and a proxy call
8. `pgo-full-bfdoipra3`  PGO + FullLTO with ColdCallSite-ColdCallee, ColdCallsite-HotCallee and indirect calls using no_caller_saved_registers attributes and a proxy call

*The following 6 are applying no_callee_saved_registers to cold caller and hot callee functions, corresponding to the previous 6 items*:

9. `pgo-full-fdoipra4`  PGO + FullLTO with ColdCallSite-ColdCallee using no_caller_saved_registers attributes
10. `pgo-full-fdoipra5`  PGO + FullLTO with ColdCallSite-ColdCallee and ColdCallsite-HotCallee using no_caller_saved_registers attributes and a proxy call
11. `pgo-full-fdoipra6`  PGO + FullLTO with ColdCallSite-ColdCallee, ColdCallsite-HotCallee and indirect calls using no_caller_saved_registers attributes and a proxy call
12. `pgo-full-bfdoipra4`  PGO + FullLTO with ColdCallSite-ColdCallee using no_caller_saved_registers attributes
13. `pgo-full-bfdoipra5`  PGO + FullLTO with ColdCallSite-ColdCallee and ColdCallsite-HotCallee using no_caller_saved_registers attributes and a proxy call
14. `pgo-full-bfdoipra6`  PGO + FullLTO with ColdCallSite-ColdCallee, ColdCallsite-HotCallee and indirect calls using no_caller_saved_registers attributes and a proxy call

## Target variants

There are variants for each target, used to configure the threshold for each target. Format: `pgo-full-fdoipra.A-B`

Number A: The threshold for how many times could be considered as a hot function in sampling data. e.g 3 means if a function has been seen 3 times in the perf sampling data, the system will consider it as a hot function.
Number B: Callsite Cold Ratio, in the PGO profiling data, which callsite should be considered as a cold callsite. e.g. 10 means if the hit frequence at entry of the caller function has 10 times larger than the hit frequence at callsite, this is a cold callsite.

Available A: 1 3 5 10
Availabel B: 10 20


# How to optimize Google's binary

## 1. Apply patches to LLVM 16 and build autofdo

[IPRA-exp/fdoipra.patch at main · sunxfancy/IPRA-exp (github.com)](https://github.com/sunxfancy/IPRA-exp/blob/main/fdoipra.patch)

[IPRA-exp/fix.patch at main · sunxfancy/IPRA-exp (github.com)](https://github.com/sunxfancy/IPRA-exp/blob/main/fix.patch)

Build LLVM and Clang

Build modified version of autofdo (dev branch)  [sunxfancy/autofdo at dev (github.com)](https://github.com/sunxfancy/autofdo/tree/dev)

## 2. Build PGO LTO version of your binary

a. Build instrumented version:

-fprofile-generate=<output_path>

b. Run tests and profile merge:

… // run tests

cd <output_path> && llvm-profdata merge -output=instrumented.profdata *

c. Build optimized version:

-flto=thin -fprofile-use=instrumented.profdata  -Wl,--lto-basic-block-sections=labels  -Wl,--build-id 

Other flags to avoid bugs:

-fno-optimize-sibling-calls  -Wl,-mllvm -Wl,-fast-isel=false -Wl,-Bsymbolic-non-weak-functions

Other flags for best performance:

-fsplit-machine-functions

## 3. Collect Perf Data using your PGO LTO build and build hot list

a. Run PGO Optimized Version with perf record

perf record -e cycles:u -j any -o  samples

b. Generate hotlist

```makefile
hot_list_creator
    --binary="<PGO VERSION>" \
		--profile="<Sample>" \
		--output="hot_list" \
		--detail="detail" \  # for debugging
		--hot_threshold=3  # 3 counts in samples will mark the function hot
```

## 4. Build the final Binary

The last step is to build the final binary using two different groups o information:

a. The PGO profile data

b. The hot list

Build FDOIPRA

-Wl,-mllvm -fdo-ipra -Wl,-fdoipra-new-impl  -Wl,-mllvm -Wl,-fdoipra-both-hot=false  -Wl,-mllvm -Wl,-fdoipra-ch=1 -Wl,-mllvm -Wl,-fdoipra-hc=1   -Wl,-mllvm -Wl,-fdoipra-use-caller-reg=1

| fdo-ipra | Enable FDOIPRA pass |
| --- | --- |
| fdoipra-new-impl   | There are two implementation, the new one supports ThinLTO which should be good to use.  |
| fdoipra-both-hot | False: only function hot in entry will be considered. True: function hot in entry and body will both be considered as candidates for optimization. |
| fdoipra-ch | Enable optimization for cold-callsite-hot-callee |
| fdoipra-hc | Enable optimization for hot-callsite-cold-callee |
| fdoipra-use-caller-reg | Enable optimization for transferring callee saved registers to caller saved. |


