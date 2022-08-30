

build:
	cd spec2017/cpu2017 && source ./shrc && \
		runcpu --action build --size ref --tune peak --config ct-v18-llvm-x86 --label llvm_ARCH_fdo1 intrate

bench:



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