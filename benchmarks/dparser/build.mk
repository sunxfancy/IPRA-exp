PWD := $(shell pwd)

all: 


build.dir/dparser.ipra:
	mkdir -p build.dir/dparser.ipra
	cd build.dir/dparser.ipra && cmake ../../source.dir/dparser-master -G Ninja \
	 	-DCMAKE_C_COMPILER=$(CC) \
		-DCMAKE_CXX_COMPILER=$(CXX) \
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
	 	-DCMAKE_C_COMPILER=$(CC) \
		-DCMAKE_CXX_COMPILER=$(CXX) \
		-DCMAKE_C_FLAGS="-fno-inline-functions -flto=full -fuse-ld=lld" \
		-DCMAKE_CXX_FLAGS="-fno-inline-functions -flto=full -fuse-ld=lld" \
		-DCMAKE_EXE_LINKER_FLAGS="-flto=full  -fuse-ld=lld" \
		-DCMAKE_SHARED_LINKER_FLAGS="-flto=full  -fuse-ld=lld" \
		-DCMAKE_MODULE_LINKER_FLAGS="-flto=full  -fuse-ld=lld" \
		-DCMAKE_BUILD_TYPE=Release \
		-DCMAKE_INSTALL_PREFIX=../../install.dir/dparser
	cd build.dir/dparser && ninja install



dparser:
	mkdir -p bench.dir/dparser
	cd bench.dir/dparser && $(FDO) config ../../source.dir/dparser-master \
		-DCMAKE_BUILD_TYPE=Release \
		-DCMAKE_C_FLAGS="-fno-inline-functions" \
		-DCMAKE_CXX_FLAGS="-fno-inline-functions"

	cd bench.dir/dparser && $(FDO) build --lto=full -s ../../ipra/DParser.yaml --propeller
	cd bench.dir/dparser && $(FDO) test  --propeller
	cd bench.dir/dparser && $(CREATE_REG) --profile=labeled/Propeller0.data --binary=labeled/make_dparser > prof.txt

dparser.ipra:
	mkdir -p bench.dir/dparser.ipra
	cd bench.dir/dparser.ipra && cmake ../../source.dir/dparser-master -G Ninja \
	 	-DCMAKE_C_COMPILER=$(CC) \
		-DCMAKE_CXX_COMPILER=$(CXX) \
		-DCMAKE_C_FLAGS="-fno-inline-functions -flto=full -fuse-ld=lld" \
		-DCMAKE_CXX_FLAGS="-fno-inline-functions -flto=full -fuse-ld=lld" \
		-DCMAKE_EXE_LINKER_FLAGS="-flto=full  -fuse-ld=lld -Wl,-mllvm -Wl,-enable-ipra -Wl,-mllvm -Wl,-ipra-profile=../dparser/prof.txt" \
		-DCMAKE_SHARED_LINKER_FLAGS="-flto=full  -fuse-ld=lld -Wl,-mllvm -Wl,-enable-ipra -Wl,-mllvm -Wl,-ipra-profile=../dparser/prof.txt" \
		-DCMAKE_MODULE_LINKER_FLAGS="-flto=full  -fuse-ld=lld -Wl,-mllvm -Wl,-enable-ipra -Wl,-mllvm -Wl,-ipra-profile=../dparser/prof.txt" \
		-DCMAKE_BUILD_TYPE=Release \
	cd bench.dir/dparser.ipra && ninja 