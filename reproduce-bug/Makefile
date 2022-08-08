
LLVM_BUILD_TYPE=RelWithDebInfo
LLVM_BIN = $(PWD)/install/llvm/bin

NCC = $(PWD)/install/llvm/bin/clang
NCXX = $(PWD)/install/llvm/bin/clang++

export

all: install/llvm 
	make benchmarks/clang

SUBDIRS := $(patsubst %/build.mk,%,$(wildcard benchmarks/*/build.mk))

.PHONY: $(SUBDIRS)

$(SUBDIRS):
	mkdir -p build/$@
	$(MAKE) -C build/$@ -f $(PWD)/$@/build.mk

benchmarks/%: 
	mkdir -p build/$(dir $@)
	echo $(dir $@)
	$(MAKE) -C build/$(dir $@) -f $(PWD)/$(dir $@)build.mk $(notdir $@)


llvm-project-main:
	wget https://github.com/llvm/llvm-project/archive/refs/heads/main.zip && unzip main && rm -f main.zip

	
install/llvm: build/llvm
	mkdir -p install/llvm
	cmake --build build/llvm --config ${LLVM_BUILD_TYPE} -j $(shell nproc) --target install
	cmake --build build/llvm --config ${LLVM_BUILD_TYPE} -j $(shell nproc) --target install-profile

build/llvm: llvm-project-main
	mkdir -p build
	cmake -G Ninja -B build/llvm -S llvm-project-main/llvm \
		-DCMAKE_BUILD_TYPE=${LLVM_BUILD_TYPE} \
		-DLLVM_ENABLE_ASSERTIONS=ON \
		-DBUILD_SHARED_LIBS=OFF \
		-DLLVM_INCLUDE_TESTS=ON \
		-DLLVM_BUILD_TESTS=ON \
		-DLLVM_OPTIMIZED_TABLEGEN=ON \
		-DLLVM_TARGETS_TO_BUILD="X86" \
		-DLLVM_ENABLE_RTTI=ON \
		-DLLVM_ENABLE_PROJECTS="clang;lld;llvm;compiler-rt;bolt" \
		-DCMAKE_INSTALL_PREFIX=install/llvm
