CC = $(PWD)/install/llvm/bin/clang
CXX = $(PWD)/install/llvm/bin/clang++
ENABLE_IPRA =  -mllvm -enable-ipra
ENABLE_IPRA_LTO = -Wl,-mllvm -Wl,-enable-ipra
NO_IPRA = 
COUNTER = $(PWD)/install/counter
FDO = $(PWD)/install/FDO
CREATE_REG = $(PWD)/install/autofdo/create_reg_prof

DonwloadTargets = download/snubench download/dparser download/vorbis-tools download/C_FFT download/mysql-experiment
.PHONY: $(DonwloadTargets)
benchmarks: $(DonwloadTargets)

download/snubench:
	wget http://www.cprover.org/goto-cc/examples/binaries/SNU-real-time.tar.gz && tar -xvf ./SNU-real-time.tar.gz && rm ./SNU-real-time.tar.gz

download/dparser:
	wget https://github.com/jplevyak/dparser/archive/refs/heads/master.zip && unzip ./master.zip && rm ./master.zip

download/vorbis-tools:
	wget https://github.com/xiph/vorbis-tools/archive/refs/heads/master.zip && unzip ./master.zip && rm ./master.zip

download/C_FFT:
	wget https://github.com/sunxfancy/C_FFT/archive/refs/heads/master.zip && unzip ./master.zip && rm ./master.zip

download/mysql-experiment:
	git clone git@github.com:sunxfancy/mysql-experiment.git

include benchmarks/example-hotpath/example.mk
include benchmarks/example-scalable/example.mk
include benchmarks/example-virtualcall/example.mk
include benchmarks/example-no-caller-saved/example.mk

mysql:
	rm -f mysql.output
	rm -rf benchmarks/mysql-experiment/pgolto-mysql
	rm -f /tmp/count-push-pop.txt 
	cd benchmarks/mysql-experiment && make pgolto-mysql/install/bin/mysqld 
	cat /tmp/count-push-pop.txt >> mysql.output 
	echo "------------------" >> mysql.output
	rm -rf benchmarks/mysql-experiment/pgolto-ipra-mysql
	rm -f /tmp/count-push-pop.txt 
	cd benchmarks/mysql-experiment && make pgolto-ipra-mysql/install/bin/mysqld 
	cat /tmp/count-push-pop.txt >> mysql.output 
	echo "------------------" >> mysql.output
	rm -rf benchmarks/mysql-experiment/pgolto-ipra-full-mysql
	rm -f /tmp/count-push-pop.txt 
	cd benchmarks/mysql-experiment && make pgolto-ipra-full-mysql/install/bin/mysqld
	cat /tmp/count-push-pop.txt >> mysql.output 