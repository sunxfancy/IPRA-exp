mkfile_path := $(dir $(lastword $(MAKEFILE_LIST)))
BENCHMARK=dparser
include $(mkfile_path)../common.mk

SOURCE = $(BUILD_PATH)/$(BENCHMARK)/dparser-master

MAIN_BIN = bin/dparser
BUILD_ACTION = build
BUILD_TARGET = dparser

define build
	mkdir -p $(BUILD_DIR)/$(1)
	mkdir -p $(PWD)/$(1)/bin
	mkdir -p $(INSTALL_DIR)
	rm -f $(PWD)/$(1).count-push-pop 
	touch $(PWD)/$(1).count-push-pop
	cd $(BUILD_DIR)/$(1) && cmake -G Ninja $(SOURCE) \
		-DCMAKE_BUILD_TYPE=Release \
		-DCMAKE_C_COMPILER=$(NCC) \
		-DCMAKE_CXX_COMPILER=$(NCXX) \
		-DCMAKE_INSTALL_PREFIX=$(INSTALL_DIR) \
		$(2) > $(PWD)/$(1)/conf.log
	cd $(BUILD_DIR)/$(1) && CLANG_PROXY_FOCUS=dparser \
		CLANG_PROXY_ARGS="$(4)" CLANG_PROXY_VAR="$(5)" \
		time -o $(PWD)/$(1)/time.log ninja $(3) -j $(shell nproc) -v > $(PWD)/$(1)/build.log \
		|| { echo "*** build failed ***"; exit 1 ; }
	echo "---------$(1)---------" >> ../dparser.raw
	cat $(PWD)/$(1).count-push-pop >> ../dparser.raw 
	echo "---------$(1)---------" >> ../dparser.output
	cat $(PWD)/$(1).count-push-pop | $(COUNTSUM) >> ../dparser.output 
endef

additional_original_flags =  $(if $(findstring thin,$(1)),-DLLVM_ENABLE_LTO=Thin) \
							 $(if $(findstring full,$(1)),-DLLVM_ENABLE_LTO=Full) \
							  -DLLVM_PROFDATA_FILE=$(PWD)/instrumented.profdata

$(eval $(call gen_pgo_targets,thin))
$(eval $(call gen_pgo_targets,full))

debug-makefile:
	$(warning $(call gen_pgo_targets,full))

instrumented: | $(SOURCE)/.complete
	$(call build_clang,$@,-DLLVM_BUILD_INSTRUMENTED=ON $(call gen_build_flags_ins),install)
	touch $@

instrumented.profdata: instrumented
	rm -rf $(INSTRUMENTED_PROF)
	$(call switch_binary,instrumented)
	$(call clang_bench,$(INSTALL_DIR)/bin)
	cd $(BENCH_DIR) && ./perf_commands.sh
	cd $(INSTRUMENTED_PROF) && $(LLVM_BIN)/llvm-profdata merge -output=$(PWD)/instrumented.profdata * && rm *.profraw
	rm -rf $(INSTALL_DIR)


%.bench: %
	cd build.dir/$(basename $@) && perf stat -o $(basename $@).bench -r5 -- $(TASKSET) bash $(mkfile_path)scripts.sh

dparser-master: $(SOURCE)/.complete

master.zip:
	wget https://github.com/jplevyak/dparser/archive/refs/heads/master.zip

$(SOURCE)/.complete: master.zip
	mkdir -p $(BUILD_PATH)/$(BENCHMARK)
	cd $(BUILD_PATH)/$(BENCHMARK) && unzip -q -o $(PWD)/$<
	touch $@
