PWD := $(shell pwd)
mkfile_path := $(dir $(lastword $(MAKEFILE_LIST)))
current_dir := $(notdir $(patsubst %/,%,$(dir $(mkfile_path))))


all: 

common_compiler_flags := -fuse-ld=lld -fno-inline-functions -mllvm -count-push-pop
common_linker_flags := -fuse-ld=lld -Wl,-fno-inline-functions -Wl,-mllvm -Wl,-count-push-pop

gen_compiler_flags = -DCMAKE_C_FLAGS=$(1) -DCMAKE_CXX_FLAGS=$(1)
gen_linker_flags   = -DCMAKE_EXE_LINKER_FLAGS=$(1) -DCMAKE_SHARED_LINKER_FLAGS=$(1) -DCMAKE_MODULE_LINKER_FLAGS=$(1)
gen_build_flags = $(call gen_compiler_flags,"$(common_compiler_flags) $(1)") $(call gen_linker_flags,"$(common_linker_flags) $(2)")
COMMA := ,


define build
	rm -f /tmp/count-push-pop.txt 
	touch /tmp/count-push-pop.txt
	mkdir -p build.dir/$(1)
	cd build.dir/$(1) && cmake -G Ninja dparser-master \
		-DCMAKE_BUILD_TYPE=Release \
		-DCMAKE_C_COMPILER=$(NCC) \
		-DCMAKE_CXX_COMPILER=$(NCXX) \
		$(2)
	cd build.dir/$(1) && CLANG_PROXY_FOCUS=make_dparser CLANG_PROXY_ARGS="-Wl,-mllvm -Wl,-count-push-pop" time -o time.log ninja -j $(shell nproc) -v > build.log
	echo "---------$(1)---------" >> ../dparser.output
	cat /tmp/count-push-pop.txt | $(COUNTSUM) >> ../dparser.output 
	touch $(1)
endef


instrumented: dparser-master
	$(call build,$@,$(call gen_build_flags,-fprofile-generate=$(INSTRUMENTED_PROF),-fprofile-generate=$(INSTRUMENTED_PROF)))

pgolto: $(INSTRUMENTED_PROF)/dparser.profdata
	$(call build,$@,$(gen_build_flags,-flto=thin -fprofile-use=$(INSTRUMENTED_PROF)/dparser.profdata,-flto=thin -fprofile-use=$(INSTRUMENTED_PROF)/dparser.profdata))

pgolto-ipra: $(INSTRUMENTED_PROF)/dparser.profdata
	$(call build,$@,$(gen_build_flags,,-Wl$(COMMA)-mllvm -Wl$(COMMA)-enable-ipra -Wl$(COMMA)-Bsymbolic-non-weak-functions))

pgolto-fdoipra: $(INSTRUMENTED_PROF)/dparser.profdata
	$(call build,$@,$(gen_build_flags,,-Wl$(COMMA)-mllvm -Wl$(COMMA)-fdo-ipra -Wl$(COMMA)-Bsymbolic-non-weak-functions))


pgolto-full: $(INSTRUMENTED_PROF)/dparser.profdata
	$(call build,$@,$(gen_build_flags,,))

pgolto-full-ipra: $(INSTRUMENTED_PROF)/dparser.profdata
	$(call build,$@,$(gen_build_flags,,-Wl$(COMMA)-mllvm -Wl$(COMMA)-enable-ipra -Wl$(COMMA)-Bsymbolic-non-weak-functions))

pgolto-full-fdoipra: $(INSTRUMENTED_PROF)/dparser.profdata
	$(call build,$@,$(gen_build_flags,,-Wl$(COMMA)-mllvm -Wl$(COMMA)-fdo-ipra -Wl$(COMMA)-Bsymbolic-non-weak-functions))


$(INSTRUMENTED_PROF)/dparser.profdata:  instrumented
	$(call run_bench,instrumented,$(PWD)/build.dir/instrumented/dparser)
	cd build.dir/bench/instrumented && ./perf_commands.sh
	cd $(INSTRUMENTED_PROF) && $(LLVM_BIN)/llvm-profdata merge -output=dparser.profdata *



dparser-master:
	wget https://github.com/jplevyak/dparser/archive/refs/heads/master.zip && unzip ./master.zip && rm ./master.zip
