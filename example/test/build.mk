mkfile_path := $(dir $(abspath $(lastword $(MAKEFILE_LIST))))
PWD := $(shell pwd)


build:
	$(NCXX) -mllvm -bbidx_map=bbidx_map.txt $(mkfile_path)main.cpp -o main 


instrumented:
	mkdir -p /tmp/IPRA/example/profiles
	$(NCXX) -fprofile-generate=/tmp/IPRA/example/profiles $(mkfile_path)main.cpp -o main

pgo-build:
	$(NCXX) -fprofile-use=/tmp/IPRA/example/profiles $(mkfile_path)main.cpp -o main
