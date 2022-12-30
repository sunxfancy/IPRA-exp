mkfile_path := $(dir $(abspath $(lastword $(MAKEFILE_LIST))))

all: 
	$(NCC) -O3 -S \
		-mllvm -debug-only=reg-profiler \
		-mllvm -EnablePushPopProfile=default.ppp \
		-mllvm -EnableSpillBytesProfile=default.sbp \
		-o main.S $(mkfile_path)main.c
	$(NCC) main.S -o main
	./main