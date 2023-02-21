HOT_LIST_THRESHOLD:=3
COLD_CALLSITE_RATIO:=10

mkfile_path := $(dir $(abspath $(lastword $(MAKEFILE_LIST))))
PWD:=$(shell pwd)
PROFILE_DIR:=$(PWD)/pgo-inst
LINKER_FLAGS:=-Wl,--lto-basic-block-sections=labels -Wl,-z,keep-text-section-prefix -Wl,--build-id -fno-optimize-sibling-calls -Wl,-mllvm -Wl,-fast-isel=false \
			  -fsplit-machine-functions -Wl,-Bsymbolic-non-weak-functions 
# -Wl,-mllvm -Wl,-EnablePushPopProfile -Wl,-mllvm -Wl,-EnableSpillBytesProfile $(ROOT)/push-pop-counter/lib.o
FDOIPRA_FLAGS:= -Wl,-mllvm -Wl,-fdo-ipra -Wl,-mllvm -Wl,-fdoipra-both-hot -Wl,-mllvm -Wl,-fdoipra-ch -Wl,-mllvm -Wl,-fdoipra-hc -Wl,-mllvm -Wl,-fdoipra-ccr=$(COLD_CALLSITE_RATIO)
#  -Wl,-mllvm -Wl,-debug-only=fdo-ipra
SOURCE:=$(mkfile_path)test.c $(mkfile_path)main.c

define build
	mkdir -p $1
	$(NCC) $2 -c -O3 $(mkfile_path)test.c -o $1/test.o
	$(NCC) $2 -c -O3 $(mkfile_path)main.c -o $1/main.o
	$(NCC) $2 $3 -fuse-ld=lld -Wl,--save-temps -O3 $1/test.o $1/main.o -o $1/main 
	objdump -d $1/main > $1/main.S
endef

.PHONY: all pgo-full hot_list final clean
all: final

pgo-full: $(NCC) $(SOURCE)
	$(call build,pgo-inst,-fprofile-generate=$(PROFILE_DIR) -flto=full,$(LINKER_FLAGS))
	./pgo-inst/main
	$(LLVM_ROOT_PATH)/bin/llvm-profdata merge -o pgo-inst/default.profdata pgo-inst/*.profraw
	$(call build,pgo-full,-fprofile-use=$(PROFILE_DIR)/default.profdata -flto=full,$(LINKER_FLAGS))

hot_list: $(HOT_LIST_CREATOR) pgo-full
	$(PERF) record -e cycles:u -o perf.data ./pgo-full/main
	$(HOT_LIST_CREATOR) \
		--binary="$(PWD)/pgo-full/main" \
		--profile="perf.data" \
		--output="hot_list" \
		--detail="hot_list.detail" \
		--hot_threshold=$(HOT_LIST_THRESHOLD)

final: $(NCC) $(SOURCE) hot_list
	$(call build,final,-fprofile-use=$(PROFILE_DIR)/default.profdata -flto=full,\
		$(LINKER_FLAGS) $(FDOIPRA_FLAGS) -Wl,-mllvm -fdoipra-hot-list=$(PWD)/hot_list)


clean:
	rm -rf pgo-full pgo-inst final