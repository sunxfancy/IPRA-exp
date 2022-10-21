mkfile_path := $(dir $(abspath $(lastword $(MAKEFILE_LIST))))
include $(mkfile_path)../common.mk

MYSQL_NAME := mysql-8.0.30
MYSQL_PACKAGE_NAME := mysql-boost-8.0.30.tar.gz
MYSQL_SOURCE := $(PWD)/$(MYSQL_NAME)

OPENSSL_NAME := openssl-3.0.5
OPENSSL_PACKAGE_NAME := $(OPENSSL_NAME).tar.gz
OPENSSL_SOURCE := $(PWD)/$(OPENSSL_NAME)

NCURSE_NAME := ncurses-6.3
NCURSE_PACKAGE_NAME := $(NCURSE_NAME).tar.gz
NCURSE_SOURCE := $(PWD)/$(NCURSE_NAME)

DBT2_NAME := dbt2-0.37.50.16
DBT2_PACKAGE_NAME := $(DBT2_NAME).tar.gz
DBT2_SOURCE := $(PWD)/$(DBT2_NAME)

common_compiler_flags += -DDBUG_OFF -DBOOST_NO_CXX98_FUNCTION_BASE -O3 -DNDEBUG  -Wno-error -Wno-error=int-conversion -Wno-error=implicit-function-declaration

MAIN_BIN = bin/mysqld
BUILD_ACTION=build_mysql
BUILD_TARGET=mysqld

define switch_binary
	rm -f install.dir/bin/mysqld
	ln -s $(PWD)/build.dir/$(1)/bin/mysqld$(2) install.dir/bin/mysqld
endef

define build_mysql
	rm -f /tmp/count-push-pop.txt 
	touch /tmp/count-push-pop.txt
	mkdir -p build.dir/$(1)
	mkdir -p install.dir/
	cd build.dir/$(1) && cmake -G Ninja $(MYSQL_SOURCE) \
		-DWITH_BOOST=$(MYSQL_SOURCE)/boost/boost_1_77_0 \
		-DCMAKE_INSTALL_PREFIX=$(PWD)/install.dir \
		-DCMAKE_LINKER="lld" \
		-DCMAKE_BUILD_TYPE=Release \
		-DWITH_LTO=OFF \
		-DWITH_SSL=$(OPENSSL_SOURCE)/install \
		-DCMAKE_C_COMPILER="$(NCC)" \
		-DCMAKE_CXX_COMPILER="$(NCXX)" \
		-DWITH_ROUTER=Off \
		-DWITH_UNIT_TESTS=Off \
		-DENABLED_PROFILING=Off \
		-DBUILD_SHARED_LIBS=OFF \
		-DWITHOUT_GROUP_REPLICATION=ON \
		-Dprotobuf_BUILD_SHARED_LIBS=OFF \
		-DCMAKE_PREFIX_PATH="$(NCURSE_SOURCE)/install/;$(GOOGLE_SYSTEM_PATH)/lib64"  \
		$(2) > conf.log
	cd build.dir/$(1) && CLANG_PROXY_FOCUS=mysqld \
		CLANG_PROXY_ARGS="$(4)" CLANG_PROXY_VAR="$(5)" \
		time -o time.log ninja $(3) -j $(shell nproc) -v > build.log \
		|| { echo "*** build failed ***"; exit 1 ; }
	echo "---------$(1)---------" >> ../mysql.raw
	cat /tmp/count-push-pop.txt >> ../mysql.raw 
	echo "---------$(1)---------" >> ../mysql.output
	cat /tmp/count-push-pop.txt | $(COUNTSUM) >> ../mysql.output 
	cat /tmp/count-push-pop.txt | $(COUNTSUM) > $(1)
	
	$(call switch_binary,$(1))
	$(call mv_binary,$(1))
endef



define copy_to_server
	/bin/cp -f $(mkfile_path)loadtest-funcs.sh ./loadtest-funcs.sh
	$(RUN_FOR_REMOTE) cp $(mkfile_path)loadtest-funcs-remote.sh ./loadtest-funcs.sh
	$(COPY_TO_REMOTE) /tmp/IPRA-exp/sysbench/
	$(COPY_TO_REMOTE) $(PWD)/loadtest-funcs.sh 
	$(COPY_TO_REMOTE) $(PWD)/install.dir/
	$(COPY_TO_REMOTE) $(PWD)/build.dir/$(1)/$(MAIN_BIN)$(2)
	$(COPY_TO_REMOTE) $(INSTALL_PATH)/sub
	$(RUN) ./loadtest-funcs.sh setup_mysql $(1) 2>&1
endef


define gen_perfdata

$(1)$(2).perfdata: $(1) 
	$(call switch_binary,$(1),$(2))
	$(call copy_to_server,$(1),$(2))
	$(RUN) ./loadtest-funcs.sh run_perf -o "$$@" -- \
			./loadtest-funcs.sh run_sysbench_loadtest "$(1)$(2)" \
		|| { echo "*** loadtest failed ***" ; rm -f $$@ ; exit 1; }
	$(COPY_BACK) $(PWD)/$$@
	$(RUN_ON_REMOTE) rm -rf $(PWD)/

endef

define gen_bench

$(1)$(2).bench: $(1)
	$(call switch_binary,$(1),$(2))
	$(call copy_to_server,$(1),$(2))
	$(RUN) ./loadtest-funcs.sh run_sysbench_benchmark $(1)$(2) 5 
	mkdir -p bench.dir/
	$(COPY_BACK) $(PWD)/bench.dir/$(1)$(2)
	$(RUN_ON_REMOTE) rm -rf $(PWD)/

endef 

additional_compiler_flags = $(if $(findstring thin,$(1)),-flto=thin)  $(if $(findstring full,$(1)),-flto=full) 
additional_linker_flags = $(if $(findstring thin,$(1)),-flto=thin)  $(if $(findstring full,$(1)),-flto=full) 
additional_original_flags = -DFPROFILE_USE=1 -DFPROFILE_DIR="$(INSTRUMENTED_PROF)/default.profdata"

$(eval $(call gen_pgo_targets,thin))
$(eval $(call gen_pgo_targets,full))

debug-makefile:
	$(warning $(call gen_pgo_targets,full))

instrumented: $(MYSQL_NAME)/README
	$(call build_mysql,$@,$(call gen_build_flags_ins) -DFPROFILE_GENERATE=1 -DFPROFILE_DIR="$(INSTRUMENTED_PROF)/%4m.profraw",install)


$(INSTRUMENTED_PROF)/default.profdata: instrumented
	rm -rf $(INSTRUMENTED_PROF)
	bash "$(mkfile_path)loadtest-funcs.sh" setup_mysql instrumented 2>&1 
	bash "$(mkfile_path)loadtest-funcs.sh" run_sysbench_loadtest instrumented
	cd $(INSTRUMENTED_PROF) ; \
	$(LLVM_BIN)/llvm-profdata merge -output=$@ *.profraw ; \
	rm *.profraw


$(DBT2_NAME)/README-MYSQL: $(DBT2_NAME).tar.gz $(mkfile_path)/packages/dbt2.patch
	tar xzvf $<
	patch -p1 < $(lastword $^)
	touch $@

$(MYSQL_PACKAGE_NAME):
	wget https://dev.mysql.com/get/Downloads/MySQL-8.0/$(MYSQL_PACKAGE_NAME)

$(MYSQL_NAME)/README: $(MYSQL_PACKAGE_NAME) $(OPENSSL_NAME)/install $(NCURSE_NAME)/install $(mkfile_path)/packages/mysql.patch
	tar xzvf $<
	cd "$(MYSQL_NAME)" ; patch -p1 < "$(lastword $^)"
	touch $@

$(OPENSSL_PACKAGE_NAME):
	wget https://www.openssl.org/source/$(OPENSSL_PACKAGE_NAME)

$(OPENSSL_NAME)/README: $(OPENSSL_PACKAGE_NAME)
	tar xzvf $<
	touch $@

$(OPENSSL_NAME)/install: $(OPENSSL_NAME)/README
	cd $(OPENSSL_SOURCE) && CC=$(NCC) CXX=$(NCXX) ./config no-shared --prefix=$(OPENSSL_SOURCE)/install \
	 && make depend -j$(shell nproc) && make -j$(shell nproc)
	cd $(OPENSSL_SOURCE) && make install_sw

$(NCURSE_NAME)/README:
	wget https://ftp.gnu.org/pub/gnu/ncurses/$(NCURSE_PACKAGE_NAME)
	tar xzvf $(NCURSE_PACKAGE_NAME)
	touch $@

$(NCURSE_NAME)/install: $(NCURSE_NAME)/README
	cd $(NCURSE_SOURCE) && CC=$(NCC) CXX=$(NCXX) ./configure --prefix=$(NCURSE_SOURCE)/install
	cd $(NCURSE_SOURCE) && make -j$(shell nproc) && make install
	cp $(mkfile_path)/packages/CursesConfig.cmake $(NCURSE_SOURCE)/install

build-ncurse: $(NCURSE_NAME)/install


dbt2-tool/bin/datagen dbt2-tool/bin/driver &: $(DBT2_SOURCE)/Makefile.in
	cd $(DBT2_SOURCE); \
	make distclean ; \
	$(DBT2_SOURCE)/configure --prefix=$(PWD)/dbt2-tool \
		--with-mysql=$(PWD)/vanilla-mysql/install ; \
	make -j20 install

dbt2-tool/data/warehouse.data: dbt2-tool/bin/datagen
	rm -fr dbt2-tool/data
	mkdir -p dbt2-tool/data
	$< -w 30 -d dbt2-tool/data --mysql
	cd dbt2-tool/data ; \
	mapfile -t datafiles < <(find . -name "*.data" -type f) ; \
	for d in "$${datafiles[@]}" ; do \
		mv $$d $${d}.origin ; \
		iconv -f iso8859-1 -t utf-8 $${d}.origin -o $$d ; \
		rm $${d}.origin ; \
	done

