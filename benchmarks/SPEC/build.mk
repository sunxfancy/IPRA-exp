mkfile_path := $(dir $(abspath $(lastword $(MAKEFILE_LIST))))
PWD := $(shell pwd)
GCC_VERSION=gcc-10.4.0
INSTRUMENTED_PROF=$(PWD)/build.dir/instrumented/profiles

build:
	cd spec2017/cpu2017 && source ./shrc && \
		BASE_DIR=$(PWD) runcpu --action build  --config $(mkfile_path)propeller-thinlto.cfg --tune peak --define reprofile=1 intrate

download: download/googlemarks
	mpm fetch -a platforms/benchmarks/googlemarks/spec2017 spec2017

download/gperftools:
	fileutil untar /x20/teams/googlemarks/library/gperftools.tar
	mkdir -p download && touch $@

download/googlemarks:
	sudo mkdir -p /data/googlemarks
	sudo chown xiaofans /data/googlemarks
	chmod a+x /data/googlemarks
	cd /data/googlemarks && mpm fetch -a third_party/libnuma/numactl numactl
	mkdir -p download && touch $@