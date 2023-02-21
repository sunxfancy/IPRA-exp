mkfile_path := $(dir $(abspath $(lastword $(MAKEFILE_LIST))))
BENCHMARK=gcc
include $(mkfile_path)../common.mk

GCC_VERSION:=10.4.0
GCC_NAME:=gcc-$(GCC_VERSION)
SOURCE = $(BUILD_PATH)/$(BENCHMARK)/gcc-releases-$(GCC_NAME)
BENCH_PROJECT =  $(BUILD_PATH)/$(BENCHMARK)/libevent-2.1.12-stable

gen_compiler_flags =CFLAGS=$(1) CXXFLAGS=$(1)
gen_linker_flags   =LDFLAGS=$(1)
COMMA := ,

MAIN_BIN = gcc/cc1
BUILD_ACTION=build_gcc
BUILD_TARGET=all-gcc
INSTALL_TARGET=all-gcc

define switch_binary
	if [ ! -d "$(INSTALL_DIR)/bin" ]; then \
		mkdir -p $(BUILD_PATH)/$(BENCHMARK) && cp -r $(PWD)/install.dir $(BUILD_PATH)/$(BENCHMARK)/; fi
	rm -f $(INSTALL_DIR)/libexec/gcc/x86_64-linux-gnu/$(GCC_VERSION)/cc1
	cp $(PWD)/$(1)/$(MAIN_BIN)$(2) $(INSTALL_DIR)/libexec/gcc/x86_64-linux-gnu/$(GCC_VERSION)/cc1
endef

define build_gcc
	if [ -d "$(PWD)/$(1)" ]; then rm -rf $(PWD)/$(1); fi
	mkdir -p $(BUILD_DIR)/$(1)
	mkdir -p $(PWD)/$(1)/$(BENCHMARK)
	mkdir -p $(INSTALL_DIR)
	$(call clean_count_push_pop,$(1))
	cd $(BUILD_DIR)/$(1) && \
		unset C_INCLUDE_PATH CPLUS_INCLUDE_PATH CFLAGS CXXFLAGS && \
 		../../gcc-releases-$(GCC_NAME)/configure -v \
		--build=x86_64-linux-gnu \
		--host=x86_64-linux-gnu \
		--target=x86_64-linux-gnu \
		--enable-offload-target=x86_64-linux-gnu \
		--prefix=$(INSTALL_DIR) \
		--enable-checking=release \
		--enable-languages=c \
		--disable-multilib \
		--disable-shared \
		--disable-lto \
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
		$(2) > $(PWD)/$(1)/conf.log	
	cd $(BUILD_DIR)/$(1) && CLANG_PROXY_FOCUS=cc1 \
		CLANG_PROXY_ARGS="$(4)" CLANG_PROXY_VAR="$(5)" \
		time -o $(PWD)/$(1)/time.log make $(3) -j $(shell nproc) > $(PWD)/$(1)/build.log \
		|| { echo "*** build failed ***"; exit 1 ; }
	if [ ! -d "$(PWD)/install.dir" ]; then \
		mkdir -p $(INSTALL_DIR) && cd $(BUILD_DIR)/$(1) && make install-gcc >> $(PWD)/$(1)/build.log; \
		if [ "$(1)" != "instrumented" ]; then \
			mv $(INSTALL_DIR) $(PWD)/install.dir; \
		fi; \
	fi 
	
	$(call mv_binary,$(1))
	$(call switch_binary,$(1))
endef

define run_bench
	if [ ! -d "$(BENCH_DIR)" ]; then \
		mkdir -p $(BENCH_DIR) && \
		cd $(BENCH_DIR) && cmake -G Ninja $(BENCH_PROJECT) \
			-DCMAKE_BUILD_TYPE=RelWithDebInfo \
			-DCMAKE_C_FLAGS="-fPIE" \
			-DCMAKE_C_COMPILER=$(1)/gcc \
			-DCMAKE_LINKER=/usr/bin/gcc \
			-DCMAKE_USER_MAKE_RULES_OVERRIDE=$(mkfile_path)makerules.cmake \
			-DCMAKE_BUILD_WITH_INSTALL_RPATH=ON \
		&& (ninja -t commands  | head -100 > perf_commands_raw.sh) \
		&& echo '/^\:\ \&\&\.*/d; /^\/usr\/bin\/cmake\.*/d;' \
		&& (sed '/^\:\ \&\&\.*/d; /^\/usr\/bin\/cmake\.*/d;' ./perf_commands_raw.sh > ./perf_commands.sh) \
		&& chmod +x ./perf_commands.sh; \
	fi
endef 


define copy_to_server
	cd $(BENCH_DIR) && $(RUN_FOR_REMOTE) sed 's/\/[^ ]*IPRA-exp/\/tmp\/IPRA-exp/g; s/^:.*://g;' ./perf_commands.sh > ./perf_commands-copy.sh && \
				sed ' s/\.cpp\.o -c/\.cpp\.i -E/g; s/^:.*://g;' ./perf_commands.sh > ./preprocess.sh &&  \
				 $(RUN_FOR_REMOTE) $(INSTALL_PATH)/process_cmd < ./perf_commands-copy.sh > ./perf_commands_remote.sh && \
				 $(RUN_FOR_REMOTE) bash ./preprocess.sh
	$(COPY_TO_REMOTE) $(BENCH_DIR)
	$(COPY_TO_REMOTE) $(PWD)/$(1)/$(MAIN_BIN)$(2)
	$(COPY_TO_REMOTE) $(INSTALL_PATH)/sub
endef



define gen_perfdata

$(1)$(2).perfdata: $(1)/.complete $(BENCH_PROJECT)/.complete
	$(call switch_binary,$(1),$(2))
	$(call run_bench,$(INSTALL_DIR)/bin)
	cd $(BENCH_DIR) && $(PERF) record -e cycles:u -j any,u -o ../$$@ -- $(TASKSET) bash ./perf_commands.sh
	$(COPY_BACK) $(PWD)/$$@
	$(RUN_ON_REMOTE) rm -rf $(PWD)/bench.dir/
	rm -rf $$@ 
	mv $(BUILD_PATH)/$(BENCHMARK)/$$@ $$@

$(1)$(2).regprof2: $(1)/.complete $(BENCH_PROJECT)/.complete
	$(call switch_binary,$(1),$(2))
	$(call run_bench,$(INSTALL_DIR)/bin)
	rm -rf $(PWD)/$$@.raw
	mkdir -p $(BENCH_DIR) && cd $(BENCH_DIR) && \
		LLVM_IRPP_PROFILE="$(PWD)/$$@.raw" $(DRRUN) bash ./perf_commands.sh
	cat $(PWD)/$$@.raw | $(COUNTSUM) > $(PWD)/$$@

$(1)$(2).regprof3: $(1).profbuild/.complete $(BENCH_PROJECT)/.complete
	$(call switch_binary,$(1).profbuild,$(2))
	$(call run_bench,$(INSTALL_DIR)/bin)
	rm -rf $(PWD)/$$@.raw
	cd $(BENCH_DIR) && \
		LLVM_IRPP_PROFILE="$(PWD)/$$@.raw" \
		$(TASKSET) bash ./perf_commands.sh
	cat $(PWD)/$$@.raw | $(COUNTSUM) > $(PWD)/$$@

endef

# $(1)$(2).bench: $(1)/.complete

define gen_bench

$(1)$(2).bench: $(1)/.complete
	$(call switch_binary,$(1),$(2))
	$(call run_bench,$(INSTALL_DIR)/bin)
	cd $(BENCH_DIR) && $(PERF) stat $(PERF_EVENTS) -o ../$$@ -r5 -- $(TASKSET) bash ./perf_commands.sh
	$(COPY_BACK) $(PWD)/$$@
	$(RUN_ON_REMOTE) rm -rf $(PWD)/bench.dir/
	rm -rf $$@ 
	mv $(BUILD_PATH)/$(BENCHMARK)/$$@ $$@
	
endef 

additional_compiler_flags = $(if $(findstring thin,$(1)),-flto=thin)  $(if $(findstring full,$(1)),-flto=full) -fprofile-use=$(PWD)/instrumented.profdata
additional_linker_flags = $(if $(findstring thin,$(1)),-flto=thin)  $(if $(findstring full,$(1)),-flto=full) -fprofile-use=$(PWD)/instrumented.profdata
additional_original_flags = $(if $(findstring thin,$(1)),AR=$(LLVM_AR) RANLIB=$(LLVM_RANLIB)) $(if $(findstring full,$(1)),AR=$(LLVM_AR) RANLIB=$(LLVM_RANLIB)) 

$(eval $(call gen_pgo_targets,thin))
$(eval $(call gen_pgo_targets,full))


debug-makefile:
	$(warning $(call gen_pgo_targets,full))

instrumented: instrumented/.complete
instrumented/.complete: | $(SOURCE)/.complete
	mkdir -p $(INSTRUMENTED_PROF)
	$(call build_gcc,instrumented,$(call gen_build_flags_ins,,-fprofile-generate=$(INSTRUMENTED_PROF),-fprofile-generate=$(INSTRUMENTED_PROF)),$(BUILD_TARGET))
	touch $@

instrumented.profdata:  instrumented/.complete
	rm -rf $(INSTRUMENTED_PROF) && mkdir -p $(INSTRUMENTED_PROF)
	$(call switch_binary,instrumented)
	$(call run_bench,$(INSTALL_DIR)/bin)
	cd $(BENCH_DIR) && ./perf_commands.sh
	cd $(INSTRUMENTED_PROF) && $(LLVM_BIN)/llvm-profdata merge -output=$(PWD)/instrumented.profdata *


libevent-2.1.12-stable.tar.gz:
	wget https://github.com/libevent/libevent/releases/download/release-2.1.12-stable/libevent-2.1.12-stable.tar.gz

$(GCC_NAME).zip:
	wget https://github.com/gcc-mirror/gcc/archive/refs/tags/releases/$(GCC_NAME).zip

$(SOURCE)/.complete: $(GCC_NAME).zip $(BENCH_PROJECT)/.complete
	mkdir -p $(BUILD_PATH)/$(BENCHMARK)
	cd $(BUILD_PATH)/$(BENCHMARK) && unzip -q -o $(PWD)/$< 
	cd $(BUILD_PATH)/$(BENCHMARK)/gcc-releases-$(GCC_NAME) && \
	   contrib/download_prerequisites \
	&& find . -type f -name configure -exec sed -i 's/\$$CC -print-multi-os-directory/gcc -print-multi-os-directory/g' {} \; \
	&& find . -type f -name configure -exec sed -i 's/\$$CXX -print-multi-os-directory/gcc -print-multi-os-directory/g' {} \; \
	&& find . -type f -name configure -exec sed -i 's/\$$CC \$$CPPFLAGS \$$CFLAGS \$$LDFLAGS -print-multi-os-directory/gcc -print-multi-os-directory/g' {} \;
	touch $@

$(BENCH_PROJECT)/.complete: libevent-2.1.12-stable.tar.gz
	mkdir -p $(BUILD_PATH)/$(BENCHMARK)
	cd $(BUILD_PATH)/$(BENCHMARK) && tar -xzf $(PWD)/$< 
	touch $@