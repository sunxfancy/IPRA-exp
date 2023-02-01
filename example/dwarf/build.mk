mkfile_path := $(dir $(abspath $(lastword $(MAKEFILE_LIST))))
PWD:=$(shell pwd)
#  -mllvm -fdoipra-dwarf
OPT:=-O3
CFLAGS:=-mllvm -fdo-ipra -mllvm -fdoipra-both-hot -mllvm -fdoipra-dwarf -mllvm -debug-only=fdo-ipra -fno-optimize-sibling-calls -mllvm -fast-isel=false -fsplit-machine-functions # -mllvm -print-after-all
LDFLAGS:=-Wl,-mllvm -Wl,-fdo-ipra -Wl,-mllvm -Wl,-fdoipra-both-hot  -Wl,-mllvm -Wl,-debug-only=fdo-ipra -fno-optimize-sibling-calls -Wl,-mllvm -Wl,-fast-isel=false -fsplit-machine-functions

.PHONY: all run example

all:
	$(NCXX) -I$(mkfile_path) -g $(mkfile_path)main.cpp `$(LLVM_ROOT_PATH)/bin/llvm-config --cxxflags --ldflags --system-libs --libs core orcjit native` -O3 -o toy
	
run:
	./toy < $(mkfile_path)fib.ks 2> fib.ll

test:
	$(NCXX) -fprofile-generate=$(PWD)  $(OPT) $(mkfile_path)example.cpp -o example
	rm -rf *.profraw *.profdata
	./example
	$(LLVM_ROOT_PATH)/bin/llvm-profdata merge -o example.profdata *.profraw
	$(NCXX) $(OPT) -g -fprofile-use=$(PWD)/example.profdata $(CFLAGS) $(mkfile_path)example.cpp -o example > example.log
	$(LLVM_ROOT_PATH)/bin/llvm-dwarfdump ./example

lldb:
	lldb -- ./example

p1:
	$(NCC) $(OPT) -g -c $(CFLAGS) $(mkfile_path)p1.c -o p1.o > p1.log


# $(LLVM_ROOT_PATH)/bin/llvm-dwarfdump ./example
 