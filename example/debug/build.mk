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


bug5.test: bug5.correct bug5.wrong
	./$(basename $@).correct 10
	./$(basename $@).wrong 10

bug5.ll: $(mkfile_path)bug5.cpp $(mkfile_path)build.mk $(NCXX)
	$(NCXX) -S -O3 -emit-llvm $(mkfile_path)bug5.cpp -o bug5.ll

bug5.correct: bug5.ll $(mkfile_path)build.mk $(NCXX)
	$(NCXX) -S bug5.ll -o $@.S
	$(NCXX) $@.S -o $@

bug5.wrong: bug5.ll $(mkfile_path)build.mk $(NCXX)
	cp bug5.ll bug5-wrong.ll
	sed -i 's/attributes #0 = {/attributes #0 = { "no_callee_saved_registers"/g' bug5-wrong.ll
	$(NCXX) -S -O3 bug5-wrong.ll -o $@.S
	$(NCXX) $@.S -o $@