
benchmarks: benchmarks-build
	make benchmarks/mysql/bench
	make benchmarks/clang/bench

benchmarks-build: benchmarks/mysql benchmarks/clang

DonwloadTargets = download/snubench download/dparser download/vorbis-tools download/C_FFT 

build-benchmarks-dir:
	mkdir -p build/benchmarks

.PHONY: $(DonwloadTargets)
download-benchmarks: build-benchmarks-dir $(DonwloadTargets)
	
download/snubench:
	cd build/benchmarks && wget http://www.cprover.org/goto-cc/examples/binaries/SNU-real-time.tar.gz && tar -xvf ./SNU-real-time.tar.gz && rm ./SNU-real-time.tar.gz

download/dparser:
	cd build/benchmarks && wget https://github.com/jplevyak/dparser/archive/refs/heads/master.zip && unzip ./master.zip && rm ./master.zip

download/vorbis-tools:
	cd build/benchmarks && wget https://github.com/xiph/vorbis-tools/archive/refs/heads/master.zip && unzip ./master.zip && rm ./master.zip

download/C_FFT:
	cd build/benchmarks && wget https://github.com/sunxfancy/C_FFT/archive/refs/heads/master.zip && unzip ./master.zip && rm ./master.zip


build/benchmarks/mysql-experiment/packages/mysql-boost-8.0.30.tar.gz:
	mkdir -p build/benchmarks
	cd build/benchmarks && git clone git@github.com:sunxfancy/mysql-experiment.git
	cd build/benchmarks/mysql-experiment/packages && wget https://dev.mysql.com/get/Downloads/MySQL-8.0/mysql-boost-8.0.30.tar.gz

define save_to_output
	rm -rf build/benchmarks/mysql-experiment/$(1)
	rm -f /tmp/count-push-pop.txt 
	cd build/benchmarks/mysql-experiment && make $(1)/install/bin/mysqld LLVM_INSTALL_BIN=$(PWD)/install/llvm/bin
	echo "---------$(1)---------" >> build/benchmarks/mysql.output
	cat /tmp/count-push-pop.txt | $(COUNTSUM) >> build/benchmarks/mysql.output 
	echo "---------$(1)---------" >> build/benchmarks/mysql.raw
	cat /tmp/count-push-pop.txt >> build/benchmarks/mysql.raw 
endef

benchmarks/mysql: build/benchmarks/mysql-experiment/packages/mysql-boost-8.0.30.tar.gz
	cd build/benchmarks/mysql-experiment && make pgo_instrument-mysql/profile-data/default.profdata LLVM_INSTALL_BIN=$(PWD)/install/llvm/bin
	-$(call save_to_output,pgolto-mysql)
	-$(call save_to_output,pgolto-ipra-mysql)
	-$(call save_to_output,pgolto-fdoipra-mysql)
	-$(call save_to_output,pgolto-full-mysql)
	-$(call save_to_output,pgolto-full-ipra-mysql)
	-$(call save_to_output,pgolto-full-fdoipra-mysql)

benchmarks/mysql/%:
	-$(call save_to_output,$(notdir $@)-mysql)

# $(call save_to_output,pgolto-full-ipra-fdoipra-mysql)

benchmarks/mysql/bench: 
	-cd build/benchmarks/mysql-experiment && make pgolto-mysql/sysbench
	-cd build/benchmarks/mysql-experiment && make pgolto-ipra-mysql/sysbench
	-cd build/benchmarks/mysql-experiment && make pgolto-fdoipra-mysql/sysbench
	-cd build/benchmarks/mysql-experiment && make pgolto-full-mysql/sysbench
	-cd build/benchmarks/mysql-experiment && make pgolto-full-ipra-mysql/sysbench
	-cd build/benchmarks/mysql-experiment && make pgolto-full-fdoipra-mysql/sysbench

export

SUBDIRS := $(patsubst %/build.mk,%,$(wildcard benchmarks/*/build.mk))

.PHONY: $(SUBDIRS)

$(SUBDIRS):
	mkdir -p build/$@
	$(MAKE) -C build/$@ -f $(PWD)/$@/build.mk

benchmarks/%: 
	mkdir -p build/$(dir $@)
	echo $(dir $@)
	$(MAKE) -C build/$(dir $@) -f $(PWD)/$(dir $@)build.mk $(notdir $@)


compare:
	@tmux new-session -d /bin/sh -c "cd /usr/local/google/home/xiaofans/workspace/IPRA-exp/build/benchmarks/clang/build.dir/pgolto-full-fdoipra && gdb --args /usr/local/google/home/xiaofans/workspace/IPRA-exp/build/benchmarks/clang/build.dir/pgolto-full-fdoipra/bin/clang-tblgen -gen-clang-attr-node-traverse -I /usr/local/google/home/xiaofans/workspace/IPRA-exp/build/benchmarks/clang/llvm-project-llvmorg-14.0.6/clang/include/clang/AST -I/usr/local/google/home/xiaofans/workspace/IPRA-exp/build/benchmarks/clang/llvm-project-llvmorg-14.0.6/clang/include -I/usr/local/google/home/xiaofans/workspace/IPRA-exp/build/benchmarks/clang/build.dir/pgolto-full-fdoipra/tools/clang/include -I/usr/local/google/home/xiaofans/workspace/IPRA-exp/build/benchmarks/clang/build.dir/pgolto-full-fdoipra/include -I/usr/local/google/home/xiaofans/workspace/IPRA-exp/build/benchmarks/clang/llvm-project-llvmorg-14.0.6/llvm/include /usr/local/google/home/xiaofans/workspace/IPRA-exp/build/benchmarks/clang/llvm-project-llvmorg-14.0.6/clang/include/clang/AST/../Basic/Attr.td --write-if-changed -o tools/clang/include/clang/AST/AttrNodeTraverse.inc -d tools/clang/include/clang/AST/AttrNodeTraverse.inc.d" \; \
	     split-window -h /bin/sh -c "cd /usr/local/google/home/xiaofans/workspace/IPRA-exp/build/benchmarks/clang/build.dir/pgolto-full && gdb --args /usr/local/google/home/xiaofans/workspace/IPRA-exp/build/benchmarks/clang/build.dir/pgolto-full/bin/clang-tblgen -gen-clang-attr-node-traverse -I /usr/local/google/home/xiaofans/workspace/IPRA-exp/build/benchmarks/clang/llvm-project-llvmorg-14.0.6/clang/include/clang/AST -I/usr/local/google/home/xiaofans/workspace/IPRA-exp/build/benchmarks/clang/llvm-project-llvmorg-14.0.6/clang/include -I/usr/local/google/home/xiaofans/workspace/IPRA-exp/build/benchmarks/clang/build.dir/pgolto-full/tools/clang/include -I/usr/local/google/home/xiaofans/workspace/IPRA-exp/build/benchmarks/clang/build.dir/pgolto-full/include -I/usr/local/google/home/xiaofans/workspace/IPRA-exp/build/benchmarks/clang/llvm-project-llvmorg-14.0.6/llvm/include /usr/local/google/home/xiaofans/workspace/IPRA-exp/build/benchmarks/clang/llvm-project-llvmorg-14.0.6/clang/include/clang/AST/../Basic/Attr.td --write-if-changed -o tools/clang/include/clang/AST/AttrNodeTraverse.inc -d tools/clang/include/clang/AST/AttrNodeTraverse.inc.d" \; attach

compare2:
	@tmux new-session -d /bin/sh -c "cd /usr/local/google/home/xiaofans/workspace/IPRA-exp/build/benchmarks/clang/build.dir/pgolto-full-fdoipra && gdb -x /usr/local/google/home/xiaofans/workspace/IPRA-exp/benchmarks/gdbscript --args /usr/local/google/home/xiaofans/workspace/IPRA-exp/build/benchmarks/clang/build.dir/pgolto-full-fdoipra/bin/llvm-tblgen -gen-dag-isel -I /usr/local/google/home/xiaofans/workspace/IPRA-exp/build/benchmarks/clang/llvm-project-llvmorg-14.0.6/llvm/lib/Target/X86 -I/usr/local/google/home/xiaofans/workspace/IPRA-exp/build/benchmarks/clang/build.dir/pgolto-full-fdoipra/include -I/usr/local/google/home/xiaofans/workspace/IPRA-exp/build/benchmarks/clang/llvm-project-llvmorg-14.0.6/llvm/include -I /usr/local/google/home/xiaofans/workspace/IPRA-exp/build/benchmarks/clang/llvm-project-llvmorg-14.0.6/llvm/lib/Target -omit-comments /usr/local/google/home/xiaofans/workspace/IPRA-exp/build/benchmarks/clang/llvm-project-llvmorg-14.0.6/llvm/lib/Target/X86/X86.td --write-if-changed -o lib/Target/X86/X86GenDAGISel.inc -d lib/Target/X86/X86GenDAGISel.inc.d"  \; \
	     split-window -h /bin/sh -c "cd /usr/local/google/home/xiaofans/workspace/IPRA-exp/build/benchmarks/clang/build.dir/pgolto-full && gdb -x /usr/local/google/home/xiaofans/workspace/IPRA-exp/benchmarks/gdbscript --args /usr/local/google/home/xiaofans/workspace/IPRA-exp/build/benchmarks/clang/build.dir/pgolto-full/bin/llvm-tblgen -gen-dag-isel -I /usr/local/google/home/xiaofans/workspace/IPRA-exp/build/benchmarks/clang/llvm-project-llvmorg-14.0.6/llvm/lib/Target/X86 -I/usr/local/google/home/xiaofans/workspace/IPRA-exp/build/benchmarks/clang/build.dir/pgolto-full/include -I/usr/local/google/home/xiaofans/workspace/IPRA-exp/build/benchmarks/clang/llvm-project-llvmorg-14.0.6/llvm/include -I /usr/local/google/home/xiaofans/workspace/IPRA-exp/build/benchmarks/clang/llvm-project-llvmorg-14.0.6/llvm/lib/Target -omit-comments /usr/local/google/home/xiaofans/workspace/IPRA-exp/build/benchmarks/clang/llvm-project-llvmorg-14.0.6/llvm/lib/Target/X86/X86.td --write-if-changed -o lib/Target/X86/X86GenDAGISel.inc -d lib/Target/X86/X86GenDAGISel.inc.d"  \; attach

compare3:
	@tmux new-session -d /bin/sh -c "cd /usr/local/google/home/xiaofans/workspace/IPRA-exp/build/benchmarks/clang/build.dir/pgolto-full-fdoipra/tools/clang/lib/Tooling && gdb -x /usr/local/google/home/xiaofans/workspace/IPRA-exp/benchmarks/gdbscript2 --args  /usr/local/google/home/xiaofans/workspace/IPRA-exp/build/benchmarks/clang/build.dir/pgolto-full-fdoipra/bin/clang-ast-dump --skip-processing=0 -I /usr/local/google/home/xiaofans/workspace/IPRA-exp/build/benchmarks/clang/build.dir/pgolto-full-fdoipra/lib/clang/14.0.6/include -I /usr/local/google/home/xiaofans/workspace/IPRA-exp/build/benchmarks/clang/llvm-project-llvmorg-14.0.6/clang/include -I /usr/local/google/home/xiaofans/workspace/IPRA-exp/build/benchmarks/clang/build.dir/pgolto-full-fdoipra/tools/clang/include -I /usr/local/google/home/xiaofans/workspace/IPRA-exp/build/benchmarks/clang/build.dir/pgolto-full-fdoipra/include -I /usr/local/google/home/xiaofans/workspace/IPRA-exp/build/benchmarks/clang/llvm-project-llvmorg-14.0.6/llvm/include -I /usr/include/c++/11 -I /usr/include/x86_64-linux-gnu/c++/11 -I /usr/include/c++/11/backward -I /usr/local/google/home/xiaofans/workspace/IPRA-exp/install/llvm/lib/clang/15.0.0/include -I /usr/local/include -I /usr/include/x86_64-linux-gnu -I /usr/include --json-output-path /usr/local/google/home/xiaofans/workspace/IPRA-exp/build/benchmarks/clang/build.dir/pgolto-full-fdoipra/tools/clang/lib/Tooling/ASTNodeAPI.json"  \; \
	     split-window -h /bin/sh -c "cd /usr/local/google/home/xiaofans/workspace/IPRA-exp/build/benchmarks/clang/build.dir/pgolto-full/tools/clang/lib/Tooling && gdb -x /usr/local/google/home/xiaofans/workspace/IPRA-exp/benchmarks/gdbscript2 --args  /usr/local/google/home/xiaofans/workspace/IPRA-exp/build/benchmarks/clang/build.dir/pgolto-full/bin/clang-ast-dump --skip-processing=0 -I /usr/local/google/home/xiaofans/workspace/IPRA-exp/build/benchmarks/clang/build.dir/pgolto-full/lib/clang/14.0.6/include -I /usr/local/google/home/xiaofans/workspace/IPRA-exp/build/benchmarks/clang/llvm-project-llvmorg-14.0.6/clang/include -I /usr/local/google/home/xiaofans/workspace/IPRA-exp/build/benchmarks/clang/build.dir/pgolto-full/tools/clang/include -I /usr/local/google/home/xiaofans/workspace/IPRA-exp/build/benchmarks/clang/build.dir/pgolto-full/include -I /usr/local/google/home/xiaofans/workspace/IPRA-exp/build/benchmarks/clang/llvm-project-llvmorg-14.0.6/llvm/include -I /usr/include/c++/11 -I /usr/include/x86_64-linux-gnu/c++/11 -I /usr/include/c++/11/backward -I /usr/local/google/home/xiaofans/workspace/IPRA-exp/install/llvm/lib/clang/15.0.0/include -I /usr/local/include -I /usr/include/x86_64-linux-gnu -I /usr/include --json-output-path /usr/local/google/home/xiaofans/workspace/IPRA-exp/build/benchmarks/clang/build.dir/pgolto-full/tools/clang/lib/Tooling/ASTNodeAPI.json"  \; attach

compare4:
	@tmux new-session -d /bin/sh -c "cd /usr/local/google/home/xiaofans/workspace/IPRA-exp/build/benchmarks/clang/build.dir/pgolto-full-ipra-fdoipra/tools/clang/lib/Tooling && gdb -x /usr/local/google/home/xiaofans/workspace/IPRA-exp/benchmarks/gdbscript3 --args /usr/local/google/home/xiaofans/workspace/IPRA-exp/build/benchmarks/clang/build.dir/pgolto-full-ipra-fdoipra/bin/clang-ast-dump --skip-processing=0 -I /usr/local/google/home/xiaofans/workspace/IPRA-exp/build/benchmarks/clang/build.dir/pgolto-full-ipra-fdoipra/lib/clang/14.0.6/include -I /usr/local/google/home/xiaofans/workspace/IPRA-exp/build/benchmarks/clang/llvm-project-llvmorg-14.0.6/clang/include -I /usr/local/google/home/xiaofans/workspace/IPRA-exp/build/benchmarks/clang/build.dir/pgolto-full-ipra-fdoipra/tools/clang/include -I /usr/local/google/home/xiaofans/workspace/IPRA-exp/build/benchmarks/clang/build.dir/pgolto-full-ipra-fdoipra/include -I /usr/local/google/home/xiaofans/workspace/IPRA-exp/build/benchmarks/clang/llvm-project-llvmorg-14.0.6/llvm/include -I /usr/include/c++/11 -I /usr/include/x86_64-linux-gnu/c++/11 -I /usr/include/c++/11/backward -I /usr/local/google/home/xiaofans/workspace/IPRA-exp/install/llvm/lib/clang/15.0.0/include -I /usr/local/include -I /usr/include/x86_64-linux-gnu -I /usr/include --json-output-path /usr/local/google/home/xiaofans/workspace/IPRA-exp/build/benchmarks/clang/build.dir/pgolto-full-ipra-fdoipra/tools/clang/lib/Tooling/ASTNodeAPI.json"  \; \
	     split-window -h /bin/sh -c "cd /usr/local/google/home/xiaofans/workspace/IPRA-exp/build/benchmarks/clang/build.dir/pgolto-full-ipra/tools/clang/lib/Tooling && gdb -x /usr/local/google/home/xiaofans/workspace/IPRA-exp/benchmarks/gdbscript3-copy --args /usr/local/google/home/xiaofans/workspace/IPRA-exp/build/benchmarks/clang/build.dir/pgolto-full-ipra/bin/clang-ast-dump --skip-processing=0 -I /usr/local/google/home/xiaofans/workspace/IPRA-exp/build/benchmarks/clang/build.dir/pgolto-full-ipra/lib/clang/14.0.6/include -I /usr/local/google/home/xiaofans/workspace/IPRA-exp/build/benchmarks/clang/llvm-project-llvmorg-14.0.6/clang/include -I /usr/local/google/home/xiaofans/workspace/IPRA-exp/build/benchmarks/clang/build.dir/pgolto-full-ipra/tools/clang/include -I /usr/local/google/home/xiaofans/workspace/IPRA-exp/build/benchmarks/clang/build.dir/pgolto-full-ipra/include -I /usr/local/google/home/xiaofans/workspace/IPRA-exp/build/benchmarks/clang/llvm-project-llvmorg-14.0.6/llvm/include -I /usr/include/c++/11 -I /usr/include/x86_64-linux-gnu/c++/11 -I /usr/include/c++/11/backward -I /usr/local/google/home/xiaofans/workspace/IPRA-exp/install/llvm/lib/clang/15.0.0/include -I /usr/local/include -I /usr/include/x86_64-linux-gnu -I /usr/include --json-output-path /usr/local/google/home/xiaofans/workspace/IPRA-exp/build/benchmarks/clang/build.dir/pgolto-full-ipra/tools/clang/lib/Tooling/ASTNodeAPI.json"  \; attach

printall:
	cd /usr/local/google/home/xiaofans/workspace/IPRA-exp/build/benchmarks/clang/build.dir/pgolto-full-ipra-fdoipra/ && /usr/local/google/home/xiaofans/workspace/IPRA-exp/install/llvm/bin/clang++ -Wl,-mllvm -Wl,-print-after-all -Wl,-mllvm -Wl,-filter-print-funcs=_ZN5clang4Sema21InstantiatingTemplateC2ERS0_NS0_20CodeSynthesisContext13SynthesisKindENS_14SourceLocationENS_11SourceRangeEPNS_4DeclEPNS_9NamedDeclEN4llvm8ArrayRefINS_16TemplateArgumentEEEPNS_4sema21TemplateDeductionInfoE  -fuse-ld=lld -fPIC -fno-optimize-sibling-calls -fvisibility-inlines-hidden -Wall -Wextra -Wno-unused-parameter -Wwrite-strings -Wcast-qual -Wmissing-field-initializers -pedantic -Wno-long-long -Wno-noexcept-type -Wnon-virtual-dtor -Wdelete-non-virtual-dtor -Wsuggest-override -Wno-comment -fdiagnostics-color -fprofile-instr-use=/usr/local/google/home/xiaofans/workspace/IPRA-exp/build/benchmarks/clang/build.dir/instrumented/profiles/clang.profdata -flto=full -fno-common -Woverloaded-virtual -O3 -DNDEBUG -fuse-ld=lld -Wl,-mllvm -Wl,-fdo-ipra -Wl,-Bsymbolic-non-weak-functions -fuse-ld=lld -Wl,--color-diagnostics -fprofile-instr-use=/usr/local/google/home/xiaofans/workspace/IPRA-exp/build/benchmarks/clang/build.dir/instrumented/profiles/clang.profdata -flto=full -Wl,--gc-sections tools/clang/lib/Tooling/DumpTool/CMakeFiles/clang-ast-dump.dir/ASTSrcLocProcessor.cpp.o tools/clang/lib/Tooling/DumpTool/CMakeFiles/clang-ast-dump.dir/ClangSrcLocDump.cpp.o -o bin/clang-ast-dump -Wl,-rpath,$ORIGIN/../lib lib/libLLVMOption.a lib/libLLVMFrontendOpenMP.a lib/libLLVMSupport.a -lpthread lib/libclangAST.a lib/libclangASTMatchers.a lib/libclangBasic.a lib/libclangDriver.a lib/libclangFrontend.a lib/libclangSerialization.a lib/libclangToolingCore.a lib/libclangDriver.a lib/libLLVMOption.a lib/libclangParse.a lib/libclangSema.a lib/libclangEdit.a lib/libclangAnalysis.a lib/libclangASTMatchers.a lib/libclangAST.a lib/libLLVMFrontendOpenMP.a lib/libLLVMScalarOpts.a lib/libLLVMAggressiveInstCombine.a lib/libLLVMInstCombine.a lib/libLLVMTransformUtils.a lib/libLLVMAnalysis.a lib/libLLVMProfileData.a lib/libLLVMDebugInfoDWARF.a lib/libLLVMObject.a lib/libLLVMMCParser.a lib/libLLVMMC.a lib/libLLVMDebugInfoCodeView.a lib/libLLVMTextAPI.a lib/libLLVMBitReader.a lib/libLLVMCore.a lib/libLLVMBinaryFormat.a lib/libLLVMRemarks.a lib/libLLVMBitstreamReader.a lib/libclangRewrite.a lib/libclangLex.a lib/libclangBasic.a lib/libLLVMSupport.a -lrt -ldl -lpthread -lm /usr/lib/x86_64-linux-gnu/libz.so /usr/lib/x86_64-linux-gnu/libtinfo.so lib/libLLVMDemangle.a


