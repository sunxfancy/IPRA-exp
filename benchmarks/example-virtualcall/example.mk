
# cd build/example && $(CC) -O3 -S -fprofile-instr-use=instrumented/PGO.profdata $(PWD)/benchmarks/example-hotpath/main.c -o no_ipra_pgo.S
# cd build/example && $(CC) -O3 -S $(ENABLE_IPRA) -fprofile-instr-use=instrumented/PGO.profdata $(PWD)/benchmarks/example-hotpath/main.c -o ipra_pgo.S

example3:
	mkdir -p build/example3 
	rm -f /tmp/count-push-pop.txt
	cd build/example3 && $(CC) -O3 -S $(PWD)/benchmarks/example-virtualcall/main.cpp -o no_ipra.S  
	cd build/example3 && $(CC) -O3 -S $(ENABLE_IPRA) $(PWD)/benchmarks/example-virtualcall/main.cpp -o ipra.S
	cat /tmp/count-push-pop.txt 

	rm -f /tmp/count-push-pop.txt
	cd build/example3 && $(CC) -O3 -S $(PWD)/benchmarks/example-virtualcall/main2.cpp -o no_ipra2.S  
	cd build/example3 && $(CC) -O3 -S $(ENABLE_IPRA) $(PWD)/benchmarks/example-virtualcall/main2.cpp -o ipra2.S
	cat /tmp/count-push-pop.txt 
