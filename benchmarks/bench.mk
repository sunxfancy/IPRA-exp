CC = $(PWD)/install/llvm/bin/clang
CXX = $(PWD)/install/llvm/bin/clang++
ENABLE_IPRA =  -mllvm -enable-ipra
NO_IPRA = 
COUNTER = $(PWD)/install/counter
FDO = $(PWD)/install/FDO
CREATE_REG = $(PWD)/install/autofdo/create_reg_prof


benchmarks: benchmarks/.snubench benchmarks/.dparser benchmarks/.vorbis-tools benchmarks/.C_FFT benchmarks/mysql-experiment

benchmarks/.snubench:
	cd benchmarks && wget http://www.cprover.org/goto-cc/examples/binaries/SNU-real-time.tar.gz && tar -xvf ./SNU-real-time.tar.gz && rm ./SNU-real-time.tar.gz
	touch benchmarks/.snubench

benchmarks/.dparser:
	cd benchmarks && wget https://github.com/jplevyak/dparser/archive/refs/heads/master.zip && unzip ./master.zip && rm ./master.zip
	touch benchmarks/.dparser

benchmarks/.vorbis-tools:
	cd benchmarks && wget https://github.com/xiph/vorbis-tools/archive/refs/heads/master.zip && unzip ./master.zip && rm ./master.zip
	touch benchmarks/.vorbis-tools

benchmarks/.C_FFT:
	cd benchmarks && wget https://github.com/sunxfancy/C_FFT/archive/refs/heads/master.zip && unzip ./master.zip && rm ./master.zip
	touch benchmarks/.C_FFT

benchmarks/mysql-experiment:
	cd benchmarks && git clone git@github.com:sunxfancy/mysql-experiment.git


include benchmarks/example/example.mk