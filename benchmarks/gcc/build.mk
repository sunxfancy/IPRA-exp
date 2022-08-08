
GCC_VERSION=gcc-12.1.0

common_compiler_flags := -fuse-ld=lld
common_linker_flags := -fuse-ld=lld

gen_compiler_flags = CFLAGS=$(1) CXXFLAGS=$(1)
gen_linker_flags   = LDFLAGS=$(1)
gen_build_flags = $(call gen_compiler_flags,"$(common_compiler_flags) $(1)") $(call gen_linker_flags,"$(common_linker_flags) $(2)")
COMMA := ,

define build_gcc
	rm -f /tmp/count-push-pop.txt 
	touch /tmp/count-push-pop.txt
    mkdir -p build.dir/$(1)
	mkdir -p install.dir/$(1)
	cd build.dir/$(1) && ../../gcc-releases-$(GCC_VERSION)/configure -v \
		--build=x86_64-linux-gnu \
		--host=x86_64-linux-gnu \
		--target=x86_64-linux-gnu \
		--prefix=$(PWD)/install.dir/$(1) \
		--enable-checking=release \
		--enable-languages=c,c++ \
		--disable-multilib \
		CC=$(NCC) \
		CXX=$(NCXX) \
		$(2)
	cd build.dir/$(1) && make install-strip -j $(shell nproc) > build.log
	echo "---------$(1)---------" >> ../gcc.output
	cat /tmp/count-push-pop.txt >> ../gcc.output 
	touch .$(1)
endef

.instrumented: gcc-releases-$(GCC_VERSION)
	$(call build_gcc,instrumented,$(call gen_build_flags,,))


gcc-releases-$(GCC_VERSION):
	wget https://github.com/gcc-mirror/gcc/archive/refs/tags/releases/$(GCC_VERSION).zip && unzip $(GCC_VERSION) && rm -f $(GCC_VERSION).zip
	cd gcc-releases-$(GCC_VERSION) && contrib/download_prerequisites