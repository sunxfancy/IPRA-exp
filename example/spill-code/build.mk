mkfile_path := $(dir $(abspath $(lastword $(MAKEFILE_LIST))))

all:
	$(NCC) -O3 -S $(mkfile_path)case1.c -fno-optimize-sibling-calls -emit-llvm -o case1.ll
	cp case1.ll case1_fdo.ll
	sed -i 's/attributes #0 = {/attributes #0 = { "no_caller_saved_registers"/g' case1_fdo.ll
	$(NCC) -O3 -S -mllvm -EnablePushPopProfile -mllvm -EnableSpillBytesProfile case1.ll -o case1.S
	$(NCC) case1.S $(ROOT)/push-pop-counter/lib.o -o case1
	$(NCC) -O3 -S -mllvm -EnablePushPopProfile -mllvm -EnableSpillBytesProfile case1_fdo.ll -o case1_fdo.S
	$(NCC) case1_fdo.S $(ROOT)/push-pop-counter/lib.o -o case1_fdo
	@rm -f regprof3.raw
	./case1
	@cat regprof3.raw
	@rm -f regprof3.raw
	./case1_fdo
	@cat regprof3.raw



	$(NCC) -O3 -S $(mkfile_path)case2.c -fno-optimize-sibling-calls -emit-llvm -o case2.ll
	cp case2.ll case2_fdo.ll
	sed -i 's/attributes #0 = {/attributes #0 = { "no_callee_saved_registers"/g' case2_fdo.ll
	$(NCC) -O3 -S -mllvm -EnablePushPopProfile -mllvm -EnableSpillBytesProfile case2.ll -o case2.S
	$(NCC) case2.S $(ROOT)/push-pop-counter/lib.o -o case2
	$(NCC) -O3 -S -mllvm -EnablePushPopProfile -mllvm -EnableSpillBytesProfile case2_fdo.ll -o case2_fdo.S
	$(NCC) case2_fdo.S $(ROOT)/push-pop-counter/lib.o -o case2_fdo
	@rm -f regprof3.raw
	./case2
	@cat regprof3.raw
	@rm -f regprof3.raw
	./case2_fdo
	@cat regprof3.raw
