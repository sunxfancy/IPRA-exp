mkfile_path := $(dir $(abspath $(lastword $(MAKEFILE_LIST))))
BENCHMARK=mysql
include $(mkfile_path)../common.mk

MYSQL_NAME := mysql-8.0.30
MYSQL_PACKAGE_NAME := mysql-boost-8.0.30.tar.gz
SOURCE := $(BUILD_PATH)/$(BENCHMARK)/$(MYSQL_NAME)

OPENSSL_NAME := openssl-3.0.5
OPENSSL_PACKAGE_NAME := $(OPENSSL_NAME).tar.gz
OPENSSL_SOURCE := $(BUILD_PATH)/$(BENCHMARK)/$(OPENSSL_NAME)

NCURSE_NAME := ncurses-6.3
NCURSE_PACKAGE_NAME := $(NCURSE_NAME).tar.gz
NCURSE_SOURCE := $(BUILD_PATH)/$(BENCHMARK)/$(NCURSE_NAME)

DBT2_NAME := dbt2-0.37.50.16
DBT2_PACKAGE_NAME := $(DBT2_NAME).tar.gz
DBT2_SOURCE := $(BUILD_PATH)/$(BENCHMARK)/$(DBT2_NAME)

common_compiler_flags += -DDBUG_OFF -DBOOST_NO_CXX98_FUNCTION_BASE -O3 -DNDEBUG \
	 -Wno-error -Wno-error=int-conversion -Wno-error=implicit-function-declaration -Wno-enum-constexpr-conversion

MAIN_BIN = bin/mysqld
BUILD_ACTION=build_mysql
BUILD_TARGET=mysqld

define switch_binary
	if [ ! -d "$(INSTALL_DIR)/bin" ]; then \
		mkdir -p $(BUILD_PATH)/$(BENCHMARK) && cp -r $(PWD)/install.dir $(BUILD_PATH)/$(BENCHMARK)/; fi
	rm -f $(INSTALL_DIR)/$(MAIN_BIN)
	cp $(PWD)/$(1)/$(MAIN_BIN)$(2) $(INSTALL_DIR)/$(MAIN_BIN)
endef

define build_mysql
	mkdir -p $(BUILD_DIR)/$(1)
	mkdir -p $(PWD)/$(1)/bin
	mkdir -p $(INSTALL_DIR)
	rm -f $(PWD)/$(1).count-push-pop 
	touch $(PWD)/$(1).count-push-pop
	cd $(BUILD_DIR)/$(1) && cmake -G Ninja $(SOURCE) \
		-DWITH_BOOST=$(SOURCE)/boost/boost_1_77_0 \
		-DCMAKE_INSTALL_PREFIX=$(INSTALL_DIR) \
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
		$(2) > $(PWD)/$(1)/conf.log	
	cd $(BUILD_DIR)/$(1) && CLANG_PROXY_FOCUS=mysqld \
		CLANG_PROXY_ARGS="$(4)" CLANG_PROXY_VAR="$(5)" \
		time -o $(PWD)/$(1)/time.log ninja $(3) -j $(shell nproc) -v > $(PWD)/$(1)/build.log \
		|| { echo "*** build failed ***"; exit 1 ; }
	if [ ! -d "$(PWD)/install.dir" ]; then \
		mkdir -p $(INSTALL_DIR) && cd $(BUILD_DIR)/$(1) && ninja install -v >> $(PWD)/$(1)/build.log; \
		if [ "$(1)" != "instrumented" ]; then \
			mv $(INSTALL_DIR) $(PWD)/install.dir; \
		fi; \
	fi
	echo "---------$(1)---------" >> ../mysql.raw
	cat $(PWD)/$(1).count-push-pop >> ../mysql.raw 
	echo "---------$(1)---------" >> ../mysql.output
	cat $(PWD)/$(1).count-push-pop | $(COUNTSUM) >> ../mysql.output 
	
	$(call mv_binary,$(1))
	$(call switch_binary,$(1))
endef



define copy_to_server
	$(RUN_FOR_REMOTE) cp $(mkfile_path)loadtest-funcs-remote.sh ./loadtest-funcs.sh
	$(COPY_TO_REMOTE) /tmp/IPRA-exp/sysbench/
	$(COPY_TO_REMOTE) $(PWD)/loadtest-funcs.sh 
	$(COPY_TO_REMOTE) $(INSTALL_DIR)/
	$(COPY_TO_REMOTE) $(PWD)/$(1)/$(MAIN_BIN)$(2)
	$(COPY_TO_REMOTE) $(INSTALL_PATH)/sub
	
endef


define gen_perfdata

$(1)$(2).perfdata: $(1) 
	$(call switch_binary,$(1),$(2))
	cp -f $(mkfile_path)loadtest-funcs.sh ./loadtest-funcs.sh
	$(call copy_to_server,$(1),$(2))
	cd $(BUILD_PATH)/$(BENCHMARK) && \
		$(RUN) $(mkfile_path)loadtest-funcs.sh setup_mysql $(1) 2>&1
	cd $(BUILD_PATH)/$(BENCHMARK) && \
		bash "$(mkfile_path)loadtest-funcs.sh" run_perf -o "$(BUILD_PATH)/$(BENCHMARK)/$$@" -- \
		bash "$(mkfile_path)loadtest-funcs.sh" run_sysbench_loadtest "$(1)$(2)" \
		|| { echo "*** loadtest failed ***" ; rm -f $(PWD)/$$@ ; exit 1; }
	$(COPY_BACK) $(PWD)/$$@
	$(RUN_ON_REMOTE) rm -rf $(PWD)/
	rm -rf $$@ 
	mv $(BUILD_PATH)/$(BENCHMARK)/$$@ $$@

$(1)$(2).regprof2: $(1)
	$(call switch_binary,$(1),$(2))
	cp -f $(mkfile_path)loadtest-funcs.sh ./loadtest-funcs.sh
	$(call copy_to_server,$(1),$(2))
	cd $(BUILD_PATH)/$(BENCHMARK) && \
		$(RUN) $(mkfile_path)loadtest-funcs.sh setup_mysql $(1) 2>&1
	cd $(BUILD_PATH)/$(BENCHMARK) && \
		bash "$(mkfile_path)loadtest-funcs.sh" run_perf -o "$(BUILD_PATH)/$(BENCHMARK)/$$@" -- \
		bash "$(mkfile_path)loadtest-funcs.sh" run_sysbench_loadtest "$(1)$(2)" \
		|| { echo "*** loadtest failed ***" ; rm -f $(PWD)/$$@ ; exit 1; }
	$(COPY_BACK) $(PWD)/$$@
	$(RUN_ON_REMOTE) rm -rf $(PWD)/
	rm -rf $$@ 
	mv $(BUILD_PATH)/$(BENCHMARK)/$$@ $$@
	
$(1)$(2).regprof3: $(1).profbuild
	$(call switch_binary,$(1).profbuild,$(2))
	cp -f $(mkfile_path)loadtest-funcs.sh ./loadtest-funcs.sh
	cd $(BUILD_PATH)/$(BENCHMARK) && \
		$(RUN) $(mkfile_path)loadtest-funcs.sh setup_mysql $(1) 2>&1
	cd $(BUILD_PATH)/$(BENCHMARK) && \
		LLVM_IRPP_PROFILE="$(PWD)/$$@.raw" \
		bash "$(mkfile_path)loadtest-funcs.sh" run_sysbench_loadtest "$(1)$(2)" \
			|| { echo "*** loadtest failed ***" ; rm -f $(PWD)/$$@ ; exit 1; }
	cat $(PWD)/$$@.raw | $(COUNTSUM) > $(PWD)/$$@
	
endef

define gen_bench

$(1)$(2).bench: $(1)
	$(call switch_binary,$(1),$(2))
	cp -f $(mkfile_path)loadtest-funcs.sh ./loadtest-funcs.sh
	$(call copy_to_server,$(1),$(2))
	$(RUN) ./loadtest-funcs.sh setup_mysql $(1) 2>&1
	cd $(BUILD_PATH)/$(BENCHMARK) && \
	$(RUN) ./loadtest-funcs.sh run_sysbench_benchmark $(1)$(2) 5 
	$(RUN_FOR_REMOTE) mkdir -p $(BENCH_DIR)/
	$(COPY_BACK) $(BENCH_DIR)/$(1)$(2)
	$(RUN_ON_REMOTE) rm -rf $(PWD)/
	rm -rf $$@ 
	mv $(BUILD_PATH)/$(BENCHMARK)/$$@ $$@

endef 

additional_compiler_flags = $(if $(findstring thin,$(1)),-flto=thin)  $(if $(findstring full,$(1)),-flto=full) 
additional_linker_flags = $(if $(findstring thin,$(1)),-flto=thin)  $(if $(findstring full,$(1)),-flto=full) 
additional_original_flags = -DFPROFILE_USE=1 -DFPROFILE_DIR="$(PWD)/instrumented.profdata"

$(eval $(call gen_pgo_targets,thin))
$(eval $(call gen_pgo_targets,full))

debug-makefile:
	$(warning $(call gen_pgo_targets,full))

instrumented: | $(SOURCE)/.complete
	$(call build_mysql,$@,$(call gen_build_flags_ins) -DFPROFILE_GENERATE=1 -DFPROFILE_DIR="$(INSTRUMENTED_PROF)/%4m.profraw",install)
	touch $@

instrumented.profdata: instrumented
	rm -rf $(INSTRUMENTED_PROF)
	$(call switch_binary,instrumented)
	cd $(BUILD_PATH)/$(BENCHMARK) && \
		bash "$(mkfile_path)loadtest-funcs.sh" setup_mysql instrumented 2>&1  && \
		bash "$(mkfile_path)loadtest-funcs.sh" run_sysbench_loadtest instrumented
	cd $(INSTRUMENTED_PROF) ; \
	$(LLVM_BIN)/llvm-profdata merge -output=$(PWD)/instrumented.profdata *.profraw ; \
	rm *.profraw
	rm -rf $(INSTALL_DIR)

$(MYSQL_PACKAGE_NAME):
	wget -q https://dev.mysql.com/get/Downloads/MySQL-8.0/$(MYSQL_PACKAGE_NAME)

$(SOURCE)/.complete: $(MYSQL_PACKAGE_NAME) $(OPENSSL_SOURCE)/install $(NCURSE_SOURCE)/install $(mkfile_path)/packages/mysql.patch
	mkdir -p $(BUILD_PATH)/$(BENCHMARK)/
	cd $(BUILD_PATH)/$(BENCHMARK)/ && tar xzf $(PWD)/$<
	cd "$(SOURCE)" ; patch -p1 < "$(lastword $^)"
	touch $@

$(OPENSSL_PACKAGE_NAME):
	wget -q https://www.openssl.org/source/$(OPENSSL_PACKAGE_NAME) 

$(OPENSSL_SOURCE)/README: $(OPENSSL_PACKAGE_NAME)
	mkdir -p $(BUILD_PATH)/$(BENCHMARK)/
	cd $(BUILD_PATH)/$(BENCHMARK)/ && tar xzf $(PWD)/$<
	touch $@

$(OPENSSL_SOURCE)/install: | $(OPENSSL_SOURCE)/README
	cd $(OPENSSL_SOURCE) && CC=$(NCC) CXX=$(NCXX) ./config no-shared --prefix=$(OPENSSL_SOURCE)/install \
	 && make depend -j$(shell nproc) && make -j$(shell nproc)
	cd $(OPENSSL_SOURCE) && make install_sw
	touch $@

$(NCURSE_PACKAGE_NAME):
	wget -q https://ftp.gnu.org/pub/gnu/ncurses/$(NCURSE_PACKAGE_NAME)

$(NCURSE_SOURCE)/README: $(NCURSE_PACKAGE_NAME)
	mkdir -p $(BUILD_PATH)/$(BENCHMARK)/
	cd $(BUILD_PATH)/$(BENCHMARK)/ && tar xzf $(PWD)/$<
	touch $@

$(NCURSE_SOURCE)/install: | $(NCURSE_SOURCE)/README
	cd $(NCURSE_SOURCE) && CC=$(NCC) CXX=$(NCXX) ./configure --prefix=$(NCURSE_SOURCE)/install
	cd $(NCURSE_SOURCE) && make -j$(shell nproc) && make install
	cp $(mkfile_path)/packages/CursesConfig.cmake $(NCURSE_SOURCE)/install
	touch $@


