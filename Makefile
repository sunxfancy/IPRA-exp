AUTOFDO_BUILD_TYPE=Release
LLVM_BUILD_TYPE=RelWithDebInfo

PWD=$(shell pwd)
FDO=install/FDO

LLVM_IPRA = $(PWD)/LLVM-IPRA
LLVM_BIN = $(PWD)/install/llvm/bin

NCC = $(PWD)/install/llvm/bin/clang-proxy
NCXX = $(PWD)/install/llvm/bin/clang-proxy++
ENABLE_IPRA =  -mllvm -enable-ipra
ENABLE_IPRA_LTO = -Wl,-mllvm -Wl,-enable-ipra
ENABLE_COUNT_PUSH_POP = -mllvm -count-push-pop 
ENABLE_COUNT_PUSH_POP_LTO = -Wl,-mllvm -Wl,-count-push-pop
NO_IPRA = 
COUNTER:= $(PWD)/install/counter
COUNTSUM:= $(PWD)/install/count-sum
FDO:= $(PWD)/install/FDO
CREATE_REG:= $(PWD)/install/autofdo/create_reg_prof

.PHONY: build check-tools check-devlibs
build: install/llvm install/autofdo install/FDO install/counter install/clang-proxy install/count-sum

BUILD = build
INSTALL = install

define tool-available
    $(eval $(1) := $(shell which $(2)))
    $(if $($(1)),$(info $(2) available at $($(1))),$(error error: missing tool $(2)))
endef

define opttool-available
    $(eval $(1) := $(shell which $(2)))
    $(if $($(1)),$(info $(2) available at $($(1))),$(info warning: missing tool $(2)))
endef

check-tools:
	$(eval $(call tool-available,HAS_CMAKE,cmake))
	$(eval $(call tool-available,HAS_GXX,g++))
	$(eval $(call tool-available,HAS_NINJA,ninja))
	$(eval $(call tool-available,HAS_GOLANG,go))
	$(eval $(call opttool-available,HAS_PERF,perf))
	$(eval $(call opttool-available,HAS_MOLD,mold))
	$(eval $(call opttool-available,HAS_SYSBENCH,sysbench))

define lib-available
	$(eval $(1) := $(shell dpkg -l $(2)))
	$(if $($(1)),$(info $(2) is installed),$(shell sudo apt-get install $(2)))
endef

check-devlibs:
	$(eval $(call lib-available,HAS_unwind,libunwind-dev))
	$(eval $(call lib-available,HAS_gflags,libgflags-dev))
	$(eval $(call lib-available,HAS_ssl,libssl-dev))
	$(eval $(call lib-available,HAS_elf,libelf-dev))
	$(eval $(call lib-available,HAS_protobuf,protobuf-compiler))


install/autofdo: build/autofdo
	mold -run cmake --build build/autofdo --config ${AUTOFDO_BUILD_TYPE} -j $(shell nproc) --target install
	mkdir -p install/autofdo
	cp build/autofdo/create_llvm_prof install/autofdo/create_llvm_prof
	cp build/autofdo/create_reg_prof install/autofdo/create_reg_prof
	cp build/autofdo/profile_merger install/autofdo/profile_merger
	cp build/autofdo/sample_merger install/autofdo/sample_merger

build/autofdo: check-tools check-devlibs autofdo install/llvm
	mkdir -p build
	cmake -G Ninja -B build/autofdo -S autofdo \
		-DCMAKE_BUILD_TYPE=${AUTOFDO_BUILD_TYPE} \
		-DLLVM_PATH=${PWD}/install/llvm \
		-DCMAKE_INSTALL_PREFIX=build/autofdo 

install/llvm: build/llvm
	mkdir -p install/llvm
	mold -run cmake --build build/llvm --config ${LLVM_BUILD_TYPE} -j $(shell nproc) --target install
	mold -run cmake --build build/llvm --config ${LLVM_BUILD_TYPE} -j $(shell nproc) --target install-profile

build/llvm: check-tools LLVM-IPRA
	mkdir -p build
	cmake -G Ninja -B build/llvm -S LLVM-IPRA/llvm \
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

install/FDO: check-tools FDO
	mkdir -p install 
	cd FDO && go build .
	mv FDO/FDO install/FDO

install/counter: check-tools utils/counter.go
	mkdir -p install
	cd utils && go build counter.go
	mv utils/counter install/counter

install/clang-proxy: check-tools utils/clang-proxy.go build/llvm
	mkdir -p install
	cd utils && go build clang-proxy.go
	mv utils/clang-proxy install/llvm/bin/clang-proxy
	rm -f install/llvm/bin/clang-proxy++ 
	ln -s ./clang-proxy install/llvm/bin/clang-proxy++

install/count-sum: check-tools utils/count-sum.cpp
	g++ -std=c++17 -O3 utils/count-sum.cpp -o install/count-sum

include benchmarks/build.mk
include example/build.mk