mkfile_path := $(dir $(abspath $(lastword $(MAKEFILE_LIST))))

full:
	rm -f /tmp/count-push-pop.txt
	$(CC) -O3 $(ENABLE_COUNT_PUSH_POP_LTO) -flto=full -fuse-ld=lld -c $(mkfile_path)test.c -o test.o 
	$(CC) -O3 $(ENABLE_COUNT_PUSH_POP_LTO) -flto=full -fuse-ld=lld -c $(mkfile_path)main.c -o main.o 
	$(CC) -O3 $(ENABLE_COUNT_PUSH_POP_LTO) -flto=full -fuse-ld=lld test.o main.o -o no_ipra
	$(CC) -O3 $(ENABLE_COUNT_PUSH_POP_LTO) -flto=full -fuse-ld=lld $(ENABLE_IPRA_LTO) test.o main.o -o ipra
	cat /tmp/count-push-pop.txt 

thin:
	rm -f /tmp/count-push-pop.txt
	$(CC) -O3 $(ENABLE_COUNT_PUSH_POP_LTO) -flto=thin -fuse-ld=lld -c $(mkfile_path)test.c -o test.thin.o 
	$(CC) -O3 $(ENABLE_COUNT_PUSH_POP_LTO) -flto=thin -fuse-ld=lld -c $(mkfile_path)main.c -o main.thin.o 
	$(CC) -O3 $(ENABLE_COUNT_PUSH_POP_LTO) -flto=thin -fuse-ld=lld test.thin.o main.thin.o -o no_ipra
	$(CC) -O3 $(ENABLE_COUNT_PUSH_POP_LTO) -flto=thin -fuse-ld=lld $(ENABLE_IPRA_LTO) test.thin.o main.thin.o -o ipra
	cat /tmp/count-push-pop.txt 


FDO-example2:
	$(FDO) config $(mkfile_path) -DCMAKE_BUILD_TYPE=Release && \
		$(FDO) build --pgo --lto=full && \
		$(FDO) test --pgo && \
		$(FDO) opt --pgo