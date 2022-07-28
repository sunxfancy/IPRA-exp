
PWD := $(shell pwd)
LLVM = $(PWD)/llvm-project-llvmorg-14.0.6/llvm
INSTRUMENTED_PROF=$(PWD)/build.dir/instrumented/profiles

all: .instrumented .pgolto .pgolto-ipra .pgolto-full-ipra .pgolto-full-fdoipra .pgolto-full-ipra-fdoipra

common_compiler_flags := -fuse-ld=lld -fPIC
common_linker_flags := -fuse-ld=lld

gen_compiler_flags = -DCMAKE_C_FLAGS=$(1) -DCMAKE_CXX_FLAGS=$(1)
gen_linker_flags   = -DCMAKE_EXE_LINKER_FLAGS=$(1) -DCMAKE_SHARED_LINKER_FLAGS=$(1) -DCMAKE_MODULE_LINKER_FLAGS=$(1)
gen_build_flags = $(call gen_compiler_flags,"$(common_compiler_flags) $(1)") $(call gen_linker_flags,"$(common_linker_flags) $(2)")
COMMA := ,

define build_clang
    mkdir -p build.dir/$(1)
	mkdir -p install.dir/$(1)
	cd build.dir/$(1) && cmake -G Ninja $(LLVM) \
		-DCMAKE_BUILD_TYPE=Release \
		-DLLVM_OPTIMIZED_TABLEGEN=ON \
		-DLLVM_TARGETS_TO_BUILD="X86" \
		-DLLVM_ENABLE_RTTI=ON \
		-DBUILD_SHARED_LIBS=OFF \
		-DLLVM_INCLUDE_TESTS=OFF \
		-DLLVM_BUILD_TESTS=OFF \
		-DCMAKE_C_COMPILER=$(CC) \
		-DCMAKE_CXX_COMPILER=$(CXX) \
		-DLLVM_ENABLE_PROJECTS="clang;compiler-rt;lld" \
		-DLLVM_USE_LINKER=lld \
		-DCMAKE_INSTALL_PREFIX=$(PWD)/install.dir/$(1) \
		$(2)
	cd build.dir/$(1) && ninja install -j $(shell nproc)
	touch .$(1)
endef

define clang_bench
	mkdir -p build.dir/clangbench/$(1)
	cd build.dir/clangbench/$(1) && cmake -G Ninja $(LLVM) \
		-DCMAKE_BUILD_TYPE=Release \
		-DLLVM_TARGETS_TO_BUILD=X86 \
		-DLLVM_OPTIMIZED_TABLEGEN=On \
		-DCMAKE_C_COMPILER=$(2)/clang \
		-DCMAKE_CXX_COMPILER=$(2)/clang++ \
		-DLLVM_ENABLE_PROJECTS="clang" 
	cd build.dir/clangbench/$(1) && (ninja -t commands | head -100 > $(PWD)/build.dir/clangbench/$(1)/perf_commands.sh)
	cd build.dir/clangbench/$(1) && chmod +x ./perf_commands.sh
endef 


.instrumented: 
	$(call build_clang,instrumented,-DLLVM_BUILD_INSTRUMENTED=ON)

.pgolto:  $(INSTRUMENTED_PROF)/clang.profdata
	$(call build_clang,pgolto,-DLLVM_ENABLE_LTO=Thin -DLLVM_PROFDATA_FILE=$(INSTRUMENTED_PROF)/clang.profdata)

.pgolto-ipra: 
	$(call build_clang,pgolto-ipra,-DLLVM_ENABLE_LTO=Thin $(call gen_build_flags,,-Wl$(COMMA)-mllvm -Wl$(COMMA)-enable-ipra,-Wl$(COMMA)-Bsymbolic-non-weak-functions) -DLLVM_PROFDATA_FILE=$(INSTRUMENTED_PROF)/clang.profdata)

.pgolto-full-ipra:
	$(call build_clang,pgolto-full-ipra,-DLLVM_ENABLE_LTO=Full $(call gen_build_flags,,-Wl$(COMMA)-mllvm -Wl$(COMMA)-enable-ipra,-Wl$(COMMA)-Bsymbolic-non-weak-functions) -DLLVM_PROFDATA_FILE=$(INSTRUMENTED_PROF)/clang.profdata)

.pgolto-full-fdoipra:
	$(call build_clang,pgolto-full-fdoipra,-DLLVM_ENABLE_LTO=Full $(call gen_build_flags,,-Wl$(COMMA)-mllvm -Wl$(COMMA)-fdo-ipra,-Wl$(COMMA)-Bsymbolic-non-weak-functions) -DLLVM_PROFDATA_FILE=$(INSTRUMENTED_PROF)/clang.profdata)

.pgolto-full-ipra-fdoipra:
	$(call build_clang,pgolto-full-ipra-fdoipra,-DLLVM_ENABLE_LTO=Full $(call gen_build_flags,,-Wl$(COMMA)-mllvm -Wl$(COMMA)-fdo-ipra -Wl$(COMMA)-mllvm -Wl$(COMMA)-enable-ipra,-Wl$(COMMA)-Bsymbolic-non-weak-functions) -DLLVM_PROFDAT_FILE=$(INSTRUMENTED_PROF)/clang.profdata)


$(INSTRUMENTED_PROF)/clang.profdata:  .instrumented
	$(call clang_bench,instrumented,$(PWD)/install.dir/instrumented/bin)
	cd build.dir/clangbench/instrumented && ./perf_commands.sh
	cd $(INSTRUMENTED_PROF) && $(LLVM_BIN)/llvm-profdata merge -output=clang.profdata *

download-llvm:
	wget https://github.com/llvm/llvm-project/archive/refs/tags/llvmorg-14.0.6.zip && unzip llvmorg-14.0.6 && rm -f llvmorg-14.0.6.zip
