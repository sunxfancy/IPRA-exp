# FDO-example2:
# 	rm -rf build/example2
# 	mkdir -p build/example2
# 	cd build/example2 && $(FDO) config ../../benchmarks/example-scalable -DCMAKE_BUILD_TYPE=Release 
# 	rm -f /tmp/count-push-pop.txt
# 	cd build/example2 && $(FDO) build --pgo
# 	cat /tmp/count-push-pop.txt
# 	cd build/example2 && $(FDO) test --pgo 
# 	rm -f /tmp/count-push-pop.txt
# 	cd build/example2 && $(FDO) opt --pgo
# 	cat /tmp/count-push-pop.txt

# FDO-example2-thin:
# 	rm -rf build/example2-thin
# 	mkdir -p build/example2-thin
# 	cd build/example2-thin && $(FDO) config ../../benchmarks/example-scalable -DCMAKE_BUILD_TYPE=Release
# 	rm -f /tmp/count-push-pop.txt
# 	cd build/example2-thin && $(FDO) build --pgo --ipra --lto=thin 
# 	cat /tmp/count-push-pop.txt
# 	cd build/example2-thin && $(FDO) test --pgo 
# 	rm -f /tmp/count-push-pop.txt
# 	cd build/example2-thin && $(FDO) opt --pgo
# 	cat /tmp/count-push-pop.txt

# FDO-example2-full:
# 	rm -rf build/example2-full
# 	mkdir -p build/example2-full
# 	cd build/example2-full && $(FDO) config ../../benchmarks/example-scalable -DCMAKE_BUILD_TYPE=Release && \
# 	rm -f /tmp/count-push-pop.txt
# 	cd build/example2-full && $(FDO) build --pgo --ipra --lto=full 
# 	cat /tmp/count-push-pop.txt
# 	cd build/example2-full && $(FDO) test --pgo 
# 	rm -f /tmp/count-push-pop.txt
# 	cd build/example2-full && $(FDO) opt --pgo
# 	cat /tmp/count-push-pop.txt



FDO-example2:
	mkdir -p build/example2
	cd build/example2 && $(FDO) config ../../benchmarks/example-scalable -DCMAKE_BUILD_TYPE=Release && \
		$(FDO) build --pgo --lto=full && \
		$(FDO) test --pgo && \
		$(FDO) opt --pgo


# cd build/example2 && $(CC) -O3 -S -fprofile-instr-use=instrumented/PGO.profdata $(PWD)/benchmarks/example-scalable/main.c -o no_ipra_pgo.S
# cd build/example2 && $(CC) -O3 -S $(ENABLE_IPRA) -fprofile-instr-use=instrumented/PGO.profdata $(PWD)/benchmarks/example-scalable/main.c -o ipra_pgo.S

example2:
	mkdir -p build/example2
	rm -f /tmp/count-push-pop.txt
	cd build/example2 && $(CC) -O3 -flto=full -fuse-ld=lld -c $(PWD)/benchmarks/example-scalable/test.c -o test.o 
	cd build/example2 && $(CC) -O3 -flto=full -fuse-ld=lld -c $(PWD)/benchmarks/example-scalable/main.c -o main.o 
	cd build/example2 && $(CC) -O3 -flto=full -fuse-ld=lld test.o main.o -o no_ipra
	cd build/example2 && $(CC) -O3 -flto=full -fuse-ld=lld $(ENABLE_IPRA_LTO) test.o main.o -o ipra
	cat /tmp/count-push-pop.txt 

example2-thin:
	mkdir -p build/example2
	rm -f /tmp/count-push-pop.txt
	cd build/example2 && $(CC) -O3 -flto=thin -fuse-ld=lld -c $(PWD)/benchmarks/example-scalable/test.c -o test.thin.o 
	cd build/example2 && $(CC) -O3 -flto=thin -fuse-ld=lld -c $(PWD)/benchmarks/example-scalable/main.c -o main.thin.o 
	cd build/example2 && $(CC) -O3 -flto=thin -fuse-ld=lld test.thin.o main.thin.o -o no_ipra
	cd build/example2 && $(CC) -O3 -flto=thin -fuse-ld=lld $(ENABLE_IPRA_LTO) test.thin.o main.thin.o -o ipra
	cat /tmp/count-push-pop.txt 

	