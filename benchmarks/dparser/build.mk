PWD := $(shell pwd)

all: 

common_compiler_flags := -fuse-ld=lld -fno-inline-functions
common_linker_flags := -fuse-ld=lld

gen_compiler_flags = -DCMAKE_C_FLAGS=$(1) -DCMAKE_CXX_FLAGS=$(1)
gen_linker_flags   = -DCMAKE_EXE_LINKER_FLAGS=$(1) -DCMAKE_SHARED_LINKER_FLAGS=$(1) -DCMAKE_MODULE_LINKER_FLAGS=$(1)
gen_build_flags = $(call gen_compiler_flags,"$(common_compiler_flags) $(1)") $(call gen_linker_flags,"$(common_linker_flags) $(2)")
COMMA := ,

build.dir/dparser.ipra:
	mkdir -p build.dir/dparser.ipra
	cd build.dir/dparser.ipra && cmake ../../source.dir/dparser-master -G Ninja \
	 	-DCMAKE_C_COMPILER=$(NCC) \
		-DCMAKE_CXX_COMPILER=$(NCXX) \
		-DCMAKE_C_FLAGS="-fno-inline-functions -flto=full -fuse-ld=lld" \
		-DCMAKE_CXX_FLAGS="-fno-inline-functions -flto=full -fuse-ld=lld" \
		-DCMAKE_EXE_LINKER_FLAGS="-flto=full  -fuse-ld=lld -Wl,-mllvm -Wl,-enable-ipra" \
		-DCMAKE_SHARED_LINKER_FLAGS="-flto=full  -fuse-ld=lld -Wl,-mllvm -Wl,-enable-ipra" \
		-DCMAKE_MODULE_LINKER_FLAGS="-flto=full  -fuse-ld=lld -Wl,-mllvm -Wl,-enable-ipra" \
		-DCMAKE_BUILD_TYPE=Release \
		-DCMAKE_INSTALL_PREFIX=../../install.dir/dparser.ipra
	cd build.dir/dparser.ipra && ninja install


build.dir/dparser:
	mkdir -p build.dir/dparser
	cd build.dir/dparser && cmake ../../source.dir/dparser-master -G Ninja \
	 	-DCMAKE_C_COMPILER=$(NCC) \
		-DCMAKE_CXX_COMPILER=$(NCXX) \
		-DCMAKE_C_FLAGS="-fno-inline-functions -flto=full -fuse-ld=lld" \
		-DCMAKE_CXX_FLAGS="-fno-inline-functions -flto=full -fuse-ld=lld" \
		-DCMAKE_EXE_LINKER_FLAGS="-flto=full  -fuse-ld=lld" \
		-DCMAKE_SHARED_LINKER_FLAGS="-flto=full  -fuse-ld=lld" \
		-DCMAKE_MODULE_LINKER_FLAGS="-flto=full  -fuse-ld=lld" \
		-DCMAKE_BUILD_TYPE=Release \
		-DCMAKE_INSTALL_PREFIX=../../install.dir/dparser
	cd build.dir/dparser && ninja install



dparser:
	mkdir -p build.dir/dparser
	$(FDO) config dparser-master -DCMAKE_BUILD_TYPE=Release 
	$(FDO) build --lto=full -s ../../ipra/DParser.yaml --pgo
	$(FDO) test  --propeller
	$(CREATE_REG) --profile=labeled/Propeller0.data --binary=labeled/make_dparser > prof.txt

dparser.ipra:
	mkdir -p bench.dir/dparser.ipra
	cd bench.dir/dparser.ipra && cmake dparser-master -G Ninja \
	 	-DCMAKE_C_COMPILER=$(NCC) \
		-DCMAKE_CXX_COMPILER=$(NCXX) \
		-DCMAKE_C_FLAGS="-fno-inline-functions -flto=full -fuse-ld=lld" \
		-DCMAKE_CXX_FLAGS="-fno-inline-functions -flto=full -fuse-ld=lld" \
		-DCMAKE_EXE_LINKER_FLAGS="-flto=full  -fuse-ld=lld -Wl,-mllvm -Wl,-enable-ipra -Wl,-mllvm -Wl,-ipra-profile=../dparser/prof.txt" \
		-DCMAKE_SHARED_LINKER_FLAGS="-flto=full  -fuse-ld=lld -Wl,-mllvm -Wl,-enable-ipra -Wl,-mllvm -Wl,-ipra-profile=../dparser/prof.txt" \
		-DCMAKE_MODULE_LINKER_FLAGS="-flto=full  -fuse-ld=lld -Wl,-mllvm -Wl,-enable-ipra -Wl,-mllvm -Wl,-ipra-profile=../dparser/prof.txt" \
		-DCMAKE_BUILD_TYPE=Release \
	cd bench.dir/dparser.ipra && ninja 