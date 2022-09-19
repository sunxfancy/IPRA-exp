mkfile_path := $(dir $(abspath $(lastword $(MAKEFILE_LIST))))



build:
	cd $(mkfile_path) && $(NCC) -O3 -S  -mllvm -debug-only=x86-isel  1.c -o 1.S > output.txt