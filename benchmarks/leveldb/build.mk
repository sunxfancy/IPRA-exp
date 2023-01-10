mkfile_path := $(dir $(abspath $(lastword $(MAKEFILE_LIST))))
BENCHMARK=leveldb
include $(mkfile_path)../common.mk

LEVELDB_VERSION=1.23
SOURCE = $(BUILD_PATH)/$(BENCHMARK)/leveldb-$(LEVELDB_VERSION)

common_compiler_flags +=  -fPIC -DNDEBUG \
	 -Wno-error -Wno-error=int-conversion -Wno-error=implicit-function-declaration \
	 -Wno-enum-constexpr-conversion -Wno-error=unused-but-set-variable -Wno-error=deprecated-copy

MAIN_BIN = db_bench
BUILD_ACTION=build_leveldb
BUILD_TARGET=db_bench


define build_leveldb
	mkdir -p $(BUILD_DIR)/$(1)
	mkdir -p $(PWD)/$(1)
	rm -f $(PWD)/$(1).count-push-pop 
	touch $(PWD)/$(1).count-push-pop
	cd $(BUILD_DIR)/$(1) && cmake -G Ninja $(SOURCE) \
		-DCMAKE_BUILD_TYPE=Release \
		-DCMAKE_C_COMPILER=$(NCC) \
		-DCMAKE_CXX_COMPILER=$(NCXX) \
		-DCMAKE_INSTALL_PREFIX=$(INSTALL_DIR) \
		$(2) > $(PWD)/$(1)/conf.log	
	cd $(BUILD_DIR)/$(1) && CLANG_PROXY_FOCUS=db_bench \
		CLANG_PROXY_ARGS="$(4)" CLANG_PROXY_VAR="$(5)" \
		time -o $(PWD)/$(1)/time.log ninja $(3) -j $(shell nproc) -v > $(PWD)/$(1)/build.log \
		|| { echo "*** build failed ***"; exit 1 ; }
	echo "---------$(1)---------" >> ../leveldb.raw
	cat $(PWD)/$(1).count-push-pop >> ../leveldb.raw 
	echo "---------$(1)---------" >> ../leveldb.output
	cat $(PWD)/$(1).count-push-pop | $(COUNTSUM) >> ../leveldb.output 
	$(call mv_binary,$(1))
endef


define gen_perfdata

$(1)$(2).perfdata: $(1) 
	mkdir -p $(BENCH_DIR) && cd $(BENCH_DIR) && \
		$(PERF) record -e cycles:u -j any,u -o ../$$@ -- $(TASKSET) $(PWD)/$(1)/$(MAIN_BIN)$(2)
	rm -rf /tmp/leveldbtest-*
	rm -rf $$@ 
	mv $(BUILD_PATH)/$(BENCHMARK)/$$@ $$@

$(1)$(2).regprof2: $(1)
	mkdir -p $(BENCH_DIR) && cd $(BENCH_DIR) && \
		$(PERF) record -e cycles:u -j any,u -o ../$$@ -- $(TASKSET) $(PWD)/$(1)/$(MAIN_BIN)$(2)
	rm -rf /tmp/leveldbtest-*
	rm -rf $$@ 
	mv $(BUILD_PATH)/$(BENCHMARK)/$$@ $$@

$(1)$(2).regprof3: $(1).profbuild
	mkdir -p $(BENCH_DIR) && cd $(BENCH_DIR) && \
		LLVM_IRPP_PROFILE="$(PWD)/$$@.raw" $(PWD)/$(1).profbuild/$(MAIN_BIN)$(2)
	rm -rf /tmp/leveldbtest-*
	cat $(PWD)/$$@.raw | $(COUNTSUM) > $(PWD)/$$@

endef

define gen_bench

$(1)$(2).bench: $(1)
	mkdir -p $(BENCH_DIR) && cd $(BENCH_DIR) && \
		$(PERF) stat $(PERF_EVENTS) -o ../$$@ -r5 -- $(TASKSET) $(PWD)/$(1)/$(MAIN_BIN)$(2)
	rm -rf /tmp/leveldbtest-*
	rm -rf $$@
	mv $(BUILD_PATH)/$(BENCHMARK)/$$@ $$@

endef 

additional_compiler_flags = $(if $(find thin,$(1)),-flto=thin,)  $(if $(find full,$(1)),-flto=full,) -fprofile-use=$(PWD)/instrumented.profdata
additional_linker_flags = $(if $(find thin,$(1)),-flto=thin,)  $(if $(find full,$(1)),-flto=full,) -fprofile-use=$(PWD)/instrumented.profdata


$(eval $(call gen_pgo_targets,thin))
$(eval $(call gen_pgo_targets,full))

debug-makefile:
	$(warning $(call gen_pgo_targets,full))

instrumented: | $(SOURCE)/.complete
	$(call build_leveldb,$@,$(call gen_build_flags_ins,,-fprofile-generate=$(INSTRUMENTED_PROF),-fprofile-generate=$(INSTRUMENTED_PROF)),install)
	touch $@

instrumented.profdata: instrumented
	rm -rf $(INSTRUMENTED_PROF)
	mkdir -p $(BENCH_DIR)
	cd $(BENCH_DIR) && $(PWD)/instrumented/$(MAIN_BIN)
	cd $(INSTRUMENTED_PROF) && $(LLVM_BIN)/llvm-profdata merge -output=$(PWD)/instrumented.profdata * && rm *.profraw
	rm -rf /tmp/leveldbtest-*


$(LEVELDB_VERSION).zip: 
	wget -q https://github.com/google/leveldb/archive/refs/tags/$(LEVELDB_VERSION).zip

benchmark.zip:
	wget -q https://github.com/google/benchmark/archive/bf585a2789e30585b4e3ce6baf11ef2750b54677.zip -O benchmark.zip

googletest.zip:
	wget -q https://github.com/google/googletest/archive/c27acebba3b3c7d94209e0467b0a801db4af73ed.zip -O googletest.zip

$(SOURCE)/.complete: $(LEVELDB_VERSION).zip benchmark.zip googletest.zip
	mkdir -p $(BUILD_PATH)/$(BENCHMARK)
	cd $(BUILD_PATH)/$(BENCHMARK) && unzip -q -o $(PWD)/$< 
	rm -rf $(SOURCE)/third_party/benchmark $(SOURCE)/third_party/googletest
	cd $(SOURCE)/third_party/ && unzip -q -o $(PWD)/benchmark.zip && mv benchmark-bf585a2789e30585b4e3ce6baf11ef2750b54677 benchmark
	cd $(SOURCE)/third_party/ && unzip -q -o $(PWD)/googletest.zip && mv googletest-c27acebba3b3c7d94209e0467b0a801db4af73ed googletest
	touch $@
