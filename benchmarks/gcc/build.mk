mkfile_path := $(dir $(abspath $(lastword $(MAKEFILE_LIST))))
PWD := $(shell pwd)
GCC_VERSION=gcc-10.4.0
INSTRUMENTED_PROF=$(PWD)/build.dir/instrumented/profiles


common_compiler_flags :=-fuse-ld=lld -fno-optimize-sibling-calls -mllvm -fast-isel=false -fsplit-machine-functions
common_linker_flags :=-fuse-ld=lld -fno-optimize-sibling-calls -Wl,-mllvm -Wl,-fast-isel=false -fsplit-machine-functions

gen_compiler_flags =CFLAGS=$(1) CXXFLAGS=$(1)
gen_linker_flags   =LDFLAGS=$(1)
gen_build_flags =$(call gen_compiler_flags,"$(common_compiler_flags) $(1)") $(call gen_linker_flags,"$(common_linker_flags) $(2)")
COMMA := ,

# pgolto pgolto-ipra pgolto-fdoipra 
# pgolto.bench pgolto-ipra.bench pgolto-fdoipra.bench
all:  pgolto-full pgolto-full-ipra pgolto-full-fdoipra pgolto-full-fdoipra2 pgolto-full-fdoipra3 
bench:   pgolto-full.bench pgolto-full-ipra.bench pgolto-full-fdoipra.bench pgolto-full-fdoipra2.bench pgolto-full-fdoipra3.bench
define build_gcc
	rm -f /tmp/count-push-pop.txt 
	touch /tmp/count-push-pop.txt
    mkdir -p build.dir/$(1)
	mkdir -p install.dir/$(1)
	cd build.dir/$(1) && unset C_INCLUDE_PATH CPLUS_INCLUDE_PATH CFLAGS CXXFLAGS && \
 		../../gcc-releases-$(GCC_VERSION)/configure -v \
		--build=x86_64-linux-gnu \
		--host=x86_64-linux-gnu \
		--target=x86_64-linux-gnu \
		--enable-offload-target=x86_64-linux-gnu \
		--prefix=$(PWD)/install.dir/$(1) \
		--enable-checking=release \
		--enable-languages=c \
		--disable-multilib \
		--disable-intermodule \
		--disable-bootstrap \
		--disable-coverage \
		--disable-libvtv \
		--disable-libssp \
		--disable-libgomp \
		--disable-libquadmath \
		--disable-build-format-warnings \
		CC=$(NCC) \
		CXX=$(NCXX) \
		$(2)
	cd build.dir/$(1) && CLANG_PROXY_FOCUS=cc1 CLANG_PROXY_ARGS="-Wl,-mllvm -Wl,-count-push-pop" time -o time.log make all-gcc -j $(shell nproc) > build.log
	echo "---------$(1)---------" >> ../gcc.output
	cat /tmp/count-push-pop.txt | $(COUNTSUM) >> ../gcc.output 
	echo "---------$(1)---------" >> ../gcc.raw
	cat /tmp/count-push-pop.txt >> ../gcc.raw 
	touch $(1)
endef

define run_bench
	mkdir -p build.dir/bench/$(1)
	cd build.dir/bench/$(1) && cmake -G Ninja $(PWD)/../dparser/dparser-master \
		-DCMAKE_BUILD_TYPE=RelWithDebInfo \
		-DCMAKE_C_FLAGS="-B$(2) -fPIE" \
		-DCMAKE_C_COMPILER=$(2)/xgcc \
		-DCMAKE_LINKER=gcc \
		-DCMAKE_USER_MAKE_RULES_OVERRIDE=$(mkfile_path)makerules.cmake \
		-DCMAKE_BUILD_WITH_INSTALL_RPATH=ON
	cd build.dir/bench/$(1) && (ninja -t commands | head -100 > $(PWD)/build.dir/bench/$(1)/perf_commands.sh)
	cd build.dir/bench/$(1) && chmod +x ./perf_commands.sh
endef 

instrumented: gcc-releases-$(GCC_VERSION)
	$(call build_gcc,$@,$(call gen_build_flags,-fprofile-generate=$(INSTRUMENTED_PROF),-fprofile-generate=$(INSTRUMENTED_PROF)))

pgolto: $(INSTRUMENTED_PROF)/gcc.profdata
	$(call build_gcc,$@,$(call gen_build_flags,-flto=thin -fprofile-use=$(INSTRUMENTED_PROF)/gcc.profdata,-flto=thin -fprofile-use=$(INSTRUMENTED_PROF)/gcc.profdata))

pgolto-ipra: $(INSTRUMENTED_PROF)/gcc.profdata
	$(call build_gcc,$@,$(call gen_build_flags,-flto=thin -fprofile-use=$(INSTRUMENTED_PROF)/gcc.profdata,-flto=thin -fprofile-use=$(INSTRUMENTED_PROF)/gcc.profdata -Wl$(COMMA)-mllvm -Wl$(COMMA)-enable-ipra -Wl$(COMMA)-Bsymbolic-non-weak-functions))

pgolto-fdoipra: $(INSTRUMENTED_PROF)/gcc.profdata
	$(call build_gcc,$@,$(call gen_build_flags,-flto=thin -fprofile-use=$(INSTRUMENTED_PROF)/gcc.profdata,-flto=thin -fprofile-use=$(INSTRUMENTED_PROF)/gcc.profdata -Wl$(COMMA)-mllvm -Wl$(COMMA)-fdo-ipra -Wl$(COMMA)-Bsymbolic-non-weak-functions))

pgolto-full: $(INSTRUMENTED_PROF)/gcc.profdata
	$(call build_gcc,$@,$(call gen_build_flags,-g -flto=full -fprofile-use=$(INSTRUMENTED_PROF)/gcc.profdata,-flto=full -fprofile-use=$(INSTRUMENTED_PROF)/gcc.profdata -Wl$(COMMA)-Bsymbolic-non-weak-functions))

pgolto-full-ipra: $(INSTRUMENTED_PROF)/gcc.profdata
	$(call build_gcc,$@,$(call gen_build_flags,-g -flto=full -fprofile-use=$(INSTRUMENTED_PROF)/gcc.profdata,-flto=full -fprofile-use=$(INSTRUMENTED_PROF)/gcc.profdata -Wl$(COMMA)-mllvm -Wl$(COMMA)-enable-ipra -Wl$(COMMA)-Bsymbolic-non-weak-functions))

pgolto-full-fdoipra: $(INSTRUMENTED_PROF)/gcc.profdata
	$(call build_gcc,$@,$(call gen_build_flags,-g -flto=full -fprofile-use=$(INSTRUMENTED_PROF)/gcc.profdata,-flto=full -fprofile-use=$(INSTRUMENTED_PROF)/gcc.profdata -Wl$(COMMA)-mllvm -Wl$(COMMA)-fdo-ipra -Wl$(COMMA)-Bsymbolic-non-weak-functions))

pgolto-full-fdoipra2: $(INSTRUMENTED_PROF)/gcc.profdata
	$(call build_gcc,$@,$(call gen_build_flags,-g -flto=full -fprofile-use=$(INSTRUMENTED_PROF)/gcc.profdata,-flto=full -fprofile-use=$(INSTRUMENTED_PROF)/gcc.profdata -Wl$(COMMA)-mllvm -Wl$(COMMA)-fdo-ipra -Wl$(COMMA)-mllvm -Wl$(COMMA)-fdoipra-ch=1 -Wl$(COMMA)-Bsymbolic-non-weak-functions))

pgolto-full-fdoipra3: $(INSTRUMENTED_PROF)/gcc.profdata
	$(call build_gcc,$@,$(call gen_build_flags,-g -flto=full -fprofile-use=$(INSTRUMENTED_PROF)/gcc.profdata,-flto=full -fprofile-use=$(INSTRUMENTED_PROF)/gcc.profdata -Wl$(COMMA)-mllvm -Wl$(COMMA)-fdo-ipra -Wl$(COMMA)-mllvm -Wl$(COMMA)-fdoipra-ch=1 -Wl$(COMMA)-mllvm -Wl$(COMMA)-fdoipra-hc=1 -Wl$(COMMA)-Bsymbolic-non-weak-functions))


gcc-releases-$(GCC_VERSION):
	wget https://github.com/gcc-mirror/gcc/archive/refs/tags/releases/$(GCC_VERSION).zip && unzip $(GCC_VERSION) && rm -f $(GCC_VERSION).zip
	cd gcc-releases-$(GCC_VERSION) && contrib/download_prerequisites
	cd gcc-releases-$(GCC_VERSION) && find . -type f -name configure -exec sed -i 's/\$$CC -print-multi-os-directory/gcc -print-multi-os-directory/g' {} \;
	cd gcc-releases-$(GCC_VERSION) && find . -type f -name configure -exec sed -i 's/\$$CXX -print-multi-os-directory/gcc -print-multi-os-directory/g' {} \;
	cd gcc-releases-$(GCC_VERSION) && find . -type f -name configure -exec sed -i 's/\$$CC \$$CPPFLAGS \$$CFLAGS \$$LDFLAGS -print-multi-os-directory/gcc -print-multi-os-directory/g' {} \;
	cd ../../.. &&  make benchmarks/dparser/dparser-master

$(INSTRUMENTED_PROF)/gcc.profdata:  instrumented
	$(call run_bench,instrumented,$(PWD)/build.dir/instrumented/gcc)
	cd build.dir/bench/instrumented && ./perf_commands.sh
	cd $(INSTRUMENTED_PROF) && $(LLVM_BIN)/llvm-profdata merge -output=gcc.profdata *

%.bench: %
	$(call run_bench,$(basename $@),$(PWD)/build.dir/$(basename $@)/gcc)
	cd build.dir/bench/$(basename $@) && perf stat -o $(basename $@).bench -r5 -- taskset -c 1 bash ./perf_commands.sh


dump-only:
	cd build.dir/pgolto-full-fdoipra/gcc && /usr/local/google/home/xiaofans/workspace/IPRA-exp/install/llvm/bin/clang-proxy++   -fuse-ld=lld -g -flto=full -fprofile-use=/usr/local/google/home/xiaofans/workspace/IPRA-exp/build/benchmarks/gcc/build.dir/instrumented/profiles/gcc.profdata -DIN_GCC    -fno-strict-aliasing -fno-exceptions -fno-rtti -fasynchronous-unwind-tables -W -Wall -Wno-narrowing -Wwrite-strings -Wcast-qual -Wno-error=format-diag -Wno-format -Wmissing-format-attribute -Woverloaded-virtual -pedantic -Wno-long-long -Wno-variadic-macros -Wno-overlength-strings   -DHAVE_CONFIG_H  -DGENERATOR_FILE -fuse-ld=lld -flto=full -fprofile-use=/usr/local/google/home/xiaofans/workspace/IPRA-exp/build/benchmarks/gcc/build.dir/instrumented/profiles/gcc.profdata -Wl,-mllvm -Wl,-fdo-ipra -Wl,-mllvm -Wl,-print-isel-input -Wl,-mllvm -Wl,-print-after-isel -Wl,-mllvm -Wl,-filter-print-funcs=_Z16yy_create_bufferP8_IO_FILEi  -Wl,-Bsymbolic-non-weak-functions -o build/gengtype     build/gengtype.o build/errors.o build/gengtype-lex.o build/gengtype-parse.o build/gengtype-state.o build/version.o ../build-x86_64-linux-gnu/libiberty/libiberty.a > dump-fdoipra.txt
	cd build.dir/pgolto-full-fdoipra/gcc && /usr/local/google/home/xiaofans/workspace/IPRA-exp/install/llvm/bin/clang-proxy++   -fuse-ld=lld -g -flto=full -fprofile-use=/usr/local/google/home/xiaofans/workspace/IPRA-exp/build/benchmarks/gcc/build.dir/instrumented/profiles/gcc.profdata -DIN_GCC    -fno-strict-aliasing -fno-exceptions -fno-rtti -fasynchronous-unwind-tables -W -Wall -Wno-narrowing -Wwrite-strings -Wcast-qual -Wno-error=format-diag -Wno-format -Wmissing-format-attribute -Woverloaded-virtual -pedantic -Wno-long-long -Wno-variadic-macros -Wno-overlength-strings   -DHAVE_CONFIG_H  -DGENERATOR_FILE -fuse-ld=lld -flto=full -fprofile-use=/usr/local/google/home/xiaofans/workspace/IPRA-exp/build/benchmarks/gcc/build.dir/instrumented/profiles/gcc.profdata                          -Wl,-mllvm -Wl,-print-isel-input -Wl,-mllvm -Wl,-print-after-isel -Wl,-mllvm -Wl,-filter-print-funcs=_Z16yy_create_bufferP8_IO_FILEi  -Wl,-Bsymbolic-non-weak-functions -o build/gengtype     build/gengtype.o build/errors.o build/gengtype-lex.o build/gengtype-parse.o build/gengtype-state.o build/version.o ../build-x86_64-linux-gnu/libiberty/libiberty.a > dump-normal.txt


dump:
	cd build.dir/pgolto-full-fdoipra/gcc && /usr/local/google/home/xiaofans/workspace/IPRA-exp/install/llvm/bin/clang-proxy++   -fuse-ld=lld -g -flto=full -fprofile-use=/usr/local/google/home/xiaofans/workspace/IPRA-exp/build/benchmarks/gcc/build.dir/instrumented/profiles/gcc.profdata -DIN_GCC    -fno-strict-aliasing -fno-exceptions -fno-rtti -fasynchronous-unwind-tables -W -Wall -Wno-narrowing -Wwrite-strings -Wcast-qual -Wno-error=format-diag -Wno-format -Wmissing-format-attribute -Woverloaded-virtual -pedantic -Wno-long-long -Wno-variadic-macros -Wno-overlength-strings   -DHAVE_CONFIG_H  -DGENERATOR_FILE -fuse-ld=lld -flto=full -fprofile-use=/usr/local/google/home/xiaofans/workspace/IPRA-exp/build/benchmarks/gcc/build.dir/instrumented/profiles/gcc.profdata -Wl,-mllvm -Wl,-fdo-ipra -Wl,-mllvm -Wl,-print-isel-input -Wl,-mllvm -Wl,-print-after-isel -Wl,-Bsymbolic-non-weak-functions -o build/gengtype     build/gengtype.o build/errors.o build/gengtype-lex.o build/gengtype-parse.o build/gengtype-state.o build/version.o ../build-x86_64-linux-gnu/libiberty/libiberty.a > dump-fdoipra.txt
	cd build.dir/pgolto-full-fdoipra/gcc && /usr/local/google/home/xiaofans/workspace/IPRA-exp/install/llvm/bin/clang-proxy++   -fuse-ld=lld -g -flto=full -fprofile-use=/usr/local/google/home/xiaofans/workspace/IPRA-exp/build/benchmarks/gcc/build.dir/instrumented/profiles/gcc.profdata -DIN_GCC    -fno-strict-aliasing -fno-exceptions -fno-rtti -fasynchronous-unwind-tables -W -Wall -Wno-narrowing -Wwrite-strings -Wcast-qual -Wno-error=format-diag -Wno-format -Wmissing-format-attribute -Woverloaded-virtual -pedantic -Wno-long-long -Wno-variadic-macros -Wno-overlength-strings   -DHAVE_CONFIG_H  -DGENERATOR_FILE -fuse-ld=lld -flto=full -fprofile-use=/usr/local/google/home/xiaofans/workspace/IPRA-exp/build/benchmarks/gcc/build.dir/instrumented/profiles/gcc.profdata                          -Wl,-mllvm -Wl,-print-isel-input -Wl,-mllvm -Wl,-print-after-isel -Wl,-Bsymbolic-non-weak-functions -o build/gengtype     build/gengtype.o build/errors.o build/gengtype-lex.o build/gengtype-parse.o build/gengtype-state.o build/version.o ../build-x86_64-linux-gnu/libiberty/libiberty.a > dump-normal.txt


output:
	cd build.dir/pgolto-full-fdoipra/gcc &&  /usr/local/google/home/xiaofans/workspace/IPRA-exp/install/llvm/bin/clang-proxy++   -fuse-ld=lld -g -flto=full -fprofile-use=/usr/local/google/home/xiaofans/workspace/IPRA-exp/build/benchmarks/gcc/build.dir/instrumented/profiles/gcc.profdata -DIN_GCC    -fno-strict-aliasing -fno-exceptions -fno-rtti -fasynchronous-unwind-tables -W -Wall -Wno-narrowing -Wwrite-strings -Wcast-qual -Wno-error=format-diag -Wno-format -Wmissing-format-attribute -Woverloaded-virtual -pedantic -Wno-long-long -Wno-variadic-macros -Wno-overlength-strings   -DHAVE_CONFIG_H  -DGENERATOR_FILE -fuse-ld=lld -flto=full -fprofile-use=/usr/local/google/home/xiaofans/workspace/IPRA-exp/build/benchmarks/gcc/build.dir/instrumented/profiles/gcc.profdata -Wl,-mllvm -Wl,-fdo-ipra -Wl,-mllvm -Wl,-print-after-all -Wl,-mllvm -Wl,-filter-print-funcs=_Z16yy_create_bufferP8_IO_FILEi  -Wl,-Bsymbolic-non-weak-functions -o build/gengtype     build/gengtype.o build/errors.o build/gengtype-lex.o build/gengtype-parse.o build/gengtype-state.o build/version.o ../build-x86_64-linux-gnu/libiberty/libiberty.a > output-fdoipra.txt
	cd build.dir/pgolto-full-fdoipra/gcc &&  /usr/local/google/home/xiaofans/workspace/IPRA-exp/install/llvm/bin/clang-proxy++   -fuse-ld=lld -g -flto=full -fprofile-use=/usr/local/google/home/xiaofans/workspace/IPRA-exp/build/benchmarks/gcc/build.dir/instrumented/profiles/gcc.profdata -DIN_GCC    -fno-strict-aliasing -fno-exceptions -fno-rtti -fasynchronous-unwind-tables -W -Wall -Wno-narrowing -Wwrite-strings -Wcast-qual -Wno-error=format-diag -Wno-format -Wmissing-format-attribute -Woverloaded-virtual -pedantic -Wno-long-long -Wno-variadic-macros -Wno-overlength-strings   -DHAVE_CONFIG_H  -DGENERATOR_FILE -fuse-ld=lld -flto=full -fprofile-use=/usr/local/google/home/xiaofans/workspace/IPRA-exp/build/benchmarks/gcc/build.dir/instrumented/profiles/gcc.profdata -Wl,-mllvm -Wl,-print-after-all -Wl,-mllvm -Wl,-filter-print-funcs=_Z16yy_create_bufferP8_IO_FILEi  -Wl,-Bsymbolic-non-weak-functions -o build/gengtype     build/gengtype.o build/errors.o build/gengtype-lex.o build/gengtype-parse.o build/gengtype-state.o build/version.o ../build-x86_64-linux-gnu/libiberty/libiberty.a > output-normal.txt


debug:
	cd build.dir/pgolto-full-fdoipra/gcc &&  /usr/local/google/home/xiaofans/workspace/IPRA-exp/install/llvm/bin/clang-proxy++   -fuse-ld=lld -g -flto=full -fprofile-use=/usr/local/google/home/xiaofans/workspace/IPRA-exp/build/benchmarks/gcc/build.dir/instrumented/profiles/gcc.profdata -DIN_GCC    -fno-strict-aliasing -fno-exceptions -fno-rtti -fasynchronous-unwind-tables -W -Wall -Wno-narrowing -Wwrite-strings -Wcast-qual -Wno-error=format-diag -Wno-format -Wmissing-format-attribute -Woverloaded-virtual -pedantic -Wno-long-long -Wno-variadic-macros -Wno-overlength-strings   -DHAVE_CONFIG_H  -DGENERATOR_FILE -fuse-ld=lld -flto=full -fprofile-use=/usr/local/google/home/xiaofans/workspace/IPRA-exp/build/benchmarks/gcc/build.dir/instrumented/profiles/gcc.profdata -Wl,-mllvm -Wl,-fdo-ipra -Wl,-mllvm -Wl,-debug-only=isel -Wl,-mllvm -Wl,-filter-print-funcs=_Z16yy_create_bufferP8_IO_FILEi  -Wl,-Bsymbolic-non-weak-functions -o build/gengtype     build/gengtype.o build/errors.o build/gengtype-lex.o build/gengtype-parse.o build/gengtype-state.o build/version.o ../build-x86_64-linux-gnu/libiberty/libiberty.a > debug-fdoipra.txt
	cd build.dir/pgolto-full-fdoipra/gcc &&  /usr/local/google/home/xiaofans/workspace/IPRA-exp/install/llvm/bin/clang-proxy++   -fuse-ld=lld -g -flto=full -fprofile-use=/usr/local/google/home/xiaofans/workspace/IPRA-exp/build/benchmarks/gcc/build.dir/instrumented/profiles/gcc.profdata -DIN_GCC    -fno-strict-aliasing -fno-exceptions -fno-rtti -fasynchronous-unwind-tables -W -Wall -Wno-narrowing -Wwrite-strings -Wcast-qual -Wno-error=format-diag -Wno-format -Wmissing-format-attribute -Woverloaded-virtual -pedantic -Wno-long-long -Wno-variadic-macros -Wno-overlength-strings   -DHAVE_CONFIG_H  -DGENERATOR_FILE -fuse-ld=lld -flto=full -fprofile-use=/usr/local/google/home/xiaofans/workspace/IPRA-exp/build/benchmarks/gcc/build.dir/instrumented/profiles/gcc.profdata -Wl,-mllvm -Wl,-debug-only=isel -Wl,-mllvm -Wl,-filter-print-funcs=_Z16yy_create_bufferP8_IO_FILEi  -Wl,-Bsymbolic-non-weak-functions -o build/gengtype     build/gengtype.o build/errors.o build/gengtype-lex.o build/gengtype-parse.o build/gengtype-state.o build/version.o ../build-x86_64-linux-gnu/libiberty/libiberty.a > debug-normal.txt

run:
	cd build.dir/pgolto-full-fdoipra/gcc &&  /usr/local/google/home/xiaofans/workspace/IPRA-exp/install/llvm/bin/clang-proxy++   -fuse-ld=lld -g -flto=full -fprofile-use=/usr/local/google/home/xiaofans/workspace/IPRA-exp/build/benchmarks/gcc/build.dir/instrumented/profiles/gcc.profdata -DIN_GCC    -fno-strict-aliasing -fno-exceptions -fno-rtti -fasynchronous-unwind-tables -W -Wall -Wno-narrowing -Wwrite-strings -Wcast-qual -Wno-error=format-diag -Wno-format -Wmissing-format-attribute -Woverloaded-virtual -pedantic -Wno-long-long -Wno-variadic-macros -Wno-overlength-strings   -DHAVE_CONFIG_H  -DGENERATOR_FILE -fuse-ld=lld -flto=full -fprofile-use=/usr/local/google/home/xiaofans/workspace/IPRA-exp/build/benchmarks/gcc/build.dir/instrumented/profiles/gcc.profdata -Wl,-mllvm -Wl,-fdo-ipra -Wl,-mllvm -Wl,-fast-isel=false  -Wl,-Bsymbolic-non-weak-functions -o build/gengtype     build/gengtype.o build/errors.o build/gengtype-lex.o build/gengtype-parse.o build/gengtype-state.o build/version.o ../build-x86_64-linux-gnu/libiberty/libiberty.a