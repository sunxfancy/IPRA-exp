mkfile_path := $(dir $(abspath $(lastword $(MAKEFILE_LIST))))
PWD := $(shell pwd)
GCC_VERSION=gcc-10.4.0
INSTRUMENTED_PROF=$(PWD)/build.dir/instrumented/profiles

RUN_CPU := export PATH=/data/googlemarks/numactl:$$PATH; cd spec2017/cpu2017 && source ./shrc && BASE_DIR=$(PWD) runcpu


build: spec2017/cpu2017
	cp -f $(mkfile_path)pgo-fulllto.cfg $(PWD)
	$(RUN_CPU) --action build  --config $(PWD)/pgo-fulllto.cfg --tune peak --define reprofile=1 --define runpmu=1 intrate ^548
	$(RUN_CPU) --action build  --config $(PWD)/pgo-fulllto.cfg --tune peak --label=ipra --define reprofile=0 --define runpmu=1 intrate ^548 
	$(RUN_CPU) --action build  --config $(PWD)/pgo-fulllto.cfg --tune peak --label=fdoipra --define reprofile=0 --define runpmu=1 intrate ^548 
	$(RUN_CPU) --action build  --config $(PWD)/pgo-fulllto.cfg --tune peak --label=fdoipra2 --define reprofile=0 --define runpmu=1 intrate ^548 
	$(RUN_CPU) --action build  --config $(PWD)/pgo-fulllto.cfg --tune peak --label=fdoipra3 --define reprofile=0 --define runpmu=1 intrate ^548 
	$(RUN_CPU) --action build  --config $(PWD)/pgo-fulllto.cfg --tune peak --label=bfdoipra --define reprofile=0 --define runpmu=1 intrate ^548 
	$(RUN_CPU) --action build  --config $(PWD)/pgo-fulllto.cfg --tune peak --label=bfdoipra2 --define reprofile=0 --define runpmu=1 intrate ^548 
	$(RUN_CPU) --action build  --config $(PWD)/pgo-fulllto.cfg --tune peak --label=bfdoipra3 --define reprofile=0 --define runpmu=1 intrate ^548 

bench:
	$(RUN_CPU) --action run  --config $(PWD)/pgo-fulllto.cfg --tune peak --define reprofile=1 --define runpmu=1 intrate ^548
	$(RUN_CPU) --action run  --config $(PWD)/pgo-fulllto.cfg --tune peak --label=ipra --define reprofile=0 --define runpmu=1 intrate ^548 
	$(RUN_CPU) --action run  --config $(PWD)/pgo-fulllto.cfg --tune peak --label=fdoipra --define reprofile=0 --define runpmu=1 intrate ^548 
	$(RUN_CPU) --action run  --config $(PWD)/pgo-fulllto.cfg --tune peak --label=fdoipra2 --define reprofile=0 --define runpmu=1 intrate ^548 
	$(RUN_CPU) --action run  --config $(PWD)/pgo-fulllto.cfg --tune peak --label=fdoipra3 --define reprofile=0 --define runpmu=1 intrate ^548 
	$(RUN_CPU) --action run  --config $(PWD)/pgo-fulllto.cfg --tune peak --label=bfdoipra --define reprofile=0 --define runpmu=1 intrate ^548 
	$(RUN_CPU) --action run  --config $(PWD)/pgo-fulllto.cfg --tune peak --label=bfdoipra2 --define reprofile=0 --define runpmu=1 intrate ^548 
	$(RUN_CPU) --action run  --config $(PWD)/pgo-fulllto.cfg --tune peak --label=bfdoipra3 --define reprofile=0 --define runpmu=1 intrate ^548 

spec2017/cpu2017: download/googlemarks
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