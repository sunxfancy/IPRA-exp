mkfile_path := $(dir $(abspath $(lastword $(MAKEFILE_LIST))))
BENCHMARK=clang
include $(mkfile_path)../common.mk

CLANG_VERSION=llvmorg-14.0.6
SOURCE = $(BUILD_PATH)/$(BENCHMARK)/llvm-project-$(CLANG_VERSION)/llvm

common_compiler_flags += -fPIC

CLANG_NAME=clang-14

MAIN_BIN = bin/$(CLANG_NAME)
BUILD_ACTION=build_clang
BUILD_TARGET=clang lld
INSTALL_TARGET=install

define switch_binary
	if [ ! -d "$(INSTALL_DIR)/bin" ]; then \
		mkdir -p $(BUILD_PATH)/$(BENCHMARK) && cp -r $(PWD)/install.dir $(BUILD_PATH)/$(BENCHMARK)/; fi
	rm -f $(INSTALL_DIR)/$(MAIN_BIN)
	rm -f $(INSTALL_DIR)/bin/lld
	cp $(PWD)/$(1)/$(MAIN_BIN)$(2) $(INSTALL_DIR)/$(MAIN_BIN)
	cp $(PWD)/$(1)/bin/lld $(INSTALL_DIR)/bin/lld
endef

define build_clang
	if [ -d "$(PWD)/$(1)" ]; then rm -rf $(PWD)/$(1); fi
	mkdir -p $(BUILD_DIR)/$(1)
	mkdir -p $(PWD)/$(1)/bin
	mkdir -p $(INSTALL_DIR)
	$(call clean_count_push_pop,$(1))
	cd $(BUILD_DIR)/$(1) && cmake -G Ninja $(SOURCE) \
		-DCMAKE_BUILD_TYPE=Release \
		-DLLVM_OPTIMIZED_TABLEGEN=ON \
		-DLLVM_TARGETS_TO_BUILD="X86" \
		-DLLVM_ENABLE_RTTI=OFF \
		-DBUILD_SHARED_LIBS=OFF \
		-DLLVM_INCLUDE_TESTS=OFF \
		-DLLVM_BUILD_TESTS=OFF \
		-DLLVM_PARALLEL_LINK_JOBS=$(shell nproc) \
		-DCMAKE_C_COMPILER=$(NCC) \
		-DCMAKE_CXX_COMPILER=$(NCXX) \
		-DLLVM_ENABLE_PROJECTS="clang;lld;compiler-rt" \
		-DLLVM_USE_LINKER=lld \
		-DCMAKE_INSTALL_PREFIX=$(INSTALL_DIR) \
		$(2) > $(PWD)/$(1)/conf.log
	cd $(BUILD_DIR)/$(1) && CLANG_PROXY_FOCUS=$(CLANG_NAME) \
		CLANG_PROXY_ARGS="$(4)" CLANG_PROXY_VAR="$(5)" \
		time -o $(PWD)/$(1)/time.log ninja $(3) -j $(shell nproc) -v > $(PWD)/$(1)/build.log \
		|| { echo "*** build failed ***"; exit 1 ; }
	if [ ! -d "$(PWD)/install.dir" ]; then \
		mkdir -p $(INSTALL_DIR) && cd $(BUILD_DIR)/$(1) && ninja $(INSTALL_TARGET) -v >> $(PWD)/$(1)/build.log; \
		if [ "$(1)" != "instrumented" ]; then \
			mv $(INSTALL_DIR) $(PWD)/install.dir; \
		fi; \
	fi

	cp $(BUILD_DIR)/$(1)/bin/lld $(PWD)/$(1)/bin/lld
	$(call mv_binary,$(1))
	$(call switch_binary,$(1))
	$(call clang_bench,$(INSTALL_DIR)/bin)
endef

define clang_bench
	if [ ! -d "$(BENCH_DIR)" ]; then \
		mkdir -p $(BENCH_DIR) && \
		cd $(BENCH_DIR) && cmake -G Ninja $(SOURCE) \
			-DCMAKE_BUILD_TYPE=RelWithDebInfo \
			-DLLVM_TARGETS_TO_BUILD=X86 \
			-DLLVM_OPTIMIZED_TABLEGEN=On \
			-DCMAKE_C_COMPILER=$(1)/clang \
			-DCMAKE_CXX_COMPILER=$(1)/clang++ \
			-DLLVM_ENABLE_PROJECTS="clang" \
		&& (ninja -t commands  | head -100 > perf_commands_raw.sh) \
		&& echo '/^\:\ \&\&\.*/d; /^\/usr\/bin\/cmake\.*/d;' \
		&& (sed '/^\:\ \&\&\.*/d; /^\/usr\/bin\/cmake\.*/d;' ./perf_commands_raw.sh > ./perf_commands.sh) \
		&& chmod +x ./perf_commands.sh; \
	fi
endef

# -DCMAKE_C_FLAGS="-I$(INSTALL_DIR)/lib/clang/15.0.3/include" \
# -DCMAKE_CXX_FLAGS="-I$(INSTALL_DIR)/lib/clang/15.0.3/include" \


define copy_to_server
	mkdir -p $(BENCH_DIR) && cd $(BENCH_DIR) \
	   && $(RUN_FOR_REMOTE) sed 's/\/[^ ]*IPRA-exp/\/tmp\/IPRA-exp/g; s/^:.*://g;' ./perf_commands.sh > ./perf_commands-copy.sh && \
				sed ' s/\.cpp\.o -c/\.cpp\.i -E/g; s/^:.*://g;' ./perf_commands.sh > ./preprocess.sh &&  \
				 $(RUN_FOR_REMOTE) $(INSTALL_PATH)/process_cmd < ./perf_commands-copy.sh > ./perf_commands_remote.sh && \
				 $(RUN_FOR_REMOTE) bash ./preprocess.sh
	$(COPY_TO_REMOTE) $(BENCH_DIR)
	$(COPY_TO_REMOTE) $(PWD)/$(1)/$(MAIN_BIN)$(2)
	$(COPY_TO_REMOTE) $(INSTALL_DIR)/$(MAIN_BIN)
	$(COPY_TO_REMOTE) $(INSTALL_DIR)/bin/clang
	$(COPY_TO_REMOTE) $(INSTALL_DIR)/bin/clang++
	$(COPY_TO_REMOTE) $(INSTALL_PATH)/sub
endef


define gen_perfdata

$(1)$(2).perfdata: | $(1)/.complete $(SOURCE)/.complete
	$(call switch_binary,$(1),$(2))
	$(call clang_bench,$(INSTALL_DIR)/bin)
	mkdir -p $(BENCH_DIR) && cd $(BENCH_DIR) && \
		$(PERF) record -e cycles:u -j any,u -o ../$$@ -- $(TASKSET) bash ./perf_commands.sh
	$(COPY_BACK) $(PWD)/$$@
	$(RUN_ON_REMOTE) rm -rf $(BENCH_DIR)
	rm -rf $$@ 
	mv $(BUILD_PATH)/$(BENCHMARK)/$$@ $$@

$(1)$(2).regprof2: | $(1)/.complete $(SOURCE)/.complete
	$(call switch_binary,$(1),$(2))
	$(call clang_bench,$(INSTALL_DIR)/bin)
	rm -rf $(PWD)/$$@.raw
	mkdir -p $(BENCH_DIR) && cd $(BENCH_DIR) && \
		LLVM_IRPP_PROFILE="$(PWD)/$$@.raw" $(DRRUN) bash ./perf_commands.sh
	cat $(PWD)/$$@.raw | $(COUNTSUM) > $(PWD)/$$@

$(1)$(2).regprof3: | $(1).profbuild/.complete $(SOURCE)/.complete
	$(call switch_binary,$(1).profbuild,$(2))
	$(call clang_bench,$(INSTALL_DIR)/bin)
	rm -rf $(PWD)/$$@.raw
	mkdir -p $(BENCH_DIR) && cd $(BENCH_DIR) && \
		LLVM_IRPP_PROFILE="$(PWD)/$$@.raw" bash ./perf_commands.sh 
	cat $(PWD)/$$@.raw | $(COUNTSUM) > $(PWD)/$$@

endef

define gen_bench

$(1)$(2).bench: | $(SOURCE)/.complete
	$(call switch_binary,$(1),$(2))
	$(call clang_bench,$(INSTALL_DIR)/bin)
	$(call copy_to_server,$(1),$(2))
	mkdir -p $(BENCH_DIR) && cd $(BENCH_DIR) && \
		$(PERF) stat $(PERF_EVENTS) -o ../$$@ -r5 -- $(TASKSET) bash ./perf_commands.sh
	$(COPY_BACK) $(PWD)/$$@
	$(RUN_ON_REMOTE) rm -rf $(BENCH_DIR)
	rm -rf $$@
	mv $(BUILD_PATH)/$(BENCHMARK)/$$@ $$@

endef 

additional_original_flags =  $(if $(findstring thin,$(1)),-DLLVM_ENABLE_LTO=Thin) \
							 $(if $(findstring full,$(1)),-DLLVM_ENABLE_LTO=Full) \
							  -DLLVM_PROFDATA_FILE=$(PWD)/instrumented.profdata

$(eval $(call gen_pgo_targets,thin))
$(eval $(call gen_pgo_targets,full))

debug-makefile:
	$(warning $(call gen_pgo_targets,full))

instrumented: instrumented/.complete
instrumented/.complete: | $(SOURCE)/.complete
	$(call build_clang,instrumented,-DLLVM_BUILD_INSTRUMENTED=ON $(call gen_build_flags_ins),$(INSTALL_TARGET))
	touch $@

instrumented.profdata: instrumented/.complete
	rm -rf $(INSTRUMENTED_PROF)
	$(call switch_binary,instrumented)
	$(call clang_bench,$(INSTALL_DIR)/bin)
	cd $(BENCH_DIR) && ./perf_commands.sh
	cd $(INSTRUMENTED_PROF) && $(LLVM_BIN)/llvm-profdata merge -output=$(PWD)/instrumented.profdata * && rm *.profraw
	rm -rf $(INSTALL_DIR)


$(CLANG_VERSION).zip: 
	wget -q https://github.com/llvm/llvm-project/archive/refs/tags/$(CLANG_VERSION).zip

$(SOURCE)/.complete: $(CLANG_VERSION).zip
	mkdir -p $(BUILD_PATH)/$(BENCHMARK)
	cd $(BUILD_PATH)/$(BENCHMARK) && unzip -q -o $(PWD)/$<
	touch $@
