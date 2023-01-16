mkfile_path := $(dir $(abspath $(lastword $(MAKEFILE_LIST))))
# NCC:= clang


define get_count
	@echo "push pop count:"
	@cat $(1) | grep push | wc -l
	@cat $(1) | grep pop | wc -l
endef

all: 
	$(NCC) -O3 -S $(mkfile_path)both-ncsr.c -fno-optimize-sibling-calls -emit-llvm -o fdo_ipra_both.ll
	cp fdo_ipra_both.ll only_no_caller.ll
	cp fdo_ipra_both.ll only_no_callee.ll
	cp fdo_ipra_both.ll no_ipra_both.ll
	sed -i 's/attributes #0 = {/attributes #0 = { "no_caller_saved_registers"/g' fdo_ipra_both.ll
	sed -i 's/attributes #2 = {/attributes #2 = { "no_callee_saved_registers"/g' fdo_ipra_both.ll
	sed -i 's/attributes #0 = {/attributes #0 = { "no_caller_saved_registers"/g' only_no_caller.ll
	sed -i 's/attributes #2 = {/attributes #2 = { "no_callee_saved_registers"/g' only_no_callee.ll
	$(NCC) -O3 -S -mllvm -EnablePushPopProfile -mllvm -EnableSpillBytesProfile fdo_ipra_both.ll -o fdo_ipra_both.S
	$(NCC) fdo_ipra_both.S $(ROOT)/push-pop-counter/lib.o -o fdo_ipra_both
	
	$(NCC) -O3 -S -mllvm -EnablePushPopProfile -mllvm -EnableSpillBytesProfile only_no_caller.ll -o only_no_caller.S
	$(NCC) only_no_caller.S $(ROOT)/push-pop-counter/lib.o -o only_no_caller
	$(NCC) -O3 -S -mllvm -EnablePushPopProfile -mllvm -EnableSpillBytesProfile only_no_callee.ll -o only_no_callee.S
	$(NCC) only_no_callee.S $(ROOT)/push-pop-counter/lib.o -o only_no_callee
	$(NCC) -O3 -S -mllvm -EnablePushPopProfile -mllvm -EnableSpillBytesProfile no_ipra_both.ll -o no_ipra_both.S
	$(NCC) no_ipra_both.S $(ROOT)/push-pop-counter/lib.o -o no_ipra_both

# nm fdo_ipra
	
	@rm -f regprof3.raw
	./no_ipra_both
	@cat regprof3.raw
	$(call get_count,fdo_ipra_both.S)

	@rm -f regprof3.raw
	./only_no_caller
	@cat regprof3.raw
	$(call get_count,only_no_caller.S)

	@rm -f regprof3.raw
	./only_no_callee
	@cat regprof3.raw
	$(call get_count,only_no_callee.S)

	@rm -f regprof3.raw
	./fdo_ipra_both
	@cat regprof3.raw
	$(call get_count,no_ipra_both.S)

# ./no_ipra


old:
	$(NCC) -O3 -S -mllvm -fdo-ipra -mllvm -debug-only=fdo-ipra -D_NCSR $(mkfile_path)no-caller-saved.c -emit-llvm -o fdo_ipra.ll
	$(NCC) -O3 -S fdo_ipra.ll -o fdo_ipra.S
	$(NCC) fdo_ipra.S -o fdo_ipra
	$(call get_count,fdo_ipra.S)
	$(NCC) -O3 -S $(mkfile_path)no-caller-saved.c -emit-llvm -o no_ipra.ll
	$(NCC) -O3 -S no_ipra.ll -o no_ipra.S
	$(NCC) no_ipra.S -o no_ipra
	$(call get_count,no_ipra.S)

	$(NCC) -O3 -S $(mkfile_path)no-callee-saved.c -emit-llvm -o fdo_ipra2.ll
	sed -i 's/attributes #0 = {/attributes #0 = { "no_callee_saved_registers"/g' fdo_ipra2.ll
	$(NCC) -O3 -S fdo_ipra2.ll -o fdo_ipra2.S
	$(NCC) fdo_ipra2.S -o fdo_ipra2
	$(call get_count,fdo_ipra2.S)
	$(NCC) -O3 -S $(mkfile_path)no-callee-saved.c -emit-llvm -o no_ipra2.ll
	$(NCC) -O3 -S no_ipra2.ll -o no_ipra2.S
	$(NCC) no_ipra2.S -o no_ipra2
	$(call get_count,no_ipra2.S)