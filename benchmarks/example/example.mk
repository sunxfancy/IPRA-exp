

FDO-example:
	mkdir -p build/example
	cd build/example && $(FDO) config ../../benchmarks/example -DCMAKE_BUILD_TYPE=Release && \
		$(FDO) build --pgo && \
		$(FDO) test --pgo && \
		$(FDO) opt --pgo


example:
	mkdir -p build/example
	cd build/example && $(CC) -O3 -S $(PWD)/benchmarks/example/main.c -o no_ipra.S
	cd build/example && $(CC) -O3 -S $(ENABLE_IPRA) $(PWD)/benchmarks/example/main.c -o ipra.S
	cd build/example && $(CC) -O3 -S -fprofile-instr-use=instrumented/PGO.profdata $(PWD)/benchmarks/example/main.c -o no_ipra_pgo.S
	cd build/example && $(CC) -O3 -S $(ENABLE_IPRA) -fprofile-instr-use=instrumented/PGO.profdata $(PWD)/benchmarks/example/main.c -o ipra_pgo.S

	cd build/example && $(CC) -O3 -S $(PWD)/benchmarks/example/main2.c -o no_ipra2.S
	cd build/example && $(CC) -O3 -S $(ENABLE_IPRA) $(PWD)/benchmarks/example/main2.c -o ipra2.S
	cd build/example && $(CC) -O3 -S -fprofile-instr-use=instrumented/PGO.profdata $(PWD)/benchmarks/example/main2.c -o no_ipra_pgo2.S
	cd build/example && $(CC) -O3 -S $(ENABLE_IPRA) -fprofile-instr-use=instrumented/PGO.profdata $(PWD)/benchmarks/example/main2.c -o ipra_pgo2.S

count-static:
	mkdir -p build/count
	cd build/count && $(CC) -O3 -S $(PWD)/benchmarks/example/main.c -o no_ipra.S
	cd build/count && $(COUNTER) < no_ipra.S 

count:
	cd build/example && $(CC) -O3 -S -fprofile-instr-use=instrumented/PGO.profdata $(PWD)/benchmarks/example/main.c -o no_ipra_pgo.S
	cd build/example && $(CC) -O3 -S $(ENABLE_IPRA) -fprofile-instr-use=instrumented/PGO.profdata $(PWD)/benchmarks/example/main.c -o ipra_pgo.S