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

## install tools

Required tools:
SingularityCE - installing it following the documentation: [https://docs.sylabs.io/guides/3.11/user-guide/](https://docs.sylabs.io/guides/3.11/user-guide/)

## Build Project
1. run `make singularity/image` to build the image, you may need the root privileges
2. run `./make` to build the clang compiler, autofdo and some small tools
3. run `./make benchmarks/${bench}/${target}` can build the specific target of one of the benchmarks
4. run `./make benchmarks/${bench}/${target}.bench` can run the bench for this target
5. run `./make benchmarks/${bench}/${target}.regprof3` can run the register and spill code profiling for this target

## Quickly Reproducing the Benchmarks

Run `./make benchmarks` to run all benchmarks


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




