
%.count4: build/example4/%.S
	cat $< | grep push | wc -l
	cat $< | grep pop | wc -l

example4:
	mkdir -p build/example4
	cd build/example4 && $(CC) -O3 -S ../../benchmarks/example-no-caller-saved/main.c -o main.S
	@make main.count4
	cd build/example4 && $(CC) -O3 -S ../../benchmarks/example-no-caller-saved/main2.c -o main2.S
	@make main2.count4