AUTOFDO_BUILD_TYPE=Release
LLVM_BUILD_TYPE=Release

PWD=$(shell pwd)
FDO=install/FDO


LLVM_IPRA = $(PWD)/LLVM-IPRA
LLVM_BIN = $(PWD)/install/llvm/bin

LLVM_ROOT_PATH = $(PWD)/install/llvm

NCC = $(PWD)/install/llvm/bin/clang_proxy
NCXX = $(PWD)/install/llvm/bin/clang_proxy++

PERF_EVENTS:= -e instructions,cycles,L1-icache-misses,iTLB-misses,L1-dcache-loads,L1-dcache-load-misses,dTLB-load-misses,L1-dcache-stores,L1-dcache-store-misses,dTLB-store-misses,branches,branch-misses,page-faults,context-switches,cpu-migrations

COUNTER:= $(PWD)/install/counter
COUNTSUM:= $(PWD)/install/count-sum
FDO:= $(PWD)/install/FDO
CREATE_REG:= $(PWD)/install/autofdo/create_reg_prof

REMOTE_PERF:=false
ifeq ($(REMOTE_PERF), true)
	COPY_TO_REMOTE:=bash $(PWD)/scripts/copy-to-test-machine.sh
	RUN_FOR_REMOTE:=
	COPY_BACK:=bash $(PWD)/scripts/copy-back.sh
	RUN_ON_REMOTE:=bash $(PWD)/scripts/run-on-remote.sh
	PERF:=$(RUN_ON_REMOTE) perf
else
	COPY_TO_REMOTE:= echo "skip running - " 
	RUN_FOR_REMOTE:= echo "skip running - " 
	COPY_BACK:= echo "skip running - " 
	RUN_ON_REMOTE:= echo "skip running - " 
	PERF:=perf
endif 

# Use mold to speed up linking
# MOLD:= mold -run
MOLD:= 

.PHONY: build check-tools 
build: check-tools  install/llvm install/autofdo install/FDO install/counter install/clang_proxy install/count-sum

BUILD_PATH = build
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

# check-devlibs:
#     $(eval $(call lib-available,HAS_unwind,libunwind-dev))
#     $(eval $(call lib-available,HAS_gflags,libgflags-dev))
#     $(eval $(call lib-available,HAS_ssl,libssl-dev))
#     $(eval $(call lib-available,HAS_elf,libelf-dev))
#     $(eval $(call lib-available,HAS_protobuf,protobuf-compiler))


install/autofdo: build/autofdo
	mold -run cmake --build $(BUILD_PATH)/autofdo --config ${AUTOFDO_BUILD_TYPE} -j $(shell nproc) --target install
	mkdir -p install/autofdo
	cp $(BUILD_PATH)/autofdo/create_llvm_prof install/autofdo/create_llvm_prof
	cp $(BUILD_PATH)/autofdo/profile_merger install/autofdo/profile_merger
	cp $(BUILD_PATH)/autofdo/sample_merger install/autofdo/sample_merger
	cp $(BUILD_PATH)/autofdo/reg_profiler install/autofdo/reg_profiler
	cp $(BUILD_PATH)/autofdo/hot_list_creator install/autofdo/hot_list_creator

build/autofdo: autofdo install/llvm
	mkdir -p build
	cmake -G Ninja -B $(BUILD_PATH)/autofdo -S autofdo \
		-DCMAKE_BUILD_TYPE=${AUTOFDO_BUILD_TYPE} \
		-DLLVM_PATH=${PWD}/install/llvm \
		-DCMAKE_INSTALL_PREFIX=$(BUILD_PATH)/autofdo 

install/llvm: $(BUILD_PATH)/llvm/build.ninja
	mkdir -p install/llvm
	$(MOLD) cmake --build $(BUILD_PATH)/llvm --config ${LLVM_BUILD_TYPE} -j $(shell nproc) --target install
	$(MOLD) cmake --build $(BUILD_PATH)/llvm --config ${LLVM_BUILD_TYPE} -j $(shell nproc) --target install-profile

$(BUILD_PATH)/llvm/build.ninja: LLVM-IPRA
	mkdir -p build
	cmake -G Ninja -B $(BUILD_PATH)/llvm -S LLVM-IPRA/llvm \
		-DCMAKE_BUILD_TYPE=${LLVM_BUILD_TYPE} \
		-DLLVM_ENABLE_ASSERTIONS=ON \
		-DBUILD_SHARED_LIBS=OFF \
		-DLLVM_INCLUDE_TESTS=ON \
		-DLLVM_BUILD_TESTS=ON \
		-DLLVM_OPTIMIZED_TABLEGEN=ON \
		-DLLVM_TARGETS_TO_BUILD="X86" \
		-DLLVM_ENABLE_RTTI=OFF \
		-DLLVM_ENABLE_PROJECTS="clang;lld;llvm;compiler-rt;bolt" \
		-DCMAKE_INSTALL_PREFIX=install/llvm \
		-DLLVM_CCACHE_BUILD=OFF \
		-DCMAKE_EXPORT_COMPILE_COMMANDS=1

# -DCMAKE_C_COMPILER=clang \
# -DCMAKE_CXX_COMPILER=clang++ \

install/FDO: FDO
	mkdir -p install 
	cd FDO && go build .
	mv FDO/FDO install/FDO

install/counter: utils/counter.go
	mkdir -p install
	cd utils && go build counter.go
	mv utils/counter install/counter

install/process_cmd: utils/process_cmd.go
	mkdir -p install
	cd utils && go build process_cmd.go
	mv utils/process_cmd install/process_cmd


install/clang_proxy: utils/clang_proxy.go build/llvm
	mkdir -p install
	cd utils && go build clang_proxy.go
	mv utils/clang_proxy install/llvm/bin/clang_proxy
	rm -f install/llvm/bin/clang_proxy++ 
	ln -s ./clang_proxy install/llvm/bin/clang_proxy++



install/count-sum: check-tools utils/count-sum.cpp
	g++ -std=c++17 -O3 utils/count-sum.cpp -o install/count-sum

download/singularity-ce:
	export VERSION=3.9.3 && cd $(BUILD) && \
	wget https://github.com/sylabs/singularity/releases/download/v${VERSION}/singularity-ce-${VERSION}.tar.gz && \
	tar -xzf singularity-ce-${VERSION}.tar.gz 

build/singularity-ce:
	cd $(BUILD)/singularity-ce-${VERSION} && \
	./mconfig && make -C builddir -j8 && sudo make -C builddir install

singularity/image:
	cd singularity && sudo singularity build image IPRA.def


copy-google-lib:
	mkdir -p install/llvm/lib/gcc
	cp $(GOOGLE_WORKSPACE)/google3/blaze-bin/third_party/llvm/llvm-project/{clang/clang,lld/lld} install/llvm/bin
	cp -Lr $(GOOGLE_LIB_GCC) install/llvm/lib/gcc
	cp -Lr $(GOOGLE_LIB) install/llvm/lib

include benchmarks/build.mk
include example/build.mk