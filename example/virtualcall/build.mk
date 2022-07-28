mkfile_path := $(dir $(abspath $(lastword $(MAKEFILE_LIST))))

define get_count
	cat $(1) | grep push | wc -l
	cat $(1) | grep pop | wc -l
endef

example3: FDO-example3
	$(NCXX) -O3 -S $(mkfile_path)main.cpp -o no_ipra.S  
	$(call get_count,no_ipra.S)
	$(NCXX) -O3 -S $(ENABLE_IPRA) $(mkfile_path)main.cpp -o ipra.S
	$(call get_count,ipra.S)
	$(NCXX) -O3 -S -fstrict-vtable-pointers -fuse-ld=lld -fprofile-use=instrumented/PGO.profdata -mllvm -debug-only=pgo-icall-prom $(mkfile_path)main.cpp -o no_ipra_pgo.S
	$(call get_count,no_ipra_pgo.S)
	$(NCXX) -O3 -S -fstrict-vtable-pointers $(ENABLE_IPRA) -fuse-ld=lld -fprofile-use=instrumented/PGO.profdata -mllvm -debug-only=pgo-icall-prom $(mkfile_path)main.cpp -o ipra_pgo.S
	$(call get_count,ipra_pgo.S)

	$(NCXX) -O3 -S $(mkfile_path)main2.cpp -o no_ipra2.S  
	$(NCXX) -O3 -S $(ENABLE_IPRA) $(mkfile_path)main2.cpp -o ipra2.S
	$(call get_count,no_ipra2.S)
	$(call get_count,ipra2.S)

FDO-example3:
	$(FDO) config $(mkfile_path) -DCMAKE_C_FLAGS="-mllvm -enable-value-profiling -fstrict-vtable-pointers" -DCMAKE_CXX_FLAGS="-mllvm -enable-value-profiling -fstrict-vtable-pointers -mllvm -debug-only=pgo-icall-prom" -DCMAKE_BUILD_TYPE=Release && \
		$(FDO) build --pgo && \
		$(FDO) test --pgo && \
		$(FDO) opt --pgo
