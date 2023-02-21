mkfile_path := $(dir $(abspath $(lastword $(MAKEFILE_LIST))))
BENCHMARK=fleet
include $(mkfile_path)../common.mk

FLEET_VERSION=main
SOURCE = $(BUILD_PATH)/$(BENCHMARK)/fleetbench-$(FLEET_VERSION)

MAIN_BIN = bin/mysqld
BUILD_ACTION=build_fleet
BUILD_TARGET=mysqld

define build_fleet
	mkdir -p $(BUILD_DIR)/$(1)
	mkdir -p $(PWD)/$(1)/fleetbench
	mkdir -p $(INSTALL_DIR)
	rm -f $(PWD)/$(1).count-push-pop 
	touch $(PWD)/$(1).count-push-pop
	cd $(SOURCE) && \
		bazel build \
		 -c opt \
		fleetbench/swissmap:hot_swissmap_benchmark

endef
#		 --incompatible_use_platforms_repo_for_constraints \


additional_compiler_flags = $(if $(find thin,$(1)),-flto=thin,)  $(if $(find full,$(1)),-flto=full,) -fprofile-use=$(PWD)/instrumented.profdata
additional_linker_flags = $(if $(find thin,$(1)),-flto=thin,)  $(if $(find full,$(1)),-flto=full,) -fprofile-use=$(PWD)/instrumented.profdata

$(eval $(call gen_pgo_targets,thin))
$(eval $(call gen_pgo_targets,full))

debug-makefile:
	$(warning $(call gen_pgo_targets,full))

instrumented: | $(SOURCE)/.complete
	mkdir -p $(INSTRUMENTED_PROF)
	$(call build_fleet,$@,$(call gen_build_flags_ins,,-fprofile-generate=$(INSTRUMENTED_PROF),-fprofile-generate=$(INSTRUMENTED_PROF)),$(BUILD_TARGET))

instrumented.profdata:  instrumented
	rm -rf $(INSTRUMENTED_PROF) && mkdir -p $(INSTRUMENTED_PROF)
	$(call switch_binary,instrumented)
	$(call run_bench,$(INSTALL_DIR)/bin)
	cd $(BENCH_DIR) && ./perf_commands.sh
	cd $(INSTRUMENTED_PROF) && $(LLVM_BIN)/llvm-profdata merge -output=$(PWD)/instrumented.profdata *

$(FLEET_VERSION).zip:
	wget https://github.com/google/fleetbench/archive/refs/heads/main.zip

# wget https://github.com/google/fleetbench/archive/refs/tags/v$(FLEET_VERSION).zip

$(SOURCE)/.complete: $(FLEET_VERSION).zip
	mkdir -p $(BUILD_PATH)/$(BENCHMARK)
	cd $(BUILD_PATH)/$(BENCHMARK) && unzip -q -o $(PWD)/$<
	touch $@
