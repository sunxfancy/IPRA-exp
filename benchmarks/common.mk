PWD := $(shell pwd)

BUILD_DIR:=$(BUILD_PATH)/$(BENCHMARK)/build.dir
INSTALL_DIR:=$(BUILD_PATH)/$(BENCHMARK)/install.dir
BENCH_DIR:=$(BUILD_PATH)/$(BENCHMARK)/bench.dir

INSTRUMENTED_PROF=$(BUILD_DIR)/instrumented/profiles
HOT_LIST_VAR:=1 3 5 10
RATIO_VAR:=10 20
PGO_FULL_HOT_LIST=$(foreach j,$(HOT_LIST_VAR),pgo-full.$(j).hot_list)
PGO_THIN_HOT_LIST=$(foreach j,$(HOT_LIST_VAR),pgo-thin.$(j).hot_list)
HOT_LIST=-mllvm -fdoipra-hot-list=$(PWD)/pgo-$(1).$(2).hot_list
HOT_LIST_LD=-Wl,-mllvm -Wl,-fdoipra-hot-list=$(PWD)/pgo-$(1).$(2).hot_list
GEN_HL=$(call HOT_LIST,$(1),$(2)) $(call HOT_LIST_LD,$(1),$(2))
COMMA := ,

# call GEN_VAR,pgo-thin-fdoipra3,thin,10
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

# .SECONDARY: $(BUILD_TARGETS) $(PERFDATA_TARGETS)  $(BENCH_TARGETS)  $(REGPROF_TARGETS)  $(NCSR_TARGETS) $(HOTLIST_TARGETS)
# .PRECIOUS: $(BUILD_TARGETS) $(PERFDATA_TARGETS)  $(BENCH_TARGETS)  $(REGPROF_TARGETS)
all:  $(BUILD_TARGETS) $(PERFDATA_TARGETS)  $(BENCH_TARGETS)  $(REGPROF_TARGETS)
build:  $(BUILD_TARGETS)
perfdata:  $(PERFDATA_TARGETS)
bench:   $(BENCH_TARGETS)
regprof:   $(REGPROF_TARGETS)
regcompare:   $(REGCOMPARE_TARGETS)
ncsr:   $(NCSR_TARGETS)
hotlist:   $(HOTLIST_TARGETS)

#(baseline, name, variant) e.g (pgo-full, pgo-full-fdoipra,.1-10)
define gen_reg_compare
$(2)$(3).regcompare: $(1).perfdata $(2)$(3).perfdata $(2)$(3).ncsr
	echo "baseline " $(1)
	$(REG_PROFILER) \
		--binary="$(PWD)/$(1)/$(MAIN_BIN)" \
		--profile="$(PWD)/$(1).perfdata" \
		--namelist="$(PWD)/$(2)$(3).ncsr" 
	$(REG_PROFILER) \
		--binary="$(PWD)/$(1)/$(MAIN_BIN)" \
		--profile="$(PWD)/$(1).perfdata" \
		--namelist="$(PWD)/$(2)$(3).ncsr" \
		--not_in_list
	echo "new method " $(2)$(3)
	$(REG_PROFILER) \
		--binary="$(PWD)/$(2)/$(MAIN_BIN)$(3)" \
		--profile="$(PWD)/$(2)$(3).perfdata" \
		--namelist="$(PWD)/$(2)$(3).ncsr" 
	$(REG_PROFILER) \
		--binary="$(PWD)/$(2)/$(MAIN_BIN)$(3)" \
		--profile="$(PWD)/$(2)$(3).perfdata" \
		--namelist="$(PWD)/$(2)$(3).ncsr" \
		--not_in_list

$(2)$(3).ncsr: $(2)
	sed -n 's/\* \([^ ]*\).*/\1/gp' $(PWD)/$(2)$(3).psi > $(PWD)/$(2)$(3).ncsr

endef

#(name, variant) e.g (pgo-full-fdoipra,1)
define gen_hot_list

$(1).$(2).hot_list $(1).$(2).detail: $(1).perfdata
	$(HOT_LIST_CREATOR) \
		--binary="$(PWD)/$(1)/$(MAIN_BIN)" \
		--profile="$(PWD)/$(1).perfdata" \
		--output="$(PWD)/$(1).$(2).hot_list" \
		--detail="$(PWD)/$(1).$(2).detail" \
		--hot_threshold=$(2)

endef


define gen_regprof

$(call gen_header,$(1),$(2),regprof,.perfdata)
	$(REG_PROFILER) \
		--binary="$(PWD)/$(1)/$(MAIN_BIN)$(2)" \
		--profile="$(PWD)/$(1)$(2).perfdata" | tee $$@

endef

define gen_pgo_variant

$(call gen_reg_compare,pgo-$(2),pgo-$(2)-$(1),$(3))
$(call gen_perfdata,pgo-$(2)-$(1),$(3))
$(call gen_bench,pgo-$(2)-$(1),$(3))
$(call gen_regprof,pgo-$(2)-$(1),$(3))

endef

define gen_header
$(1)$(2).$(3): $(1)$(2)$(4)
endef


 #(fdoname, lto)
define gen_pgo_target

pgo-$(2)-$(1): instrumented.profdata $(PGO_$(call UPCASE,$(2))_HOT_LIST)  | $(SOURCE)/.complete
	$(call $(BUILD_ACTION),$$@,\
		$(call gen_build_flags,$(1),pgo-$(2)-$(1))\
		,$$(BUILD_TARGET)\
		,$(call GEN_ARGS,pgo-$(2)-$(1))\
		,$(call GEN_VARS,pgo-$(2)-$(1),$(2)))
	touch $$@

$(foreach j,$(HOT_LIST_VAR),$(call gen_hot_list,pgo-$(2)-$(1),$(j),$(2)))
$(foreach j,$(COMBINATION),$(call gen_pgo_variant,$(1),$(2),.$(j)))
$(call gen_pgo_variant,$(1),$(2))

endef

 #(lto)
define gen_pgo_targets

pgo-$(1): instrumented.profdata | $(SOURCE)/.complete
	$(call $(BUILD_ACTION),$$@,\
		$(call gen_build_flags,,pgo-$(1))\
		,$$(BUILD_TARGET)\
		,$(call GEN_ARGS,pgo-$(1)))
	touch $$@

pgo-$(1)-ipra: instrumented.profdata | $(SOURCE)/.complete
	$(call $(BUILD_ACTION),$$@,\
		$(call gen_build_flags,ipra,pgo-$(1)-ipra)\
		,$$(BUILD_TARGET)\
		,$(call GEN_ARGS,pgo-$(1)-ipra))
	touch $$@
	
$(foreach j,$(HOT_LIST_VAR),$(call gen_hot_list,pgo-$(1),$(j)))
$(foreach f,$(FDOIPRA_FLAVORS),$(call gen_pgo_target,$(f),$(1)))
$(call gen_perfdata,pgo-$(1))
$(call gen_bench,pgo-$(1))
$(call gen_regprof,pgo-$(1))
$(call gen_perfdata,pgo-$(1)-ipra)
$(call gen_bench,pgo-$(1)-ipra)
$(call gen_regprof,pgo-$(1)-ipra)

endef

define mv_binary
	 cp  $(BUILD_DIR)/$(1)/$(MAIN_BIN)    $(PWD)/$(1)/$(MAIN_BIN)
	-cp  $(BUILD_DIR)/$(1)/$(MAIN_BIN).0  $(PWD)/$(1)/$(MAIN_BIN).1-10
	-cp  $(BUILD_DIR)/$(1)/$(MAIN_BIN).1  $(PWD)/$(1)/$(MAIN_BIN).3-10
	-cp  $(BUILD_DIR)/$(1)/$(MAIN_BIN).2  $(PWD)/$(1)/$(MAIN_BIN).5-10
	-cp  $(BUILD_DIR)/$(1)/$(MAIN_BIN).3  $(PWD)/$(1)/$(MAIN_BIN).10-10
	-cp  $(BUILD_DIR)/$(1)/$(MAIN_BIN).4  $(PWD)/$(1)/$(MAIN_BIN).1-20
	-cp  $(BUILD_DIR)/$(1)/$(MAIN_BIN).5  $(PWD)/$(1)/$(MAIN_BIN).3-20
	-cp  $(BUILD_DIR)/$(1)/$(MAIN_BIN).6  $(PWD)/$(1)/$(MAIN_BIN).5-20
	-cp  $(BUILD_DIR)/$(1)/$(MAIN_BIN).7  $(PWD)/$(1)/$(MAIN_BIN).10-20
endef

clean:
	rm -rf $(OUTPUT_PATH)/benchmarks/$(BENCHMARK).output  $(OUTPUT_PATH)/benchmarks/$(BENCHMARK).raw  $(OUTPUT_PATH)/benchmarks/$(BENCHMARK) $(BUILD_PATH)/$(BENCHMARK) 

clean-tmp:
	rm -rf $(BUILD_PATH)/$(BENCHMARK) 