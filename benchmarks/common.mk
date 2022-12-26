ifeq (0,1) # The following is the editable source code


build/pgo-%(LTO): profdata $(TMP)/source_dir  ## Build PGO Build with FullLTO
	mkdir -p $C/bin && touch $C/bin/clang

build/pgo-%(LTO)-%(FDO): hotlist/pgo-%(LTO) $(TMP)/source_dir ## Build PGO-LTO FDOIPRA versions
	mkdir -p $C/bin && touch $C/bin/clang 

build/pgo-%(LTO)-%(FDO).%(VAR): build/pgo-%(LTO)-%(FDO)  ## Build FDOIPRA variant versions
	touch $C/bin/clang$V

build/instrumented: | $(TMP)/source_dir  ## Build instrumented binary
	mkdir -p $C/bin && touch $C/bin/clang

hotlist/%: perf/%  			## Generate hotlist
	mkdir -p hotlist
	cat <FI:$(BUILD_PATH)/$< > | awk '{print "hotlist gen from:\n $$1"}' > <FO:$@>

profdata: build/instrumented  ## Generate profdata
	echo "prof data gen" > <FO:$@>

perf/%: build/%              ## Run perf record
	mkdir -p perf
	cat <FI:$C/bin/clang$V> > <FO:$@>

bench/%: build/%             ## Run perf stat
	mkdir -p bench
	cat <FI:$C/bin/clang$V> > <FO:$@>


endif # End of the editable source code

#-------------------- Editable Library Code --------------------#

COLORFUL := 1

ifeq ($(COLORFUL),1)
RED := \033[0;31m
GREEN := \033[0;32m
YELLOW := \033[0;33m
BLUE := \033[0;34m
PURPLE := \033[0;35m
CYAN := \033[0;36m
WHITE := \033[0;37m
NC := \033[0m
DIM := \033[2m
endif


.ONESHELL: 
.NOTINTERMEDIATE: 
# .SILENT: 

DEFAULT_PREACTION = @echo -e "$(CYAN)[umake] $@$(NC)"; $(call check_unfinished,$@) \
	if [ "$(DEBUG)" = "1" ]; then echo -e "$(DIM)PWD=$(PWD)  TMP=$(TMP)$(NC)"; fi
DEFAULT_ACTION = @echo "$A target $T: C = $C V = $V" && $(call mv_back,$@) && cd $(PWD) && mkdir -p $A && touch $@ 


%: A = $(patsubst %/,%,$(dir $@))
%: T = $(notdir $@)
%: C = $(basename $(T))
%: V = $(suffix $(T))

PWD := $(shell pwd)
TMP := $(TMP_PATH)/$(BENCHMARK)

BUILD_DIR:=$(TMP)/build.dir
INSTALL_DIR:=$(TMP)/install.dir
BENCH_DIR:=$(TMP)/bench.dir

INSTRUMENTED_PROF=$(BUILD_DIR)/instrumented/profiles

LTO := full thin
FDO := fdoipra fdoipra2 fdoipra3 bfdoipra bfdoipra2 bfdoipra3

HOT_LIST_VAR := 1 3 5 10
RATIO_VAR    := 10 20
VAR := $(foreach k,$(RATIO_VAR),$(foreach j,$(HOT_LIST_VAR),$(j)-$(k)))
COMBINDEX:=$(shell seq 0 $(words $(VAR)))

PGO_FULL_HOT_LIST=$(foreach j,$(HOT_LIST_VAR),pgo-full.$(j).hot_list)
PGO_THIN_HOT_LIST=$(foreach j,$(HOT_LIST_VAR),pgo-thin.$(j).hot_list)
HOT_LIST=-mllvm -fdoipra-hot-list=$(PWD)/pgo-$(1).$(2).hot_list
HOT_LIST_LD=-Wl,-mllvm -Wl,-fdoipra-hot-list=$(PWD)/pgo-$(1).$(2).hot_list
GEN_HL=$(call HOT_LIST,$(1),$(2)) $(call HOT_LIST_LD,$(1),$(2))
COMMA := ,

GEN_VAR=$(foreach j,$(HOT_LIST_VAR),-Wl,-mllvm -Wl,-fdoipra-ccr=$(3).0 $(call GEN_HL,$(2),$(j)) -Wl,-mllvm -Wl,-fdoipra-psi=$(PWD)/$(1).$(j)-$(3).psi;)
GEN_VARS=$(foreach j,$(RATIO_VAR),$(call GEN_VAR,$(1),$(2),$(j)))

GEN_ARGS=-Wl$(COMMA)-mllvm -Wl$(COMMA)-count-push-pop=$(PWD)/$(1).count-push-pop -Wl$(COMMA)-mllvm -Wl$(COMMA)-fdoipra-psi=$(PWD)/$(1).psi

common_compiler_flags := $(COMPILER_FLAGS) 
common_linker_flags := $(LINKER_FLAGS)
gen_compiler_flags = -DCMAKE_C_FLAGS=$(1) -DCMAKE_CXX_FLAGS=$(1)
gen_linker_flags   = -DCMAKE_EXE_LINKER_FLAGS=$(1) -DCMAKE_SHARED_LINKER_FLAGS=$(1) -DCMAKE_MODULE_LINKER_FLAGS=$(1)
additional_compiler_flags = 
additional_linker_flags =
additional_original_flags = 

define gen_build_flags
	$(call gen_compiler_flags,"$(common_compiler_flags) $(COMPILER_FLAGS_$(call UPCASE,$(1))) $(call additional_compiler_flags,$(2)) $(3)") \
	$(call gen_linker_flags,"$(common_linker_flags) $(LINKER_FLAGS_$(call UPCASE,$(1))) $(call additional_linker_flags,$(2)) $(4)") \
	$(call additional_original_flags,$(2))
endef

gen_build_flags_ins = $(call gen_compiler_flags,"$(common_compiler_flags) $(COMPILER_FLAGS_$(call UPCASE,$(1))) $(2)") \
								  $(call gen_linker_flags,"$(common_linker_flags) $(LINKER_FLAGS_$(call UPCASE,$(1))) $(3)") 

UPFIRST=$(shell L1=$(1); echo $${L1^})
UPCASE=$(shell L1=$(1); echo $${L1^^})

COMBINATION:=$(foreach k,$(RATIO_VAR),$(foreach j,$(HOT_LIST_VAR),$(j)-$(k)))
GEN_FDOIPRA_VARIANT_TARGETS = $(foreach f,$(FLAVORS),$(f).$(1) \
				 $(if $(findstring fdoipra,$(f)),$(foreach v,$(COMBINATION),$(f).$(v).$(1))))

BUILD_TARGETS:= $(FLAVORS)
PERFDATA_TARGETS:= $(call GEN_FDOIPRA_VARIANT_TARGETS,perfdata)
BENCH_TARGETS:= $(call GEN_FDOIPRA_VARIANT_TARGETS,bench)
REGPROF_TARGETS:= $(call GEN_FDOIPRA_VARIANT_TARGETS,regprof)
REGCOMPARE_TARGETS:= $(call GEN_FDOIPRA_VARIANT_TARGETS,regcompare)
NCSR_TARGETS:= $(call GEN_FDOIPRA_VARIANT_TARGETS,ncsr)
HOTLIST_TARGETS:= $(call GEN_FDOIPRA_VARIANT_TARGETS,hot_list)

all:  $(BUILD_TARGETS) $(PERFDATA_TARGETS)  $(BENCH_TARGETS)  $(REGPROF_TARGETS)
build:  $(BUILD_TARGETS)
perfdata:  $(PERFDATA_TARGETS)
bench:   $(BENCH_TARGETS)
regprof:   $(REGPROF_TARGETS)
regcompare:   $(REGCOMPARE_TARGETS)
ncsr:   $(NCSR_TARGETS)
hotlist:   $(HOTLIST_TARGETS)

define check_file_exist
	@if [ ! -f $1 ]; then echo "Error: $1 does not exist"; exit 1; fi

endef 

define check_dir_exist
	@if [ ! -d $1 ]; then echo "Error: $1 does not exist"; exit 1; fi

endef

define make_sure_parent_dir_exist
	@mkdir -p $(abspath $1/..)

endef 

define check_unfinished
	if [ -f $(TMP)/$1 ]; then rm $(TMP)/$1; echo "$(TMP)/$1 unfinished"; fi
	if [ -d $(TMP)/$1 ]; then rm -rf $(TMP)/$1; echo "$(TMP)/$1 unfinished"; fi

endef

define mv_back
	rm -rf $(PWD)/$1 && mv $(TMP)/$1 $(PWD)/
endef

ifeq (,)

#-------------------- DO NOT EDIT BELOW THIS LINE --------------------#

ifeq ($(DEBUG),1)
define GENERATE_1
build/pgo-$(LTO_IT): profdata $(TMP_PATH)/source/.complete
	$$(DEFAULT_PREACTION)
	cd $$(PWD)
	$$(DEFAULT_ACTION)

endef
$(foreach LTO_IT, $(LTO),$(eval $(call GENERATE_1)))

define GENERATE_2
build/pgo-$(LTO_IT)-$(FDO_IT): hotlist/pgo-$(LTO_IT) $(TMP_PATH)/source/.complete
	$$(DEFAULT_PREACTION)
	cd $$(PWD)
	$$(DEFAULT_ACTION)

endef
$(foreach LTO_IT, $(LTO),$(foreach FDO_IT, $(FDO),$(eval $(call GENERATE_2))))

define GENERATE_3
build/pgo-$(LTO_IT)-$(FDO_IT).$(VAR_IT): build/pgo-$(LTO_IT)-$(FDO_IT)
	$$(DEFAULT_PREACTION)
	cd $$(PWD)
	$$(DEFAULT_ACTION)

endef
$(foreach LTO_IT, $(LTO),$(foreach FDO_IT, $(FDO),$(foreach VAR_IT, $(VAR),$(eval $(call GENERATE_3)))))

build/instrumented: $(TMP_PATH)/source/.complete
	$(DEFAULT_PREACTION)
	cd $(PWD)
	$(DEFAULT_ACTION)


hotlist/%: perf/%
	$(DEFAULT_PREACTION)
	$(call check_file_exist,$(BUILD_PATH)/$< )
	$(call make_sure_parent_dir_exist,$@)
	touch $@
	$(call check_file_exist,$@)
	cd $(PWD)
	$(DEFAULT_ACTION)


profdata: build/instrumented
	$(DEFAULT_PREACTION)
	$(call make_sure_parent_dir_exist,$@)
	touch $@
	$(call check_file_exist,$@)
	cd $(PWD)
	$(DEFAULT_ACTION)


perf/%: build/%
	$(DEFAULT_PREACTION)
	$(call check_file_exist,$C/bin/clang$V)
	$(call make_sure_parent_dir_exist,$@)
	touch $@
	$(call check_file_exist,$@)
	cd $(PWD)
	$(DEFAULT_ACTION)


bench/%: build/%
	$(DEFAULT_PREACTION)
	$(call check_file_exist,$C/bin/clang$V)
	$(call make_sure_parent_dir_exist,$@)
	touch $@
	$(call check_file_exist,$@)
	cd $(PWD)
	$(DEFAULT_ACTION)


else
define GENERATE_4
build/pgo-$(LTO_IT): profdata $(TMP_PATH)/source/.complete
	$$(DEFAULT_PREACTION)
	mkdir -p $$C/bin && touch $$C/bin/clang
	cd $$(PWD)
	$$(DEFAULT_ACTION)

endef
$(foreach LTO_IT, $(LTO),$(eval $(call GENERATE_4)))

define GENERATE_5
build/pgo-$(LTO_IT)-$(FDO_IT): hotlist/pgo-$(LTO_IT) $(TMP_PATH)/source/.complete
	$$(DEFAULT_PREACTION)
	mkdir -p $$C/bin && touch $$C/bin/clang 
	cd $$(PWD)
	$$(DEFAULT_ACTION)

endef
$(foreach LTO_IT, $(LTO),$(foreach FDO_IT, $(FDO),$(eval $(call GENERATE_5))))

define GENERATE_6
build/pgo-$(LTO_IT)-$(FDO_IT).$(VAR_IT): build/pgo-$(LTO_IT)-$(FDO_IT)
	$$(DEFAULT_PREACTION)
	touch $$C/bin/clang$$V
	cd $$(PWD)
	$$(DEFAULT_ACTION)

endef
$(foreach LTO_IT, $(LTO),$(foreach FDO_IT, $(FDO),$(foreach VAR_IT, $(VAR),$(eval $(call GENERATE_6)))))

build/instrumented: $(TMP_PATH)/source/.complete
	$(DEFAULT_PREACTION)
	mkdir -p $C/bin && touch $C/bin/clang
	cd $(PWD)
	$(DEFAULT_ACTION)


hotlist/%: perf/%
	$(DEFAULT_PREACTION)
	$(call check_file_exist,$(BUILD_PATH)/$< )
	$(call make_sure_parent_dir_exist,$@)
	mkdir -p hotlist
	cat $(BUILD_PATH)/$<  | awk '{print "hotlist gen from:\n $$1"}' > $@
	$(call check_file_exist,$@)
	cd $(PWD)
	$(DEFAULT_ACTION)


profdata: build/instrumented
	$(DEFAULT_PREACTION)
	$(call make_sure_parent_dir_exist,$@)
	echo "prof data gen" > $@
	$(call check_file_exist,$@)
	cd $(PWD)
	$(DEFAULT_ACTION)


perf/%: build/%
	$(DEFAULT_PREACTION)
	$(call check_file_exist,$C/bin/clang$V)
	$(call make_sure_parent_dir_exist,$@)
	mkdir -p perf
	cat $C/bin/clang$V > $@
	$(call check_file_exist,$@)
	cd $(PWD)
	$(DEFAULT_ACTION)


bench/%: build/%
	$(DEFAULT_PREACTION)
	$(call check_file_exist,$C/bin/clang$V)
	$(call make_sure_parent_dir_exist,$@)
	mkdir -p bench
	cat $C/bin/clang$V > $@
	$(call check_file_exist,$@)
	cd $(PWD)
	$(DEFAULT_ACTION)


endif

endif
