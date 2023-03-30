
benchmarks: benchmarks/gcc/build benchmarks/leveldb/build  benchmarks/clang/build benchmarks/mysql/build  benchmarks/gcc/regprof3 benchmarks/leveldb/regprof3 benchmarks/clang/regprof3 benchmarks/mysql/regprof3  

# make benchmarks/SPEC/bench

benchmarks-build: benchmarks/clang/build benchmarks/mysql/build benchmarks/gcc/build # benchmarks/SPEC

FDOIPRA_FLAVORS := fdoipra bfdoipra fdoipra2 bfdoipra2 fdoipra3 bfdoipra3 fdoipra4 bfdoipra4 fdoipra5 bfdoipra5 fdoipra6 bfdoipra6
PGO_FULL_FLAVORS := pgo-full $(foreach f,$(FDOIPRA_FLAVORS),pgo-full-$(f)) pgo-full-ipra
PGO_THIN_FLAVORS := pgo-thin $(foreach f,$(FDOIPRA_FLAVORS),pgo-thin-$(f)) pgo-thin-ipra
FLAVORS := $(PGO_FULL_FLAVORS) $(PGO_THIN_FLAVORS)

# -mno-sse -mno-avx
COMPILER_FLAGS:=-fuse-ld=lld -fbasic-block-sections=labels -Qunused-arguments -funique-internal-linkage-names -fno-optimize-sibling-calls -mllvm -fast-isel=false -fsplit-machine-functions
LINKER_FLAGS:=-fuse-ld=lld -static-libgcc -static-libstdc++  -Wl,--lto-basic-block-sections=labels -Wl,-z,keep-text-section-prefix -Wl,--build-id -fno-optimize-sibling-calls -Wl,-mllvm -Wl,-fast-isel=false -fsplit-machine-functions -Wl,-Bsymbolic-non-weak-functions

COMPILER_FLAGS_IPRA:= -mllvm -enable-ipra
LINKER_FLAGS_IPRA:= -Wl,-mllvm -Wl,-enable-ipra

COMPILER_FLAGS_FDOIPRA:= -mllvm -fdo-ipra -mllvm -fdoipra-both-hot=false  -mllvm -disable-thinlto-funcattrs=false -mllvm -fdoipra-new-impl
LINKER_FLAGS_FDOIPRA:= -Wl,-mllvm -Wl,-fdo-ipra -Wl,-mllvm -Wl,-fdoipra-both-hot=false -Wl,-mllvm -Wl,-disable-thinlto-funcattrs=false -Wl,-mllvm -Wl,-fdoipra-new-impl

COMPILER_FLAGS_BFDOIPRA:= -mllvm -fdo-ipra 
LINKER_FLAGS_BFDOIPRA:= -Wl,-mllvm -Wl,-fdo-ipra

COMPILER_FLAGS_CH:= -mllvm -fdoipra-ch=1
LINKER_FLAGS_CH:= -Wl,-mllvm -Wl,-fdoipra-ch=1

COMPILER_FLAGS_HC:= -mllvm -fdoipra-hc=1
LINKER_FLAGS_HC:= -Wl,-mllvm -Wl,-fdoipra-hc=1

COMPILER_FLAGS_CALLER:= -mllvm -fdoipra-use-caller-reg=1
LINKER_FLAGS_CALLER:= -Wl,-mllvm -Wl,-fdoipra-use-caller-reg=1

COMPILER_FLAGS_FDOIPRA2:= $(COMPILER_FLAGS_FDOIPRA) $(COMPILER_FLAGS_CH)
LINKER_FLAGS_FDOIPRA2:= $(LINKER_FLAGS_FDOIPRA) $(LINKER_FLAGS_CH)

COMPILER_FLAGS_BFDOIPRA2:=  $(COMPILER_FLAGS_BFDOIPRA) $(COMPILER_FLAGS_CH)
LINKER_FLAGS_BFDOIPRA2:= $(LINKER_FLAGS_BFDOIPRA) $(LINKER_FLAGS_CH)

COMPILER_FLAGS_FDOIPRA3:= $(COMPILER_FLAGS_FDOIPRA2) $(COMPILER_FLAGS_HC)
LINKER_FLAGS_FDOIPRA3:= $(LINKER_FLAGS_FDOIPRA2) $(LINKER_FLAGS_HC)

COMPILER_FLAGS_BFDOIPRA3:=  $(COMPILER_FLAGS_BFDOIPRA2) $(COMPILER_FLAGS_HC)
LINKER_FLAGS_BFDOIPRA3:= $(LINKER_FLAGS_BFDOIPRA2) $(LINKER_FLAGS_HC)

COMPILER_FLAGS_FDOIPRA4:= $(COMPILER_FLAGS_FDOIPRA) $(COMPILER_FLAGS_CALLER)
LINKER_FLAGS_FDOIPRA4:= $(LINKER_FLAGS_FDOIPRA) $(LINKER_FLAGS_CALLER)

COMPILER_FLAGS_BFDOIPRA4:=  $(COMPILER_FLAGS_BFDOIPRA) $(COMPILER_FLAGS_CALLER)
LINKER_FLAGS_BFDOIPRA4:= $(LINKER_FLAGS_BFDOIPRA) $(LINKER_FLAGS_CALLER)

COMPILER_FLAGS_FDOIPRA5:= $(COMPILER_FLAGS_FDOIPRA2) $(COMPILER_FLAGS_CALLER)
LINKER_FLAGS_FDOIPRA5:= $(LINKER_FLAGS_FDOIPRA2) $(LINKER_FLAGS_CALLER)

COMPILER_FLAGS_BFDOIPRA5:=  $(COMPILER_FLAGS_BFDOIPRA2) $(COMPILER_FLAGS_CALLER)
LINKER_FLAGS_BFDOIPRA5:= $(LINKER_FLAGS_BFDOIPRA2) $(LINKER_FLAGS_CALLER)

COMPILER_FLAGS_FDOIPRA6:= $(COMPILER_FLAGS_FDOIPRA3) $(COMPILER_FLAGS_CALLER)
LINKER_FLAGS_FDOIPRA6:= $(LINKER_FLAGS_FDOIPRA3) $(LINKER_FLAGS_CALLER)

COMPILER_FLAGS_BFDOIPRA6:=  $(COMPILER_FLAGS_BFDOIPRA3) $(COMPILER_FLAGS_CALLER)
LINKER_FLAGS_BFDOIPRA6:= $(LINKER_FLAGS_BFDOIPRA3) $(LINKER_FLAGS_CALLER)


PERF_EVENTS:= -e instructions,cycles,L1-icache-misses,iTLB-misses,L1-dcache-loads,L1-dcache-load-misses,dTLB-load-misses,L1-dcache-stores,L1-dcache-store-misses,dTLB-store-misses,branches,branch-misses,page-faults,context-switches,cpu-migrations
CONFIG:=$(PWD)/benchmarks/cfg

export

SUBDIRS := $(patsubst %/build.mk,%,$(wildcard benchmarks/*/build.mk))

.PHONY: $(SUBDIRS)

$(SUBDIRS):
	mkdir -p $(OUTPUT_PATH)/$@
	$(MAKE) -C $(OUTPUT_PATH)/$@ -f $(PWD)/$@/build.mk 

benchmarks/%: 
	mkdir -p $(OUTPUT_PATH)/$(dir $@)
	$(MAKE) -C $(OUTPUT_PATH)/$(dir $@) -f $(PWD)/$(dir $@)build.mk $(notdir $@) 

COMPARE_BASE_DIR:=$(BUILD_PATH)/clang/bench.dir
COMPARE_BIN_DIR:=$(OUTPUT_PATH)/benchmarks/clang
COMPARE_A:=pgo-full-fdoipra3/bin/clang-14
COMPARE_B:=pgo-full-fdoipra6/bin/clang-14
COMPARE_ARGS:="-cc1" "-triple" "x86_64-unknown-linux-gnu" "-emit-obj" "--mrelax-relocations" "-disable-free" "-clear-ast-before-backend" "-disable-llvm-verifier" "-discard-value-names" "-main-file-name" "ItaniumDemangle.cpp" "-mrelocation-model" "pic" "-pic-level" "2" "-mframe-pointer=none" "-fmath-errno" "-ffp-contract=on" "-fno-rounding-math" "-mconstructor-aliases" "-funwind-tables=2" "-target-cpu" "x86-64" "-tune-cpu" "generic" "-mllvm" "-treat-scalable-fixed-error-as-warning" "-debug-info-kind=constructor" "-dwarf-version=5" "-debugger-tuning=gdb" "-ffunction-sections" "-fdata-sections" "-fcoverage-compilation-dir=/home/riple/IPRA-exp/tmp/clang/bench.dir" "-resource-dir" "/home/riple/IPRA-exp/tmp/clang/install.dir/lib/clang/14.0.6" "-dependency-file" "lib/Demangle/CMakeFiles/LLVMDemangle.dir/ItaniumDemangle.cpp.o.d" "-MT" "lib/Demangle/CMakeFiles/LLVMDemangle.dir/ItaniumDemangle.cpp.o" "-sys-header-deps" "-D" "GTEST_HAS_RTTI=0" "-D" "_GNU_SOURCE" "-D" "__STDC_CONSTANT_MACROS" "-D" "__STDC_FORMAT_MACROS" "-D" "__STDC_LIMIT_MACROS" "-I" "/home/riple/IPRA-exp/tmp/clang/bench.dir/lib/Demangle" "-I" "/home/riple/IPRA-exp/tmp/clang/llvm-project-llvmorg-14.0.6/llvm/lib/Demangle" "-I" "/home/riple/IPRA-exp/tmp/clang/bench.dir/include" "-I" "/home/riple/IPRA-exp/tmp/clang/llvm-project-llvmorg-14.0.6/llvm/include" "-D" "NDEBUG" "-internal-isystem" "/usr/lib/gcc/x86_64-linux-gnu/11/../../../../include/c++/11" "-internal-isystem" "/usr/lib/gcc/x86_64-linux-gnu/11/../../../../include/x86_64-linux-gnu/c++/11" "-internal-isystem" "/usr/lib/gcc/x86_64-linux-gnu/11/../../../../include/c++/11/backward" "-internal-isystem" "/home/riple/IPRA-exp/tmp/clang/install.dir/lib/clang/14.0.6/include" "-internal-isystem" "/usr/local/include" "-internal-isystem" "/usr/lib/gcc/x86_64-linux-gnu/11/../../../../x86_64-linux-gnu/include" "-internal-externc-isystem" "/usr/include/x86_64-linux-gnu" "-internal-externc-isystem" "/include" "-internal-externc-isystem" "/usr/include" "-O2" "-Werror=date-time" "-Werror=unguarded-availability-new" "-Wall" "-Wextra" "-Wno-unused-parameter" "-Wwrite-strings" "-Wcast-qual" "-Wmissing-field-initializers" "-Wno-long-long" "-Wc++98-compat-extra-semi" "-Wimplicit-fallthrough" "-Wcovered-switch-default" "-Wno-noexcept-type" "-Wnon-virtual-dtor" "-Wdelete-non-virtual-dtor" "-Wsuggest-override" "-Wstring-conversion" "-Wmisleading-indentation" "-pedantic" "-std=c++14" "-fdeprecated-macro" "-fdebug-compilation-dir=/home/riple/IPRA-exp/tmp/clang/bench.dir" "-ferror-limit" "19" "-fvisibility-inlines-hidden" "-fno-rtti" "-fgnuc-version=4.2.1" "-fcolor-diagnostics" "-vectorize-loops" "-vectorize-slp" "-faddrsig" "-D__GCC_HAVE_DWARF2_CFI_ASM=1" "-o" "lib/Demangle/CMakeFiles/LLVMDemangle.dir/ItaniumDemangle.cpp.o" "-x" "c++" "/home/riple/IPRA-exp/tmp/clang/llvm-project-llvmorg-14.0.6/llvm/lib/Demangle/ItaniumDemangle.cpp"

compare: 
	tmux new-session -d /bin/sh -c 'cd $(COMPARE_BASE_DIR) && lldb -- $(COMPARE_BIN_DIR)/$(COMPARE_A) $(COMPARE_ARGS)' \; \
	     split-window -h /bin/sh -c 'cd $(COMPARE_BASE_DIR) && lldb -- $(COMPARE_BIN_DIR)/$(COMPARE_B) $(COMPARE_ARGS)' \; attach

diff:
	$(RADIFF2) -a x86 -D $(COMPARE_BIN_DIR)/pgo-full/bin/clang-14 $(COMPARE_BIN_DIR)/pgo-full-fdoipra3/bin/clang-14 | head -n 100