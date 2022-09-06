mkfile_path := $(dir $(abspath $(lastword $(MAKEFILE_LIST))))

define get_count
	cat $(1) | grep push | wc -l
	cat $(1) | grep pop | wc -l
endef

define run_command
	rm -f /tmp/count-push-pop.txt 
	touch /tmp/count-push-pop.txt
	$@
	cat /tmp/count-push-pop.txt
endef 

# all: fdo_ipra2.S fdo_ipra.S no_ipra.S

all: ipra2.S ipra.S fdo_ipra2.S fdo_ipra.S no_ipra.S

ipra2.S: FDO
	rm -f /tmp/count-push-pop.txt 
	touch /tmp/count-push-pop.txt
	$(NCC) -O3 -S -fprofile-use=instrumented/PGO.profdata \
		-mllvm -count-push-pop \
		-mllvm -fdo-ipra -mllvm -fdoipra-both-hot -mllvm -fdoipra-ch=1 -mllvm -fdoipra-hc=1 \
		-mllvm -enable-value-profiling  \
		-mllvm -debug-only=fdo-ipra \
		-mllvm -profile-summary-cold-count=50 -mllvm -profile-summary-hot-count=200 \
		$(mkfile_path)main.c -o ipra2.S
	cat /tmp/count-push-pop.txt

ipra.S: FDO
	rm -f /tmp/count-push-pop.txt 
	touch /tmp/count-push-pop.txt
	$(NCC) -O3 -S -fprofile-use=instrumented/PGO.profdata \
		-mllvm -count-push-pop \
		-mllvm -fdo-ipra -mllvm -fdoipra-both-hot -mllvm -fdoipra-ch=1 \
		-mllvm -enable-value-profiling -mllvm -enable-ipra \
		-mllvm -debug-only=fdo-ipra \
		-mllvm -profile-summary-cold-count=50 -mllvm -profile-summary-hot-count=100 \
		$(mkfile_path)main.c -o ipra.S
	cat /tmp/count-push-pop.txt


fdo_ipra2.S: FDO
	rm -f /tmp/count-push-pop.txt 
	touch /tmp/count-push-pop.txt
	$(NCC) -O3 -S -fprofile-use=instrumented/PGO.profdata \
		-mllvm -count-push-pop \
		-mllvm -fdo-ipra -mllvm -fdoipra-both-hot -mllvm -fdoipra-ch=1 \
		-mllvm -debug-only=fdo-ipra \
		-mllvm -profile-summary-cold-count=50 -mllvm -profile-summary-hot-count=100 \
		$(mkfile_path)main.c -o fdo_ipra2.S
	cat /tmp/count-push-pop.txt

fdo_ipra.S: FDO
	rm -f /tmp/count-push-pop.txt 
	touch /tmp/count-push-pop.txt
	$(NCC) -O3 -S -fprofile-use=instrumented/PGO.profdata \
		-mllvm -count-push-pop \
		-mllvm -fdo-ipra -mllvm -fdoipra-both-hot -mllvm -fdoipra-ch=0 \
		-mllvm -debug-only=fdo-ipra \
		-mllvm -profile-summary-cold-count=50 -mllvm -profile-summary-hot-count=100 \
		$(mkfile_path)main.c -o fdo_ipra.S
	cat /tmp/count-push-pop.txt

no_ipra.S: FDO
	rm -f /tmp/count-push-pop.txt 
	touch /tmp/count-push-pop.txt
	$(NCC) -O3 -S -fprofile-use=instrumented/PGO.profdata -mllvm -count-push-pop  $(mkfile_path)main.c -o no_ipra.S
	cat /tmp/count-push-pop.txt

FDO:
	$(FDO) config $(mkfile_path) -DCMAKE_BUILD_TYPE=Release && \
		$(FDO) build --pgo && \
		$(FDO) test --pgo 
