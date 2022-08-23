mkfile_path := $(dir $(abspath $(lastword $(MAKEFILE_LIST))))
PWD := $(shell pwd)
GCC_VERSION=gcc-10.4.0
INSTRUMENTED_PROF=$(PWD)/build.dir/instrumented/profiles


common_compiler_flags :=-fuse-ld=lld
common_linker_flags :=-fuse-ld=lld

gen_compiler_flags =CFLAGS=$(1) CXXFLAGS=$(1)
gen_linker_flags   =LDFLAGS=$(1)
gen_build_flags =$(call gen_compiler_flags,"$(common_compiler_flags) $(1)") $(call gen_linker_flags,"$(common_linker_flags) $(2)")
COMMA := ,

all:  pgolto pgolto-ipra pgolto-fdoipra pgolto-full pgolto-full-ipra pgolto-full-fdoipra 
bench:  pgolto.bench pgolto-ipra.bench pgolto-fdoipra.bench pgolto-full.bench pgolto-full-ipra.bench pgolto-full-fdoipra.bench
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
	$(call build_gcc,$@,$(call gen_build_flags,-flto=full -fprofile-use=$(INSTRUMENTED_PROF)/gcc.profdata,-flto=full -fprofile-use=$(INSTRUMENTED_PROF)/gcc.profdata -Wl$(COMMA)-Bsymbolic-non-weak-functions))

pgolto-full-ipra: $(INSTRUMENTED_PROF)/gcc.profdata
	$(call build_gcc,$@,$(call gen_build_flags,-flto=full -fprofile-use=$(INSTRUMENTED_PROF)/gcc.profdata,-flto=full -fprofile-use=$(INSTRUMENTED_PROF)/gcc.profdata -Wl$(COMMA)-mllvm -Wl$(COMMA)-enable-ipra -Wl$(COMMA)-Bsymbolic-non-weak-functions))

pgolto-full-fdoipra: $(INSTRUMENTED_PROF)/gcc.profdata
	$(call build_gcc,$@,$(call gen_build_flags,-flto=full -fprofile-use=$(INSTRUMENTED_PROF)/gcc.profdata,-flto=full -fprofile-use=$(INSTRUMENTED_PROF)/gcc.profdata -Wl$(COMMA)-mllvm -Wl$(COMMA)-fdo-ipra -Wl$(COMMA)-Bsymbolic-non-weak-functions))

gcc-releases-$(GCC_VERSION):
	wget https://github.com/gcc-mirror/gcc/archive/refs/tags/releases/$(GCC_VERSION).zip && unzip $(GCC_VERSION) && rm -f $(GCC_VERSION).zip
	cd gcc-releases-$(GCC_VERSION) && contrib/download_prerequisites
	cd gcc-releases-$(GCC_VERSION) && find . -type f -name configure -exec sed -i 's/\$$CC -print-multi-os-directory/gcc -print-multi-os-directory/g' {} \;
	cd gcc-releases-$(GCC_VERSION) && find . -type f -name configure -exec sed -i 's/\$$CXX -print-multi-os-directory/gcc -print-multi-os-directory/g' {} \;
	cd gcc-releases-$(GCC_VERSION) && find . -type f -name configure -exec sed -i 's/\$$CC \$$CPPFLAGS \$$CFLAGS \$$LDFLAGS -print-multi-os-directory/gcc -print-multi-os-directory/g' {} \;
	make benchmarks/dparser/dparser-master

$(INSTRUMENTED_PROF)/gcc.profdata:  instrumented
	$(call run_bench,instrumented,$(PWD)/build.dir/instrumented/gcc)
	cd build.dir/bench/instrumented && ./perf_commands.sh
	cd $(INSTRUMENTED_PROF) && $(LLVM_BIN)/llvm-profdata merge -output=gcc.profdata *

%.bench: %
	$(call run_bench,$(basename $@),$(PWD)/build.dir/$(basename $@)/gcc)
	cd build.dir/bench/$(basename $@) && perf stat -o $(basename $@).bench -r5 -- taskset -c 1 bash ./perf_commands.sh