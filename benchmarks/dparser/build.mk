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
	$(FDO) opt --pgo $(2)
	echo "---------$(1)---------" >> dparser.output
	cat /tmp/count-push-pop.txt >> dparser.output 
	touch .$(1)
endef

instrumented: dparser-master
	mkdir -p build.dir/dparser
	$(FDO) config dparser-master -DCMAKE_BUILD_TYPE=Release

	$(FDO) build --lto=full -s $(mkfile_path)DParser.yaml --pgo
	$(FDO) test  --pgo
	touch instrumented

pgolto: instrumented
	$(call build,pgolto,$(gen_build_flags,,))

pgolto-ipra: instrumented
	$(call build,pgolto,$(gen_build_flags,,-Wl$(COMMA)-mllvm -Wl$(COMMA)-enable-ipra -Wl$(COMMA)-Bsymbolic-non-weak-functions))

pgolto-fdoipra: instrumented
	$(call build,pgolto,$(gen_build_flags,,-Wl$(COMMA)-mllvm -Wl$(COMMA)-fdo-ipra -Wl$(COMMA)-Bsymbolic-non-weak-functions))

dparser-master:
	wget https://github.com/jplevyak/dparser/archive/refs/heads/master.zip && unzip ./master.zip && rm ./master.zip
