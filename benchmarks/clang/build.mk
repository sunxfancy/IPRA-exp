
PWD := $(shell pwd)
LLVM = $(PWD)/llvm-project-llvmorg-14.0.6/llvm

# TODO: change this makefile to support clang test

all: .baseline .instrumented .pgo-opt-clang

.baseline: 
	mkdir -p build.dir/baseline
	mkdir -p install.dir/baseline
	cd build.dir/baseline && cmake -G Ninja $(LLVM) \
		-DCMAKE_BUILD_TYPE=Release \
		-DLLVM_TARGETS_TO_BUILD=X86 \
		-DLLVM_OPTIMIZED_TABLEGEN=On \
		-DCMAKE_C_COMPILER=$(CC) \
		-DCMAKE_CXX_COMPILER=$(CXX) \
		-DLLVM_ENABLE_PROJECTS="clang;lld" \
		-DLLVM_USE_LINKER=lld \
		-DCMAKE_INSTALL_PREFIX=$(PWD)/install.dir/baseline
	cd build.dir/baseline && ninja install -j $(shell nproc)
	touch .baseline

.instrumented: 
	mkdir -p build.dir/instrumented
	mkdir -p install.dir/instrumented
	cd build.dir/instrumented && cmake -G Ninja $(LLVM) \
		-DCMAKE_BUILD_TYPE=Release \
		-DLLVM_TARGETS_TO_BUILD=X86 \
		-DLLVM_OPTIMIZED_TABLEGEN=On \
		-DCMAKE_C_COMPILER=$(CC) \
		-DCMAKE_CXX_COMPILER=$(CXX) \
		-DLLVM_ENABLE_PROJECTS="clang;lld" \
		-DLLVM_USE_LINKER=lld \
		-DLLVM_BUILD_INSTRUMENTED=ON \
		-DCMAKE_INSTALL_PREFIX=$(PWD)/install.dir/instrumented
	cd build.dir/instrumented && ninja install -j $(shell nproc)
	touch .instrumented


.pgo-opt-clang:
	mkdir -p build.dir/pgo-opt-clang
	mkdir -p install.dir/pgo-opt-clang
	cd build.dir/pgo-opt-clang && cmake -G Ninja $(LLVM) \
		-DCMAKE_BUILD_TYPE=Release \
		-DLLVM_TARGETS_TO_BUILD=X86 \
		-DLLVM_OPTIMIZED_TABLEGEN=On \
		-DCMAKE_C_COMPILER=$(CC) \
		-DCMAKE_CXX_COMPILER=$(CXX) \
		-DLLVM_ENABLE_PROJECTS="clang;lld" \
		-DLLVM_USE_LINKER=lld \
		-DLLVM_ENABLE_LTO=Thin  \
		-DLLVM_PROFDATA_FILE=$(INSTRUMENTED_PROF)/clang.profdata \
		-DCMAKE_INSTALL_PREFIX=$(PWD)/install.dir/pgo-opt-clang
	cd build.dir/pgo-opt-clang && ninja install -j $(shell nproc)
	touch .pgo-opt-clang


%.clangbench:
	mkdir -p build/clangbench/$(basename $@)
	cd build/clangbench/$(basename $@) && cmake -G Ninja $(LLVM) \
		-DCMAKE_BUILD_TYPE=Release \
		-DLLVM_TARGETS_TO_BUILD=X86 \
		-DLLVM_OPTIMIZED_TABLEGEN=On \
		-DCMAKE_C_COMPILER=$(PWD)/build/clangbench/$(basename $@)/install/bin/clang \
		-DCMAKE_CXX_COMPILER=$(PWD)/build/clangbench/$(basename $@)/install/bin/clang++ \
		-DLLVM_ENABLE_PROJECTS="clang" 
	cd build/clangbench/$(basename $@) && (ninja -t commands | head -100 > $(PWD)/build/clangbench/$(basename $@)/perf_commands.sh)
	cd build/clangbench/$(basename $@) && chmod +x ./perf_commands.sh


download-llvm:
	wget https://github.com/llvm/llvm-project/archive/refs/tags/llvmorg-14.0.6.zip && unzip llvmorg-14.0.6 && rm -f llvmorg-14.0.6.zip
