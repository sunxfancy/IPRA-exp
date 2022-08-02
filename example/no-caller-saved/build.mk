mkfile_path := $(dir $(abspath $(lastword $(MAKEFILE_LIST))))

define get_count
	cat $(1) | grep push | wc -l
	cat $(1) | grep pop | wc -l
endef

example4-fdo: FDO-example4
	$(NCC) -O3 -S -fprofile-use=instrumented/PGO.profdata -mllvm -fdo-ipra -mllvm -debug-only=fdo-ipra -mllvm -profile-summary-hot-count=100 $(mkfile_path)main2.c -o fdo_ipra.S
	$(call get_count,fdo_ipra.S)
	$(NCC) -O3 -S -fprofile-use=instrumented/PGO.profdata $(mkfile_path)main2.c -o no_ipra.S
	$(call get_count,no_ipra.S)


example4:
	$(NCC) -O3 -S $(mkfile_path)main.c -o main.S
	$(call get_count,main.S)
	$(NCC) -O3 -S $(mkfile_path)main2.c -o main2.S
	$(call get_count,main2.S)

FDO-example4:
	$(FDO) config $(mkfile_path) -DCMAKE_BUILD_TYPE=Release && \
		$(FDO) build --pgo && \
		$(FDO) test --pgo && \
		$(FDO) opt --pgo

main3:
	$(NCC) -O3 -S $(mkfile_path)main3.c -o main3.S