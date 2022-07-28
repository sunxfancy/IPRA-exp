AUTOFDO_BUILD_TYPE=Release
LLVM_BUILD_TYPE=RelWithDebInfo

PWD=$(shell pwd)
FDO=install/FDO

LLVM_TARGET = install/llvm/bin/clang-15
AUTOFDO_TARGET = install/autofdo/create_llvm_prof


CC = $(PWD)/install/llvm/bin/clang
CXX = $(PWD)/install/llvm/bin/clang++
ENABLE_IPRA =  -mllvm -enable-ipra
ENABLE_IPRA_LTO = -Wl,-mllvm -Wl,-enable-ipra
ENABLE_COUNT_PUSH_POP = -mllvm -count-push-pop 
ENABLE_COUNT_PUSH_POP_LTO = -Wl,-mllvm -Wl,-count-push-pop
NO_IPRA = 
COUNTER = $(PWD)/install/counter
FDO = $(PWD)/install/FDO
CREATE_REG = $(PWD)/install/autofdo/create_reg_prof

.PHONY: build check-tools check-devlibs
build: check-tools check-devlibs $(LLVM_TARGET) $(AUTOFDO_TARGET) install/FDO install/counter

BUILD = build
INSTALL = install

define tool-available
    $(eval $(1) := $(shell which $(2)))
    $(if $($(1)),$(info $(2) available at $($(1))),$(error error: missing tool $(2)))
endef

check-tools:
	$(eval $(call tool-available,HAS_CMAKE,cmake))
	$(eval $(call tool-available,HAS_GXX,g++))
	$(eval $(call tool-available,HAS_NINJA,ninja))
	$(eval $(call tool-available,HAS_MOLD,mold))
	$(eval $(call tool-available,HAS_GOLANG,go))

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


$(AUTOFDO_TARGET): build/autofdo/build.ninja
	mold -run cmake --build build/autofdo --config ${AUTOFDO_BUILD_TYPE} -j $(shell nproc) --target install
	mkdir -p install/autofdo
	cp build/autofdo/create_llvm_prof install/autofdo/create_llvm_prof
	cp build/autofdo/create_reg_prof install/autofdo/create_reg_prof
	cp build/autofdo/profile_merger install/autofdo/profile_merger
	cp build/autofdo/sample_merger install/autofdo/sample_merger

build/autofdo/build.ninja: autofdo $(LLVM_TARGET)
	mkdir -p build
	cmake -G Ninja -B build/autofdo -S autofdo \
		-DCMAKE_BUILD_TYPE=${AUTOFDO_BUILD_TYPE} \
		-DLLVM_PATH=${PWD}/install/llvm \
		-DCMAKE_INSTALL_PREFIX=build/autofdo 

$(LLVM_TARGET): build/llvm/build.ninja
	mkdir -p install/llvm
	mold -run cmake --build build/llvm --config ${LLVM_BUILD_TYPE} -j $(shell nproc) --target install
	mold -run cmake --build build/llvm --config ${LLVM_BUILD_TYPE} -j $(shell nproc) --target install-profile

build/llvm/build.ninja: LLVM-IPRA
	mkdir -p build
	cmake -G Ninja -B build/llvm -S LLVM-IPRA/llvm \
		-DCMAKE_BUILD_TYPE=${LLVM_BUILD_TYPE} \
		-DLLVM_ENABLE_ASSERTIONS=ON \
		-DBUILD_SHARED_LIBS=OFF \
		-DLLVM_PARALLEL_LINK_JOBS=1 \
		-DLLVM_INCLUDE_TESTS=OFF \
		-DLLVM_BUILD_TESTS=OFF \
		-DLLVM_OPTIMIZED_TABLEGEN=ON \
		-DLLVM_TARGETS_TO_BUILD="X86" \
		-DLLVM_ENABLE_RTTI=ON \
		-DLLVM_ENABLE_PROJECTS="clang;lld;llvm;compiler-rt;bolt" \
		-DCMAKE_INSTALL_PREFIX=install/llvm

install/FDO: FDO
	mkdir -p install 
	cd FDO && go build .
	mv FDO/FDO install/FDO

install/counter: counter/counter.go
	mkdir -p install
	cd counter && go build counter.go
	mv counter/counter install/counter

include $(wildcard */build.mk)