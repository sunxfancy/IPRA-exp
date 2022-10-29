mkfile_path := $(dir $(abspath $(lastword $(MAKEFILE_LIST))))
include $(mkfile_path)../common.mk

CLANG_VERSION=llvmorg-14.0.6
LLVM = $(PWD)/llvm-project-$(CLANG_VERSION)/llvm

common_compiler_flags += -fPIC

MAIN_BIN = bin/clang-14
BUILD_ACTION=build_clang
BUILD_TARGET=clang lld

define switch_binary
	rm -f install.dir/bin/clang-14
	rm -f install.dir/bin/lld
	ln -s $(PWD)/build.dir/$(1)/bin/clang-14$(2) install.dir/bin/clang-14
	ln -s $(PWD)/build.dir/$(1)/bin/lld install.dir/bin/lld
endef

define build_clang
	mkdir -p build.dir/$(1)
	mkdir -p install.dir/
	rm -f $(PWD)/build.dir/$(1).count-push-pop 
	touch $(PWD)/build.dir/$(1).count-push-pop
	cd build.dir/$(1) && cmake -G Ninja $(LLVM) \
		-DCMAKE_BUILD_TYPE=Release \
		-DLLVM_OPTIMIZED_TABLEGEN=ON \
		-DLLVM_TARGETS_TO_BUILD="X86" \
		-DLLVM_ENABLE_RTTI=OFF \
		-DBUILD_SHARED_LIBS=OFF \
		-DLLVM_INCLUDE_TESTS=ON \
		-DLLVM_BUILD_TESTS=ON \
		-DLLVM_PARALLEL_LINK_JOBS=$(shell nproc) \
		-DCMAKE_C_COMPILER=$(NCC) \
		-DCMAKE_CXX_COMPILER=$(NCXX) \
		-DLLVM_ENABLE_PROJECTS="clang;lld" \
		-DLLVM_USE_LINKER=lld \
		-DCMAKE_INSTALL_PREFIX=$(PWD)/install.dir/ \
		$(2) > conf.log
	cd build.dir/$(1) && CLANG_PROXY_FOCUS=clang-14 \
		CLANG_PROXY_ARGS="$(4)" CLANG_PROXY_VAR="$(5)" \
		time -o time.log ninja $(3) -j $(shell nproc) -v > build.log \
		|| { echo "*** build failed ***"; exit 1 ; }
	echo "---------$(1)---------" >> ../clang.raw
	cat $(PWD)/build.dir/$(1).count-push-pop >> ../clang.raw 
	echo "---------$(1)---------" >> ../clang.output
	cat $(PWD)/build.dir/$(1).count-push-pop | $(COUNTSUM) >> ../clang.output 
	cat $(PWD)/build.dir/$(1).count-push-pop | $(COUNTSUM) > $(1)

	$(call switch_binary,$(1))
	$(call mv_binary,$(1))

endef

define clang_bench
	mkdir -p bench.dir/
	cd bench.dir/ && cmake -G Ninja $(LLVM) \
		-DCMAKE_BUILD_TYPE=RelWithDebInfo \
		-DLLVM_TARGETS_TO_BUILD=X86 \
		-DLLVM_OPTIMIZED_TABLEGEN=On \
		-DCMAKE_C_COMPILER=$(2)/clang \
		-DCMAKE_CXX_COMPILER=$(2)/clang++ \
		-DLLVM_ENABLE_PROJECTS="clang"
	cd bench.dir/ && (ninja -t commands | head -100 > $(PWD)/bench.dir/perf_commands.sh)
	cd bench.dir/ && chmod +x ./perf_commands.sh
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
	cd bench.dir && $(PERF) record -e cycles:u -j any,u -o ../$$@ -- taskset -c 1 bash ./perf_commands.sh
	$(COPY_BACK) $(PWD)/$$@
	$(RUN_ON_REMOTE) rm -rf $(PWD)/bench.dir/

endef

define gen_bench

$(1)$(2).bench: $(1)
	$(call switch_binary,$(1),$(2))
	$(call copy_to_server,$(1),$(2))
	cd bench.dir && $(PERF) stat $(PERF_EVENTS) -o ../$$@ -r5 -- taskset -c 1 bash ./perf_commands.sh
	$(COPY_BACK) $(PWD)/$$@
	$(RUN_ON_REMOTE) rm -rf $(PWD)/bench.dir/

endef 

additional_original_flags =  $(if $(findstring thin,$(1)),-DLLVM_ENABLE_LTO=Thin) \
														 $(if $(findstring full,$(1)),-DLLVM_ENABLE_LTO=Full) \
														 -DLLVM_PROFDATA_FILE=$(INSTRUMENTED_PROF)/default.profdata

$(eval $(call gen_pgo_targets,thin))
$(eval $(call gen_pgo_targets,full))

debug-makefile:
	$(warning $(call gen_pgo_targets,full))

instrumented: llvm-project-$(CLANG_VERSION)
	$(call build_clang,$@,-DLLVM_BUILD_INSTRUMENTED=ON $(call gen_build_flags_ins),install)

$(INSTRUMENTED_PROF)/default.profdata: instrumented
	$(call clang_bench,instrumented,$(PWD)/install.dir/bin)
	cd bench.dir && ./perf_commands.sh
	cd $(INSTRUMENTED_PROF) && $(LLVM_BIN)/llvm-profdata merge -output=default.profdata *

gen_profdata: $(INSTRUMENTED_PROF)/default.profdata

llvm-project-$(CLANG_VERSION):
	wget -q https://github.com/llvm/llvm-project/archive/refs/tags/$(CLANG_VERSION).zip && unzip -q $(CLANG_VERSION) && rm -f $(CLANG_VERSION).zip

%.lbench: %
	$(call switch_binary,$(basename $@))
	cd bench.dir && perf stat -o ../$(basename $@).lbench -r5 -- taskset -c 1 bash ./perf_commands.sh


%.convert:
	rm -rf bench.dir/$(basename $@)/tb
	cd $(GOOGLE_WORKSPACE) && blaze-bin/experimental/users/kpszeniczny/perf2capacitor/perf2capacitor \
		--binary="$(PWD)/install.dir/bin/clang-14" \
		--profile_pattern="$(PWD)/bench.dir/$(basename $@)/*.perfdata" \
		--output_directory="$(PWD)/bench.dir/$(basename $@)/tb" \
		--parallelism=5
	fileutil cp -f $(PWD)/bench.dir/$(basename $@)/tb/$(basename $@).perfdata.capacitor /cns/sandbox/home/xiaofans

# --output_capacitor=/cns/sandbox/home/xiaofans/$(basename $@).capacitor 
# --binary="/cns/sandbox/home/xiaofans/clang-14" 
%.query:
	cd $(GOOGLE_WORKSPACE) && blaze-bin/experimental/users/kpszeniczny/symbolize_sql/mass_symbolizer_main \
		--binary="$(PWD)/install.dir/bin/clang-14" \
		--output_capacitor=/cns/sandbox/home/xiaofans/f1output/$(basename $@).capacitor \
		--query='DEFINE TABLE tab(format = "capacitor", path = "/cns/sandbox/home/xiaofans/$(basename $@).perfdata.capacitor"); SELECT DISTINCT sample_event.ip FROM tab;' \
	  --alsologtostderr
	fileutil cp -f /cns/sandbox/home/xiaofans/f1output/$(basename $@).capacitor /tmp/IPRA-exp/$(basename $@).capacitor
	fileutil rm -f /cns/sandbox/home/xiaofans/f1output/$(basename $@).capacitor
	