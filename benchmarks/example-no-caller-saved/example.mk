
%.count4: build/example4/%.S
	cat $< | grep push | wc -l
	cat $< | grep pop | wc -l

example4:
	mkdir -p build/example4
	cd build/example4 && $(CC) -O3 -S ../../benchmarks/example-no-caller-saved/main.c -o main.S
	@make main.count4
	cd build/example4 && $(CC) -O3 -S ../../benchmarks/example-no-caller-saved/main2.c -o main2.S
	@make main2.count4


FDO-example4:
	mkdir -p build/example4
	cd build/example4 && $(FDO) config ../../benchmarks/example-no-caller-saved -DCMAKE_BUILD_TYPE=Release && \
		$(FDO) build --pgo && \
		$(FDO) test --pgo && \
		$(FDO) opt --pgo


example4-fdo: FDO-example4
	mkdir -p build/example4
	cd build/example4 && $(CC) -O3 -S -fprofile-use=instrumented/PGO.profdata -mllvm -fdo-ipra -mllvm -debug-only=fdo-ipra -mllvm -profile-summary-hot-count=100 ../../benchmarks/example-no-caller-saved/main2.c -o fdo_ipra.S
	@make fdo_ipra.count4
	cd build/example4 && $(CC) -O3 -S -fprofile-use=instrumented/PGO.profdata ../../benchmarks/example-no-caller-saved/main2.c -o no_ipra.S
	@make no_ipra.count4