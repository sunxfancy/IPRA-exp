mkfile_path := $(dir $(abspath $(lastword $(MAKEFILE_LIST))))
PWD:=$(shell pwd)
PROFILE_DIR:=$(PWD)/pgo
LINKER_FLAGS:=-Wl,-z,keep-text-section-prefix -Wl,--build-id -fno-optimize-sibling-calls -Wl,-mllvm -Wl,-fast-isel=false \
			  -fsplit-machine-functions -Wl,-Bsymbolic-non-weak-functions \
			  -Wl,-mllvm -Wl,-EnablePushPopProfile -Wl,-mllvm -Wl,-EnableSpillBytesProfile $(ROOT)/push-pop-counter/lib.o
FDOIPRA_FLAGS:= -Wl,-mllvm -Wl,-debug-only=fdo-ipra -Wl,-mllvm -Wl,-fdo-ipra -Wl,-mllvm -Wl,-fdoipra-both-hot  # -Wl,-mllvm -Wl,-fdoipra-ch -Wl,-mllvm -Wl,-fdoipra-hc -Wl,-mllvm -Wl,-fdoipra-use-caller-reg 
#-Wl,-mllvm -Wl,-disable-thinlto-funcattrs -Wl,-mllvm -Wl,-fdoipra-new-impl

SOURCE:=$(mkfile_path)test.c $(mkfile_path)main.c


define build
	mkdir -p $1
	$(NCC) $2 -c -O3 $(mkfile_path)test.c -o $1/test.o
	$(NCC) $2 -c -O3 $(mkfile_path)main.c -o $1/main.o
	$(NCC) $2 $3 -fuse-ld=lld -Wl,--save-temps -O3 $1/test.o $1/main.o -o $1/main 
	$(NCC) $2 $3 -fuse-ld=lld -O3 $1/test.o $1/main.o -o $1/main -###
	objdump -d $1/main > $1/main.s
	$(LLVM_ROOT_PATH)/bin/llvm-dwarfdump $1/main
endef

.PHONY: all pgo full thin full-fdoipra thin-fdoipra clean lldb-full-fdoipra
all: thin full thin-fdoipra full-fdoipra
	@echo "Full LTO"
	@cat full/regprof3.raw
	@echo "Thin LTO"
	@cat thin/regprof3.raw

	@echo "Full LTO with FDOIPRA"
	@cat full-fdoipra/regprof3.raw
	@echo "Thin LTO with FDOIPRA"
	@cat thin-fdoipra/regprof3.raw
# /home/riple/IPRA-exp/install/llvm/bin/ld.lld --help

pgo: $(NCC) $(SOURCE)
	mkdir -p pgo
	$(call build,pgo,-fprofile-generate=$(PROFILE_DIR) -flto=thin)
	./pgo/main
	$(LLVM_ROOT_PATH)/bin/llvm-profdata merge -o pgo/default.profdata pgo/*.profraw

full: pgo
	@rm -rf full/regprof3.raw
	$(call build,full,-fprofile-use=$(PROFILE_DIR)/default.profdata -flto=full -DMARK,$(LINKER_FLAGS))
	cd full && ./main

thin: pgo
	@rm -rf thin/regprof3.raw
	$(call build,thin,-fprofile-use=$(PROFILE_DIR)/default.profdata -flto=thin -DMARK,$(LINKER_FLAGS))
	cd thin && ./main

full-fdoipra: pgo
	@rm -rf full-fdoipra/regprof3.raw
	$(call build,full-fdoipra,-fprofile-use=$(PROFILE_DIR)/default.profdata -flto=full -DMARK,$(LINKER_FLAGS) $(FDOIPRA_FLAGS))
	cd full-fdoipra && ./main

thin-fdoipra: pgo
	@rm -rf thin-fdoipra/regprof3.raw
	$(call build,thin-fdoipra,-fprofile-use=$(PROFILE_DIR)/default.profdata -flto=thin -DMARK,$(LINKER_FLAGS) $(FDOIPRA_FLAGS))
	cd thin-fdoipra && ./main

clean:
	rm -rf pgo full thin thin-fdoipra full-fdoipra