mkfile_path := $(dir $(abspath $(lastword $(MAKEFILE_LIST))))
BENCHMARK=mongodb
include $(mkfile_path)../common.mk

MONGODB_VERSION=r5.3.2
MONGODB_VERSION_FOR_BUILD=5.3.2
URL=https://github.com/sunxfancy/mongodb-publish/releases/download/v5.3.2/mongo-r5.3.2.zip
SOURCE = $(BUILD_PATH)/$(BENCHMARK)/mongo-$(MONGODB_VERSION)

common_compiler_flags += \
	 -Wno-error -Wno-error=int-conversion -Wno-error=implicit-function-declaration \
	 -Wno-enum-constexpr-conversion -Wno-error=unused-but-set-variable -Wno-error=deprecated-copy -Wno-backend-plugin

MAIN_BIN=install/bin/mongod
BUILD_ACTION=build_mongo
BUILD_TARGET=install-core
INSTALL_TARGET=install-core

gen_compiler_flags =CCFLAGS=$(1)
gen_linker_flags   =LINKFLAGS=$(1)



define build_mongo
	if [ -d "$(PWD)/$(1)" ]; then rm -rf $(PWD)/$(1); fi
	mkdir -p $(BUILD_DIR)/$(1)
	mkdir -p $(PWD)/$(1)
	mkdir -p $(PWD)/$(1)/install/bin
	cd $(SOURCE) && \
		CLANG_PROXY_FOCUS=mongod \
		CLANG_PROXY_ARGS="$(4)" CLANG_PROXY_VAR="$(5)" \
		GIT_PYTHON_REFRESH=quiet \
		time -o $(PWD)/$(1)/time.log \
		python3 buildscripts/scons.py $(3) \
		--disable-warnings-as-errors  \
		--build-dir=$(BUILD_DIR)/$(1) \
		CC=$(NCC) CXX=$(NCXX) \
		$(2) \
		MONGO_VERSION=$(MONGODB_VERSION_FOR_BUILD) \
		> $(PWD)/$(1)/build.log
	$(call mv_binary,$(1))
	cp $(BUILD_DIR)/$(1)/install/bin/mongo $(PWD)/$(1)/install/bin/mongo
endef

# cd $(BUILD_DIR)/$(1) && cmake -G Ninja $(SOURCE) \
# 	-DCMAKE_BUILD_TYPE=Release \
# 	-DCMAKE_C_COMPILER=$(NCC) \
# 	-DCMAKE_CXX_COMPILER=$(NCXX) \
# 	-DCMAKE_INSTALL_PREFIX=$(INSTALL_DIR) \
# 	$(2) > $(PWD)/$(1)/conf.log	
# cd $(BUILD_DIR)/$(1) && CLANG_PROXY_DEBUG=1 CLANG_PROXY_FOCUS=db_bench \
# 	CLANG_PROXY_ARGS="$(4)" CLANG_PROXY_VAR="$(5)" \
# 	time -o $(PWD)/$(1)/time.log ninja $(3) -j $(shell nproc) -v > $(PWD)/$(1)/build.log \
# 	|| { echo "*** build failed ***"; exit 1 ; }
# cat $(PWD)/$(1).count-push-pop | $(COUNTSUM) > $(1).regprof0



define gen_perfdata

$(1)$(2).perfdata: | $(1)/.complete
	mkdir -p $(BENCH_DIR) && cd $(BENCH_DIR) && \
		bash "$(mkfile_path)run.sh" run_perf  ../$$@  $(1) $(2)
	rm -rf $(BENCH_DIR) 
	rm -rf $$@ 
	mv $(BUILD_PATH)/$(BENCHMARK)/$$@ $$@

$(1)$(2).regprof2: | $(1)/.complete
	rm -rf $(PWD)/$$@.raw
	mkdir -p $(BENCH_DIR) && cd $(BENCH_DIR) && \
		LLVM_IRPP_PROFILE="$(PWD)/$$@.raw" $(DRRUN) python benchrun.py -f testcases/simple_insert.js  -t 1 
	rm -rf $(BENCH_DIR) 
	cat $(PWD)/$$@.raw | $(COUNTSUM) > $(PWD)/$$@

$(1)$(2).regprof3: | $(1).profbuild/.complete
	rm -rf $(PWD)/$$@.raw
	mkdir -p $(BENCH_DIR) && cd $(BENCH_DIR) && \
		LLVM_IRPP_PROFILE="$(PWD)/$$@.raw" bash "$(mkfile_path)run.sh" run $(1).profbuild $(2)
	rm -rf $(BENCH_DIR) 
	cat $(PWD)/$$@.raw | $(COUNTSUM) > $(PWD)/$$@

endef

define gen_bench

$(1)$(2).bench: | $(1)/.complete
	mkdir -p $(BENCH_DIR) && cd $(BENCH_DIR) && \
		bash "$(mkfile_path)run.sh" run_bench  $(PWD)/$$@  $(1) $(2)
	mv $(BUILD_PATH)/$(BENCHMARK)/$$@ $$@
	rm -rf $(BENCH_DIR)

endef 

additional_compiler_flags = $(if $(findstring thin,$(1)),-flto=thin,)  $(if $(findstring full,$(1)),-flto=full,) -fprofile-use=$(PWD)/instrumented.profdata
additional_linker_flags = $(if $(findstring thin,$(1)),-flto=thin,)  $(if $(findstring full,$(1)),-flto=full,) -fprofile-use=$(PWD)/instrumented.profdata


$(eval $(call gen_pgo_targets,thin))
$(eval $(call gen_pgo_targets,full))

debug-makefile:
	$(warning $(call gen_pgo_targets,full))

instrumented: instrumented/.complete
instrumented/.complete: | $(SOURCE)/.complete
	$(call build_mongo,instrumented,$(call gen_build_flags_ins,,-fprofile-generate=$(INSTRUMENTED_PROF),-fprofile-generate=$(INSTRUMENTED_PROF)),$(INSTALL_TARGET))
	touch $@

instrumented.profdata: instrumented/.complete
	rm -rf $(INSTRUMENTED_PROF)
	mkdir -p $(BENCH_DIR)
	cd $(BENCH_DIR) &&  bash "$(mkfile_path)run.sh" run instrumented \
		|| { echo "*** loadtest failed ***" ; rm -f $(PWD)/$$@ ; exit 1; }
	cd $(INSTRUMENTED_PROF) && $(LLVM_BIN)/llvm-profdata merge -output=$(PWD)/instrumented.profdata * && rm *.profraw
	rm -rf $(BENCH_DIR) 


mongo-$(MONGODB_VERSION).zip: 
	wget -q $(URL) 

mongo-perf.zip:
	wget -q https://github.com/mongodb/mongo-perf/archive/refs/heads/master.zip -O mongo-perf.zip

$(SOURCE)/.complete: mongo-$(MONGODB_VERSION).zip  mongo-perf.zip
	mkdir -p $(BUILD_PATH)/$(BENCHMARK)
	cd $(BUILD_PATH)/$(BENCHMARK) && unzip -q -o $(PWD)/mongo-perf.zip
	mkdir -p $(SOURCE) && cd $(SOURCE) &&  unzip -q -o $(PWD)/$<
	touch $@


