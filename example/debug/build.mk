mkfile_path := $(dir $(abspath $(lastword $(MAKEFILE_LIST))))
# CFLAGS := -mllvm -print-after-all 
CFLAGS := -mllvm -debug-only=x86-isel -mllvm -print-isel-input -mllvm -print-after-isel -mllvm -print-regmask-num-regs=-1

all: bug3.test bug4.test

%.test: %.correct %.wrong
	./$(basename $@).correct
	./$(basename $@).wrong

%.correct: $(mkfile_path)%.cpp $(mkfile_path)build.mk $(NCXX)
	$(NCXX) -O3 -fno-optimize-sibling-calls $(CFLAGS) -S $(mkfile_path)$(basename $@).cpp -o $@.S 2>&1 > $@.log
	$(NCXX) $@.S -o $@

%.wrong: $(mkfile_path)%.cpp $(mkfile_path)build.mk $(NCXX)
	$(NCXX) -O3 -fno-optimize-sibling-calls $(CFLAGS) -S -DNCSR $(mkfile_path)$(basename $@).cpp -o $@.S 2>&1 > $@.log 
	$(NCXX) $@.S -o $@
