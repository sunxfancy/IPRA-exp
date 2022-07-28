mkfile_path := $(dir $(abspath $(lastword $(MAKEFILE_LIST))))

FDO-example:
	$(FDO) config $(mkfile_path) -DCMAKE_BUILD_TYPE=Release && \
		$(FDO) build --pgo && \
		$(FDO) test --pgo && \
		$(FDO) opt --pgo

example: FDO-example
	mkdir -p build/example 
	rm -f /tmp/count-push-pop.txt
	$(CC) -O3 -S $(ENABLE_COUNT_PUSH_POP) $(mkfile_path)main.c -o no_ipra.S  
	$(CC) -O3 -S $(ENABLE_COUNT_PUSH_POP) $(ENABLE_IPRA) $(mkfile_path)main.c -o ipra.S
	$(CC) -O3 -S $(ENABLE_COUNT_PUSH_POP) -fprofile-use=instrumented/PGO.profdata $(mkfile_path)main.c -o no_ipra_pgo.S
	$(CC) -O3 -S $(ENABLE_COUNT_PUSH_POP) $(ENABLE_IPRA) -fprofile-use=instrumented/PGO.profdata $(mkfile_path)main.c -o ipra_pgo.S
	cat /tmp/count-push-pop.txt 

	rm -f /tmp/count-push-pop.txt
	$(CC) -O3 -S $(ENABLE_COUNT_PUSH_POP) $(mkfile_path)main2.c -o no_ipra2.S
	$(CC) -O3 -S $(ENABLE_COUNT_PUSH_POP) $(ENABLE_IPRA) $(mkfile_path)main2.c -o ipra2.S
	$(CC) -O3 -S $(ENABLE_COUNT_PUSH_POP) -fprofile-use=instrumented/PGO.profdata $(mkfile_path)main2.c -o no_ipra_pgo2.S
	$(CC) -O3 -S $(ENABLE_COUNT_PUSH_POP) $(ENABLE_IPRA) -fprofile-use=instrumented/PGO.profdata $(mkfile_path)main2.c -o ipra_pgo2.S
	cat /tmp/count-push-pop.txt 

ENABLE_FDO_IPRA = -mllvm -fdo-ipra

FDO-example-fdo:
	mkdir -p build/example-fdo
	cd build/example-fdo && $(FDO) config ../../benchmarks/example-hotpath -DCMAKE_BUILD_TYPE=Release && \
		$(FDO) build --pgo && \
		$(FDO) test --pgo && \
		$(FDO) opt --pgo


example-fdo: FDO-example-fdo
	mkdir -p build/example-fdo 	
	rm -f /tmp/count-push-pop.txt
	cd build/example-fdo && $(CC) -O3 -S -fprofile-use=instrumented/PGO.profdata $(ENABLE_COUNT_PUSH_POP) $(mkfile_path)main.c -o no_ipra.S  
	cd build/example-fdo && $(CC) -O3 -S -fprofile-use=instrumented/PGO.profdata $(ENABLE_COUNT_PUSH_POP) $(ENABLE_IPRA) $(mkfile_path)main.c -o ipra.S
	cd build/example-fdo && $(CC) -O3 -S -fprofile-use=instrumented/PGO.profdata $(ENABLE_COUNT_PUSH_POP) -mllvm -debug-only=fdo-ipra $(ENABLE_FDO_IPRA) $(mkfile_path)main.c -o fdo_ipra.S
	cat /tmp/count-push-pop.txt 


count-static:
	mkdir -p build/count
	cd build/count && $(CC) -O3 -S $(mkfile_path)main.c -o no_ipra.S
	cd build/count && $(COUNTER) < no_ipra.S 

count:
	$(CC) -O3 -S -fprofile-instr-use=instrumented/PGO.profdata $(mkfile_path)main.c -o no_ipra_pgo.S
	$(CC) -O3 -S $(ENABLE_IPRA) -fprofile-instr-use=instrumented/PGO.profdata $(mkfile_path)main.c -o ipra_pgo.S

