
benchmarks: benchmarks/clang/regprof benchmarks/mysql/regprof benchmarks/gcc/regprof
	
# make benchmarks/SPEC/bench

benchmarks-build: benchmarks/clang/build benchmarks/mysql/build benchmarks/gcc/build # benchmarks/SPEC

FDOIPRA_FLAVORS := fdoipra fdoipra2 fdoipra3 bfdoipra bfdoipra2 bfdoipra3
PGO_FULL_FLAVORS := pgo-full $(foreach f,$(FDOIPRA_FLAVORS),pgo-full-$(f)) pgo-full-ipra
PGO_THIN_FLAVORS := pgo-thin $(foreach f,$(FDOIPRA_FLAVORS),pgo-thin-$(f)) pgo-thin-ipra
FLAVORS := $(PGO_FULL_FLAVORS)

COMPILER_FLAGS:=-fuse-ld=lld -fbasic-block-sections=labels -Qunused-arguments -funique-internal-linkage-names -fno-optimize-sibling-calls -mllvm -fast-isel=false -fsplit-machine-functions
LINKER_FLAGS:=-fuse-ld=lld -static-libgcc -static-libstdc++ -Wl,--lto-basic-block-sections=labels -Wl,-z,keep-text-section-prefix -Wl,--build-id -fno-optimize-sibling-calls -Wl,-mllvm -Wl,-fast-isel=false -fsplit-machine-functions -Wl,-Bsymbolic-non-weak-functions

COMPILER_FLAGS_IPRA:= -mllvm -enable-ipra
LINKER_FLAGS_IPRA:= -Wl,-mllvm -Wl,-enable-ipra

COMPILER_FLAGS_FDOIPRA:= -mllvm -fdo-ipra -mllvm -fdoipra-both-hot=false
LINKER_FLAGS_FDOIPRA:= -Wl,-mllvm -Wl,-fdo-ipra -Wl,-mllvm -Wl,-fdoipra-both-hot=false

COMPILER_FLAGS_BFDOIPRA:= -mllvm -fdo-ipra 
LINKER_FLAGS_BFDOIPRA:= -Wl,-mllvm -Wl,-fdo-ipra

COMPILER_FLAGS_CH:= -mllvm -fdoipra-ch=1
LINKER_FLAGS_CH:= -Wl,-mllvm -Wl,-fdoipra-ch=1

COMPILER_FLAGS_HC:= -mllvm -fdoipra-hc=1
LINKER_FLAGS_HC:= -Wl,-mllvm -Wl,-fdoipra-hc=1

COMPILER_FLAGS_FDOIPRA2:= $(COMPILER_FLAGS_FDOIPRA) $(COMPILER_FLAGS_CH)
LINKER_FLAGS_FDOIPRA2:= $(LINKER_FLAGS_FDOIPRA) $(LINKER_FLAGS_CH)

COMPILER_FLAGS_BFDOIPRA2:=  $(COMPILER_FLAGS_BFDOIPRA) $(COMPILER_FLAGS_CH)
LINKER_FLAGS_BFDOIPRA2:= $(LINKER_FLAGS_BFDOIPRA) $(LINKER_FLAGS_CH)

COMPILER_FLAGS_FDOIPRA3:= $(COMPILER_FLAGS_FDOIPRA2) $(COMPILER_FLAGS_HC)
LINKER_FLAGS_FDOIPRA3:= $(LINKER_FLAGS_FDOIPRA2) $(LINKER_FLAGS_HC)

COMPILER_FLAGS_BFDOIPRA3:=  $(COMPILER_FLAGS_BFDOIPRA2) $(COMPILER_FLAGS_HC)
LINKER_FLAGS_BFDOIPRA3:= $(LINKER_FLAGS_BFDOIPRA2) $(LINKER_FLAGS_HC)

PERF_EVENTS:= -e instructions,cycles,L1-icache-misses,iTLB-misses,L1-dcache-loads,L1-dcache-load-misses,dTLB-load-misses,L1-dcache-stores,L1-dcache-store-misses,dTLB-store-misses,branches,branch-misses,page-faults,context-switches,cpu-migrations
CONFIG:=$(PWD)/benchmarks/cfg

export

SUBDIRS := $(patsubst %/build.mk,%,$(wildcard benchmarks/*/build.mk))

.PHONY: $(SUBDIRS)

$(SUBDIRS):
	mkdir -p $(OUTPUT_PATH)/$@
	$(MAKE) -C $(OUTPUT_PATH)/$@ -f $(PWD)/$@/build.mk 

benchmarks/%: 
	mkdir -p $(OUTPUT_PATH)/$(dir $@)
	$(MAKE) -C $(OUTPUT_PATH)/$(dir $@) -f $(PWD)/$(dir $@)build.mk $(notdir $@) 


