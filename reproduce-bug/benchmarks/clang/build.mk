mkfile_path := $(dir $(abspath $(lastword $(MAKEFILE_LIST))))

PWD := $(shell pwd)
CLANG_VERSION=llvmorg-14.0.6
LLVM = $(PWD)/llvm-project-$(CLANG_VERSION)/llvm
INSTRUMENTED_PROF=$(PWD)/build.dir/instrumented/profiles

all: .instrumented .pgolto .pgolto-full .pgolto-ipra .pgolto-full-ipra pgolto-full.bench pgolto-full-ipra.bench 

common_compiler_flags := -fuse-ld=lld -fPIC -fno-inline
common_linker_flags := -fuse-ld=lld -fno-inline

gen_compiler_flags = -DCMAKE_C_FLAGS=$(1) -DCMAKE_CXX_FLAGS=$(1)
gen_linker_flags   = -DCMAKE_EXE_LINKER_FLAGS=$(1) -DCMAKE_SHARED_LINKER_FLAGS=$(1) -DCMAKE_MODULE_LINKER_FLAGS=$(1)
gen_build_flags = $(call gen_compiler_flags,"$(common_compiler_flags) $(1)") $(call gen_linker_flags,"$(common_linker_flags) $(2)")
COMMA := ,


define build_clang
	rm -f /tmp/count-push-pop.txt 
	touch /tmp/count-push-pop.txt
    mkdir -p build.dir/$(1)
	mkdir -p install.dir/$(1)
	cd build.dir/$(1) && cmake -G Ninja $(LLVM) \
		-DCMAKE_BUILD_TYPE=Release \
		-DLLVM_OPTIMIZED_TABLEGEN=ON \
		-DLLVM_TARGETS_TO_BUILD="X86" \
		-DLLVM_ENABLE_RTTI=ON \
		-DBUILD_SHARED_LIBS=OFF \
		-DLLVM_INCLUDE_TESTS=ON \
		-DLLVM_BUILD_TESTS=ON \
		-DCMAKE_C_COMPILER=$(NCC) \
		-DCMAKE_CXX_COMPILER=$(NCXX) \
		-DLLVM_ENABLE_PROJECTS="clang;compiler-rt;lld" \
		-DLLVM_USE_LINKER=lld \
		-DCMAKE_INSTALL_PREFIX=$(PWD)/install.dir/$(1) \
		$(2)
	cd build.dir/$(1) && time -o time.log ninja install -j $(shell nproc) -v > build.log
	echo "---------$(1)---------" >> ../clang.output
	cat /tmp/count-push-pop.txt >> ../clang.output 
	touch .$(1)
endef

define clang_bench
	mkdir -p build.dir/clangbench/$(1)
	cd build.dir/clangbench/$(1) && cmake -G Ninja $(LLVM) \
		-DCMAKE_BUILD_TYPE=RelWithDebInfo \
		-DLLVM_TARGETS_TO_BUILD=X86 \
		-DLLVM_OPTIMIZED_TABLEGEN=On \
		-DCMAKE_C_COMPILER=$(2)/clang \
		-DCMAKE_CXX_COMPILER=$(2)/clang++ \
		-DLLVM_ENABLE_PROJECTS="clang" 
	cd build.dir/clangbench/$(1) && (ninja -t commands | head -100 > $(PWD)/build.dir/clangbench/$(1)/perf_commands.sh)
	cd build.dir/clangbench/$(1) && chmod +x ./perf_commands.sh
endef 

.instrumented: llvm-project-$(CLANG_VERSION)
	$(call build_clang,instrumented,-DLLVM_BUILD_INSTRUMENTED=ON $(call gen_build_flags,,))

.pgolto: $(INSTRUMENTED_PROF)/clang.profdata
	$(call build_clang,pgolto,-DLLVM_ENABLE_LTO=Thin $(call gen_build_flags,,) -DLLVM_PROFDATA_FILE=$(INSTRUMENTED_PROF)/clang.profdata)

.pgolto-ipra: $(INSTRUMENTED_PROF)/clang.profdata
	$(call build_clang,pgolto-ipra,-DLLVM_ENABLE_LTO=Thin $(call gen_build_flags,,-Wl$(COMMA)-mllvm -Wl$(COMMA)-enable-ipra -Wl$(COMMA)-Bsymbolic-non-weak-functions) -DLLVM_PROFDATA_FILE=$(INSTRUMENTED_PROF)/clang.profdata)

.pgolto-full-ipra: $(INSTRUMENTED_PROF)/clang.profdata
	$(call build_clang,pgolto-full-ipra,-DLLVM_ENABLE_LTO=Full $(call gen_build_flags,,-Wl$(COMMA)-mllvm -Wl$(COMMA)-enable-ipra -Wl$(COMMA)-Bsymbolic-non-weak-functions) -DLLVM_PROFDATA_FILE=$(INSTRUMENTED_PROF)/clang.profdata)

.pgolto-full: $(INSTRUMENTED_PROF)/clang.profdata
	$(call build_clang,pgolto-full,-DLLVM_ENABLE_LTO=Full $(call gen_build_flags,,-Wl$(COMMA)-Bsymbolic-non-weak-functions) -DLLVM_PROFDATA_FILE=$(INSTRUMENTED_PROF)/clang.profdata)

.pgolto-full-fdoipra-may-crash: $(INSTRUMENTED_PROF)/clang.profdata
	$(call build_clang,pgolto-full-fdoipra,-DLLVM_ENABLE_LTO=Full $(call gen_build_flags,,-Wl$(COMMA)-mllvm -Wl$(COMMA)-fdo-ipra -Wl$(COMMA)-Bsymbolic-non-weak-functions) -DLLVM_PROFDATA_FILE=$(INSTRUMENTED_PROF)/clang.profdata)

.pgolto-full-fdoipra: $(INSTRUMENTED_PROF)/clang.profdata
	$(call build_clang,pgolto-full-fdoipra,-DLLVM_ENABLE_LTO=Full $(call gen_build_flags,-fno-optimize-sibling-calls,-Wl$(COMMA)-mllvm -Wl$(COMMA)-fdo-ipra -Wl$(COMMA)-Bsymbolic-non-weak-functions) -DLLVM_PROFDATA_FILE=$(INSTRUMENTED_PROF)/clang.profdata)

.pgolto-full-ipra-fdoipra: $(INSTRUMENTED_PROF)/clang.profdata
	$(call build_clang,pgolto-full-ipra-fdoipra,-DLLVM_ENABLE_LTO=Full $(call gen_build_flags,-fno-optimize-sibling-calls,-Wl$(COMMA)-mllvm -Wl$(COMMA)-fdo-ipra -Wl$(COMMA)-mllvm -Wl$(COMMA)-enable-ipra -Wl$(COMMA)-Bsymbolic-non-weak-functions) -DLLVM_PROFDAT_FILE=$(INSTRUMENTED_PROF)/clang.profdata)


$(INSTRUMENTED_PROF)/clang.profdata:  .instrumented
	$(call clang_bench,instrumented,$(PWD)/install.dir/instrumented/bin)
	cd build.dir/clangbench/instrumented && ./perf_commands.sh
	cd $(INSTRUMENTED_PROF) && $(LLVM_BIN)/llvm-profdata merge -output=clang.profdata *

%.bench: .% 
	$(call clang_bench,$(basename $@),$(PWD)/install.dir/$(basename $@)/bin)
	cd build.dir/clangbench/$(basename $@) && perf stat -o $(basename $@).bench -r5 -- bash ./perf_commands.sh

llvm-project-$(CLANG_VERSION):
	wget https://github.com/llvm/llvm-project/archive/refs/tags/$(CLANG_VERSION).zip && unzip $(CLANG_VERSION) && rm -f $(CLANG_VERSION).zip


check:
	install.dir/pgolto-full-fdoipra/bin/clang++ -g -O3 $(mkfile_path)test.cpp -o test.cpp.o

check-gdb:
	gdb --args /usr/local/google/home/xiaofans/workspace/IPRA-exp/build/benchmarks/clang/install.dir/pgolto-full-fdoipra/bin/clang-14 -cc1 -triple x86_64-unknown-linux-gnu -emit-obj --mrelax-relocations -disable-free -clear-ast-before-backend -disable-llvm-verifier -discard-value-names -main-file-name test.cpp -mrelocation-model static -mframe-pointer=none -fmath-errno -ffp-contract=on -fno-rounding-math -mconstructor-aliases -funwind-tables=2 -target-cpu x86-64 -tune-cpu generic -mllvm -treat-scalable-fixed-error-as-warning -debug-info-kind=constructor -dwarf-version=5 -debugger-tuning=gdb -fcoverage-compilation-dir=/usr/local/google/home/xiaofans/workspace/IPRA-exp/build/benchmarks/clang -resource-dir /usr/local/google/home/xiaofans/workspace/IPRA-exp/build/benchmarks/clang/install.dir/pgolto-full-fdoipra/lib/clang/14.0.6 -internal-isystem /usr/lib/gcc/x86_64-linux-gnu/11/../../../../include/c++/11 -internal-isystem /usr/lib/gcc/x86_64-linux-gnu/11/../../../../include/x86_64-linux-gnu/c++/11 -internal-isystem /usr/lib/gcc/x86_64-linux-gnu/11/../../../../include/c++/11/backward -internal-isystem /usr/local/google/home/xiaofans/workspace/IPRA-exp/build/benchmarks/clang/install.dir/pgolto-full-fdoipra/lib/clang/14.0.6/include -internal-isystem /usr/local/include -internal-isystem /usr/lib/gcc/x86_64-linux-gnu/11/../../../../x86_64-linux-gnu/include -internal-externc-isystem /usr/include/x86_64-linux-gnu -internal-externc-isystem /include -internal-externc-isystem /usr/include -O3 -fdeprecated-macro -fdebug-compilation-dir=/usr/local/google/home/xiaofans/workspace/IPRA-exp/build/benchmarks/clang -ferror-limit 19 -fmessage-length=454 -fgnuc-version=4.2.1 -fcxx-exceptions -fexceptions -fcolor-diagnostics -vectorize-loops -vectorize-slp -faddrsig -D__GCC_HAVE_DWARF2_CFI_ASM=1 -o /tmp/test-4c9ef2.o -x c++ /usr/local/google/home/xiaofans/workspace/IPRA-exp/benchmarks/clang/test.cpp

dbg1:
	cd /usr/local/google/home/xiaofans/workspace/IPRA-exp/build/benchmarks/clang/build.dir/pgolto-full-fdoipra/ && /usr/local/google/home/xiaofans/workspace/IPRA-exp/install/llvm/bin/ld.lld -pie --eh-frame-hdr -m elf_x86_64 -dynamic-linker /lib64/ld-linux-x86-64.so.2 -o bin/clang-import-test /lib/x86_64-linux-gnu/Scrt1.o /lib/x86_64-linux-gnu/crti.o /usr/lib/gcc/x86_64-linux-gnu/11/crtbeginS.o -L/usr/lib/gcc/x86_64-linux-gnu/11 -L/usr/lib/gcc/x86_64-linux-gnu/11/../../../../lib64 -L/lib/x86_64-linux-gnu -L/lib/../lib64 -L/usr/lib/x86_64-linux-gnu -L/usr/lib/../lib64 -L/lib -L/usr/lib -plugin-opt=mcpu=x86-64 -plugin-opt=O3 -plugin-opt=cs-profile-path=/usr/local/google/home/xiaofans/workspace/IPRA-exp/build/benchmarks/clang/build.dir/instrumented/profiles/clang.profdata -mllvm -fdo-ipra -Bsymbolic-non-weak-functions --color-diagnostics --gc-sections tools/clang/tools/clang-import-test/CMakeFiles/clang-import-test.dir/clang-import-test.cpp.o -rpath \\RIGIN/../lib lib/libLLVMCore.a lib/libLLVMSupport.a -lpthread lib/libclangAST.a lib/libclangBasic.a lib/libclangCodeGen.a lib/libclangDriver.a lib/libclangFrontend.a lib/libclangLex.a lib/libclangParse.a lib/libclangSerialization.a lib/libclangDriver.a lib/libLLVMOption.a lib/libclangSema.a lib/libclangEdit.a lib/libclangAnalysis.a lib/libclangASTMatchers.a lib/libclangAST.a lib/libclangLex.a lib/libclangBasic.a lib/libLLVMCoverage.a lib/libLLVMLTO.a lib/libLLVMExtensions.a lib/libLLVMCodeGen.a lib/libLLVMPasses.a lib/libLLVMCoroutines.a lib/libLLVMipo.a lib/libLLVMFrontendOpenMP.a lib/libLLVMBitWriter.a lib/libLLVMIRReader.a lib/libLLVMAsmParser.a lib/libLLVMLinker.a lib/libLLVMInstrumentation.a lib/libLLVMObjCARCOpts.a lib/libLLVMVectorize.a lib/libLLVMScalarOpts.a lib/libLLVMAggressiveInstCombine.a lib/libLLVMInstCombine.a lib/libLLVMTarget.a lib/libLLVMTransformUtils.a lib/libLLVMAnalysis.a lib/libLLVMProfileData.a lib/libLLVMDebugInfoDWARF.a lib/libLLVMObject.a lib/libLLVMBitReader.a lib/libLLVMCore.a lib/libLLVMRemarks.a lib/libLLVMBitstreamReader.a lib/libLLVMMCParser.a lib/libLLVMMC.a lib/libLLVMDebugInfoCodeView.a lib/libLLVMTextAPI.a lib/libLLVMBinaryFormat.a lib/libLLVMSupport.a -lrt -ldl -lpthread -lm /usr/lib/x86_64-linux-gnu/libz.so /usr/lib/x86_64-linux-gnu/libtinfo.so lib/libLLVMDemangle.a -lstdc++ -lm -lgcc_s -lgcc -lc -lgcc_s -lgcc /usr/lib/gcc/x86_64-linux-gnu/11/crtendS.o /lib/x86_64-linux-gnu/crtn.o

dbg1-gdb:
	cd /usr/local/google/home/xiaofans/workspace/IPRA-exp/build/benchmarks/clang/build.dir/pgolto-full-fdoipra/ && gdb --args /usr/local/google/home/xiaofans/workspace/IPRA-exp/install/llvm/bin/ld.lld --args -pie --eh-frame-hdr -m elf_x86_64 -dynamic-linker /lib64/ld-linux-x86-64.so.2 -o bin/clang-import-test /lib/x86_64-linux-gnu/Scrt1.o /lib/x86_64-linux-gnu/crti.o /usr/lib/gcc/x86_64-linux-gnu/11/crtbeginS.o -L/usr/lib/gcc/x86_64-linux-gnu/11 -L/usr/lib/gcc/x86_64-linux-gnu/11/../../../../lib64 -L/lib/x86_64-linux-gnu -L/lib/../lib64 -L/usr/lib/x86_64-linux-gnu -L/usr/lib/../lib64 -L/lib -L/usr/lib -plugin-opt=mcpu=x86-64 -plugin-opt=O3 -plugin-opt=cs-profile-path=/usr/local/google/home/xiaofans/workspace/IPRA-exp/build/benchmarks/clang/build.dir/instrumented/profiles/clang.profdata -mllvm -fdo-ipra -Bsymbolic-non-weak-functions --color-diagnostics --gc-sections tools/clang/tools/clang-import-test/CMakeFiles/clang-import-test.dir/clang-import-test.cpp.o -rpath \\RIGIN/../lib lib/libLLVMCore.a lib/libLLVMSupport.a -lpthread lib/libclangAST.a lib/libclangBasic.a lib/libclangCodeGen.a lib/libclangDriver.a lib/libclangFrontend.a lib/libclangLex.a lib/libclangParse.a lib/libclangSerialization.a lib/libclangDriver.a lib/libLLVMOption.a lib/libclangSema.a lib/libclangEdit.a lib/libclangAnalysis.a lib/libclangASTMatchers.a lib/libclangAST.a lib/libclangLex.a lib/libclangBasic.a lib/libLLVMCoverage.a lib/libLLVMLTO.a lib/libLLVMExtensions.a lib/libLLVMCodeGen.a lib/libLLVMPasses.a lib/libLLVMCoroutines.a lib/libLLVMipo.a lib/libLLVMFrontendOpenMP.a lib/libLLVMBitWriter.a lib/libLLVMIRReader.a lib/libLLVMAsmParser.a lib/libLLVMLinker.a lib/libLLVMInstrumentation.a lib/libLLVMObjCARCOpts.a lib/libLLVMVectorize.a lib/libLLVMScalarOpts.a lib/libLLVMAggressiveInstCombine.a lib/libLLVMInstCombine.a lib/libLLVMTarget.a lib/libLLVMTransformUtils.a lib/libLLVMAnalysis.a lib/libLLVMProfileData.a lib/libLLVMDebugInfoDWARF.a lib/libLLVMObject.a lib/libLLVMBitReader.a lib/libLLVMCore.a lib/libLLVMRemarks.a lib/libLLVMBitstreamReader.a lib/libLLVMMCParser.a lib/libLLVMMC.a lib/libLLVMDebugInfoCodeView.a lib/libLLVMTextAPI.a lib/libLLVMBinaryFormat.a lib/libLLVMSupport.a -lrt -ldl -lpthread -lm /usr/lib/x86_64-linux-gnu/libz.so /usr/lib/x86_64-linux-gnu/libtinfo.so lib/libLLVMDemangle.a -lstdc++ -lm -lgcc_s -lgcc -lc -lgcc_s -lgcc /usr/lib/gcc/x86_64-linux-gnu/11/crtendS.o /lib/x86_64-linux-gnu/crtn.o && rr replay
