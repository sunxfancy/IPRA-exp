
# cd build/example && $(CC) -O3 -S -fprofile-instr-use=instrumented/PGO.profdata $(PWD)/benchmarks/example-virtualcall/main.c -o no_ipra_pgo.S
# cd build/example && $(CC) -O3 -S $(ENABLE_IPRA) -fprofile-instr-use=instrumented/PGO.profdata $(PWD)/benchmarks/example-virtualcall/main.c -o ipra_pgo.S

%.count: build/example3/%.S
	cat $< | grep push | wc -l
	cat $< | grep pop | wc -l

example3:
	mkdir -p build/example3 
	rm -f /tmp/count-push-pop.txt
	cd build/example3 && $(CXX) -O3 -S $(PWD)/benchmarks/example-virtualcall/main.cpp -o no_ipra.S  
	make no_ipra.count
	cd build/example3 && $(CXX) -O3 -S $(ENABLE_IPRA) $(PWD)/benchmarks/example-virtualcall/main.cpp -o ipra.S
	make ipra.count
	cd build/example3 && $(CXX) -O3 -S -fstrict-vtable-pointers -fuse-ld=lld -fprofile-use=instrumented/PGO.profdata -mllvm -debug-only=pgo-icall-prom $(PWD)/benchmarks/example-virtualcall/main.cpp -o no_ipra_pgo.S
	make no_ipra_pgo.count
	cd build/example3 && $(CXX) -O3 -S -fstrict-vtable-pointers $(ENABLE_IPRA) -fprofile-use=instrumented/PGO.profdata -mllvm -debug-only=pgo-icall-prom $(PWD)/benchmarks/example-virtualcall/main.cpp -o ipra_pgo.S
	make ipra_pgo.count
	cat /tmp/count-push-pop.txt 

	rm -f /tmp/count-push-pop.txt
	cd build/example3 && $(CXX) -O3 -S $(PWD)/benchmarks/example-virtualcall/main2.cpp -o no_ipra2.S  
	cd build/example3 && $(CXX) -O3 -S $(ENABLE_IPRA) $(PWD)/benchmarks/example-virtualcall/main2.cpp -o ipra2.S
	cat /tmp/count-push-pop.txt 

FDO-example3:
	rm -rf build/example3
	mkdir -p build/example3/instrumented
	cd build/example3/instrumented && cmake ../../../benchmarks/example-virtualcall -G Ninja -DCMAKE_BUILD_TYPE=Release -DCMAKE_C_COMPILER=/usr/local/google/home/xiaofans/workspace/IPRA-exp/install/llvm/bin/clang -DCMAKE_CXX_COMPILER=/usr/local/google/home/xiaofans/workspace/IPRA-exp/install/llvm/bin/clang++ -DCMAKE_C_FLAGS=-fprofile-generate -DCMAKE_CXX_FLAGS="-fprofile-generate -mllvm -enable-value-profiling -fstrict-vtable-pointers -mllvm -debug-only=pgo-icall-prom" -DCMAKE_EXE_LINKER_FLAGS=-fuse-ld=lld -DCMAKE_SHARED_LINKER_FLAGS=-fuse-ld=lld -DCMAKE_MODULE_LINKER_FLAGS=-fuse-ld=lld
	cd build/example3/instrumented && ninja
	cd build/example3/instrumented && LLVM_PROFILE_FILE=PGO0.profraw ./example 500
	cd build/example3/instrumented && /usr/local/google/home/xiaofans/workspace/IPRA-exp/install/llvm/bin/llvm-profdata merge -output=PGO.profdata PGO0.profraw