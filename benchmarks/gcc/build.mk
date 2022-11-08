mkfile_path := $(dir $(abspath $(lastword $(MAKEFILE_LIST))))
BENCHMARK=gcc
include $(mkfile_path)../common.mk
GCC_VERSION=gcc-10.4.0

gen_compiler_flags =CFLAGS=$(1) CXXFLAGS=$(1)
gen_linker_flags   =LDFLAGS=$(1)
COMMA := ,

MAIN_BIN = gcc/cc1
BUILD_ACTION=build_gcc
BUILD_TARGET=

define switch_binary
	rm -f $(INSTALL_DIR)/libexec/gcc/x86_64-linux-gnu/10.4.0/cc1
	ln -s $(PWD)/$(1)/$(MAIN_BIN)$(2) $(INSTALL_DIR)/libexec/gcc/x86_64-linux-gnu/10.4.0/cc1
endef

define build_gcc
	rm -f $(PWD)/$(1).count-push-pop 
	touch $(PWD)/$(1).count-push-pop
	mkdir -p build.dir/$(1)
	mkdir -p install.dir/$(1)
	cd build.dir/$(1) && unset C_INCLUDE_PATH CPLUS_INCLUDE_PATH CFLAGS CXXFLAGS && \
 		../../gcc-releases-$(GCC_VERSION)/configure -v \
		--build=x86_64-linux-gnu \
		--host=x86_64-linux-gnu \
		--target=x86_64-linux-gnu \
		--enable-offload-target=x86_64-linux-gnu \
		--prefix=$(PWD)/install.dir \
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
	cd build.dir/$(1) && CLANG_PROXY_FOCUS=cc1 \
		CLANG_PROXY_ARGS="$(4)" CLANG_PROXY_VAR="$(5)" \
		time -o time.log make $(3) -j $(shell nproc) > build.log
	if [ ! -d "$(INSTALL_DIR)/libexec" ]; then \
		cd $(BUILD_DIR)/$(1) && make all-gcc -j $(shell nproc) -v >>  $(PWD)/$(1)/build.log; \
	fi 
	echo "---------$(1)---------" >> ../gcc.raw
	cat $(PWD)/$(1).count-push-pop.txt >> ../gcc.raw 
	echo "---------$(1)---------" >> ../gcc.output
	cat $(PWD)/$(1).count-push-pop.txt | $(COUNTSUM) >> ../gcc.output 
	
	$(call mv_binary,$(1))
	$(call switch_binary,$(1))
	touch $@
endef

define run_bench
	mkdir -p build.dir/bench.dir
	cd build.dir/bench.dir && cmake -G Ninja $(PWD)/../dparser/dparser-master \
		-DCMAKE_BUILD_TYPE=RelWithDebInfo \
		-DCMAKE_C_FLAGS="-B$(2) -fPIE" \
		-DCMAKE_C_COMPILER=$(2)/xgcc \
		-DCMAKE_LINKER=gcc \
		-DCMAKE_USER_MAKE_RULES_OVERRIDE=$(mkfile_path)makerules.cmake \
		-DCMAKE_BUILD_WITH_INSTALL_RPATH=ON
	cd build.dir/bench.dir && (ninja -t commands dparse | head -100 > $(PWD)/build.dir/bench.dir/perf_commands.sh)
	cd build.dir/bench.dir && chmod +x ./perf_commands.sh
endef 


define copy_to_server
	cd bench.dir && $(RUN_FOR_REMOTE) sed 's/\/[^ ]*IPRA-exp/\/tmp\/IPRA-exp/g; s/^:.*://g;' ./perf_commands.sh > ./perf_commands-copy.sh && \
				sed ' s/\.cpp\.o -c/\.cpp\.i -E/g; s/^:.*://g;' ./perf_commands.sh > ./preprocess.sh &&  \
				 $(RUN_FOR_REMOTE) $(INSTALL_PATH)/process_cmd < ./perf_commands-copy.sh > ./perf_commands_remote.sh && \
				 $(RUN_FOR_REMOTE) bash ./preprocess.sh
	$(COPY_TO_REMOTE) $(PWD)/bench.dir/
	$(COPY_TO_REMOTE) $(PWD)/build.dir/$(1)/$(MAIN_BIN)$(2)
	$(COPY_TO_REMOTE) $(PWD)/install.dir/bin/clang-14
	$(COPY_TO_REMOTE) $(PWD)/install.dir/bin/clang
	$(COPY_TO_REMOTE) $(PWD)/install.dir/bin/clang++
	$(COPY_TO_REMOTE) $(INSTALL_PATH)/sub
endef



define gen_perfdata

$(1)$(2).perfdata: $(1) 
	$(call switch_binary,$(1),$(2))
	$(call copy_to_server,$(1),$(2))
	cd bench.dir && $(PERF) record -e cycles:u -j any,u -o ../$$@ -- $(TASKSET) bash ./perf_commands_remote.sh
	$(COPY_BACK) $(PWD)/$$@
	$(RUN_ON_REMOTE) rm -rf $(PWD)/bench.dir/

endef

define gen_bench

$(1)$(2).bench: $(1)
	$(call switch_binary,$(1),$(2))
	$(call copy_to_server,$(1),$(2))
	cd bench.dir && $(PERF) stat $(PERF_EVENTS) -o ../$$@ -r5 -- $(TASKSET) bash ./perf_commands_remote.sh
	$(COPY_BACK) $(PWD)/$$@
	$(RUN_ON_REMOTE) rm -rf $(PWD)/bench.dir/

endef 

additional_compiler_flags = $(if $(find thin,$(1)),-flto=thin,)  $(if $(find full,$(1)),-flto=full,) -fprofile-use=$(INSTRUMENTED_PROF)/default.profdata
additional_linker_flags = $(if $(find thin,$(1)),-flto=thin,)  $(if $(find full,$(1)),-flto=full,) -fprofile-use=$(INSTRUMENTED_PROF)/default.profdata

$(eval $(call gen_pgo_targets,thin))
$(eval $(call gen_pgo_targets,full))


debug-makefile:
	$(warning $(call gen_pgo_targets,full))

instrumented: gcc-releases-$(GCC_VERSION)
	$(call build_gcc,$@,$(call gen_build_flags_ins,,,-fprofile-generate=$(INSTRUMENTED_PROF),-fprofile-generate=$(INSTRUMENTED_PROF)),all-gcc)

instrumented.profdata:  instrumented
	rm -rf $(INSTRUMENTED_PROF)
	$(call switch_binary,instrumented)
	$(call run_bench,instrumented,$(PWD)/build.dir/instrumented/gcc)
	cd $(BENCH_DIR) && ./perf_commands.sh
	cd $(INSTRUMENTED_PROF) && $(LLVM_BIN)/llvm-profdata merge -output=$(PWD)/instrumented.profdata *


gcc-releases-$(GCC_VERSION):
	wget https://github.com/gcc-mirror/gcc/archive/refs/tags/releases/$(GCC_VERSION).zip && unzip -q -o $(GCC_VERSION) && rm -f $(GCC_VERSION).zip
	cd gcc-releases-$(GCC_VERSION) && contrib/download_prerequisites
	cd gcc-releases-$(GCC_VERSION) && find . -type f -name configure -exec sed -i 's/\$$CC -print-multi-os-directory/gcc -print-multi-os-directory/g' {} \;
	cd gcc-releases-$(GCC_VERSION) && find . -type f -name configure -exec sed -i 's/\$$CXX -print-multi-os-directory/gcc -print-multi-os-directory/g' {} \;
	cd gcc-releases-$(GCC_VERSION) && find . -type f -name configure -exec sed -i 's/\$$CC \$$CPPFLAGS \$$CFLAGS \$$LDFLAGS -print-multi-os-directory/gcc -print-multi-os-directory/g' {} \;
	cd $(MAKEFILE_ROOT) &&  make benchmarks/dparser/dparser-master



%.prepare: %
	$(call run_bench,$(basename $@),$(PWD)/build.dir/$(basename $@)/gcc)
	cd build.dir/bench/$(basename $@) && $(RUN_FOR_REMOTE) sed 's/\/[^ ]*IPRA-exp/\/tmp\/IPRA-exp/g; s/^:.*://g; s/\.c\.o -c/\.c\.S -S/g;' ./perf_commands.sh > ./perf_commands-copy.sh && \
				sed ' s/\.c\.o -c/\.c\.i -E/g; s/^:.*://g;' ./perf_commands.sh > ./preprocess.sh &&  \
				 $(RUN_FOR_REMOTE) $(INSTALL_PATH)/process_cmd < ./perf_commands-copy.sh > ./perf_commands.sh && \
				 $(RUN_FOR_REMOTE) bash ./preprocess.sh

%.bench: %.prepare
	$(COPY_TO_REMOTE) $(PWD)/build.dir/bench/$(basename $@)/
	$(COPY_TO_REMOTE) $(PWD)/build.dir/$(basename $@)/gcc/xgcc
	$(COPY_TO_REMOTE) $(PWD)/build.dir/$(basename $@)/gcc/cc1
	cd build.dir/bench/$(basename $@) && $(PERF) stat $(PERF_EVENTS) -o $(basename $@).bench -r5 -- $(TASKSET) bash ./perf_commands.sh
	$(COPY_BACK) $(PWD)/build.dir/bench/$(basename $@)/$(basename $@).bench
	cd build.dir/bench/$(basename $@) && $(PERF) record -e cycles:u -j any,u -o $(basename $@).perfdata -- $(TASKSET) bash ./perf_commands.sh
	$(COPY_BACK) $(PWD)/build.dir/bench/$(basename $@)/$(basename $@).perfdata
	$(RUN_ON_REMOTE) rm -rf /tmp/IPRA-exp/*
