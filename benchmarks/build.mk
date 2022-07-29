
benchmarks: benchmarks/mysql benchmarks/clang

DonwloadTargets = download/snubench download/dparser download/vorbis-tools download/C_FFT 

build-benchmarks-dir:
	mkdir -p build/benchmarks

.PHONY: $(DonwloadTargets)
download-benchmarks: build-benchmarks-dir $(DonwloadTargets)
	
download/snubench:
	cd build/benchmarks && wget http://www.cprover.org/goto-cc/examples/binaries/SNU-real-time.tar.gz && tar -xvf ./SNU-real-time.tar.gz && rm ./SNU-real-time.tar.gz

download/dparser:
	cd build/benchmarks && wget https://github.com/jplevyak/dparser/archive/refs/heads/master.zip && unzip ./master.zip && rm ./master.zip

download/vorbis-tools:
	cd build/benchmarks && wget https://github.com/xiph/vorbis-tools/archive/refs/heads/master.zip && unzip ./master.zip && rm ./master.zip

download/C_FFT:
	cd build/benchmarks && wget https://github.com/sunxfancy/C_FFT/archive/refs/heads/master.zip && unzip ./master.zip && rm ./master.zip


build/benchmarks/mysql-experiment/packages/mysql-boost-8.0.30.tar.gz:
	mkdir -p build/benchmarks
	cd build/benchmarks && git clone git@github.com:sunxfancy/mysql-experiment.git
	cd build/benchmarks/mysql-experiment/packages && wget https://dev.mysql.com/get/Downloads/MySQL-8.0/mysql-boost-8.0.30.tar.gz

define save_to_output
	rm -rf build/benchmarks/mysql-experiment/$(1)
	rm -f /tmp/count-push-pop.txt 
	cd build/benchmarks/mysql-experiment && make $(1)/install/bin/mysqld LLVM_INSTALL_BIN=$(PWD)/install/llvm/bin
	echo "---------$(1)---------" >> build/benchmarks/mysql.output
	cat /tmp/count-push-pop.txt >> build/benchmarks/mysql.output 
endef

benchmarks/mysql: build/benchmarks/mysql-experiment/packages/mysql-boost-8.0.30.tar.gz
	rm -f build/benchmarks/mysql.output
	$(call save_to_output,pgolto-mysql)
	$(call save_to_output,pgolto-ipra-mysql)
	$(call save_to_output,pgolto-full-ipra-mysql)
	$(call save_to_output,pgolto-full-fdoipra-mysql)
	$(call save_to_output,pgolto-full-ipra-fdoipra-mysql)
	
export

SUBDIRS := $(patsubst %/build.mk,%,$(wildcard benchmarks/*/build.mk))

.PHONY: $(SUBDIRS)

$(SUBDIRS):
	mkdir -p build/$@
	$(MAKE) -C build/$@ -f $(PWD)/$@/build.mk

benchmarks/%: 
	mkdir -p build/$(dir $@)
	echo $(dir $@)
	$(MAKE) -C build/$(dir $@) -f $(PWD)/$(dir $@)build.mk $(notdir $@)
