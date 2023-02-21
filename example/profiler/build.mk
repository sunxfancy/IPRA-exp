mkfile_path := $(dir $(abspath $(lastword $(MAKEFILE_LIST))))
.PHONY: all thread switch

all: 
	$(NCC) -O3 -S \
		-mllvm -debug-only=reg-profiler \
		-mllvm -EnablePushPopProfile \
		-mllvm -EnableSpillBytesProfile \
		-o main.S $(mkfile_path)main.c
	$(NCC) main.S -o main
	./main

thread: 
	$(NCC) -c -O3 $(mkfile_path)lib.c -o lib.o
	$(NCC) -O3 -S \
		-mllvm -debug-only=reg-profiler \
		-mllvm -EnablePushPopProfile \
		-mllvm -EnableSpillBytesProfile \
		-o thread.S $(mkfile_path)thread.c 
	$(NCC) -L.  -Wl,-rpath,.  thread.S lib.o -o thread 
	./thread
	$(NCC) -O3 -S $(mkfile_path)thread.c -o thread2.S
	$(NCC) -L.  -Wl,-rpath,.  thread2.S -o thread2
	$(DRRUN) thread2

# $(NCXX) -O3 -c  $(mkfile_path)lib.cpp -o lib.o 
# $(NCXX) -c thread.S -o thread.o
# $(NCXX) thread.o lib.o -o thread

thread-cpp:
	$(NCXX) -O3 -S \
		-mllvm -debug-only=reg-profiler \
		-mllvm -EnablePushPopProfile \
		-mllvm -EnableSpillBytesProfile \
		-o thread.S $(mkfile_path)thread.cpp 

switch:
	$(NCC) -O3 -S \
		-mllvm -debug-only=reg-profiler \
		-mllvm -EnablePushPopProfile \
		-mllvm -EnableSpillBytesProfile \
		-o switch.S $(mkfile_path)switch.c 
	$(NCC) switch.S $(ROOT)/push-pop-counter/lib.o -o switch 
	./switch