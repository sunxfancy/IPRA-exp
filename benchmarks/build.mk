
benchmarks: benchmarks/mysql benchmarks/clang

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
	cat /tmp/count-push-pop.txt >> build/benchmarks/mysql.output 
endef

benchmarks/mysql: build/benchmarks/mysql-experiment/packages/mysql-boost-8.0.30.tar.gz
	rm -f build/benchmarks/mysql.output
	$(call save_to_output,pgolto-mysql)
	$(call save_to_output,pgolto-ipra-mysql)
	$(call save_to_output,pgolto-full-ipra-mysql)
	$(call save_to_output,pgolto-full-fdoipra-mysql)
	$(call save_to_output,pgolto-full-ipra-fdoipra-mysql)
	
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
