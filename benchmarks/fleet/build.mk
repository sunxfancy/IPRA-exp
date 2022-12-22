mkfile_path := $(dir $(abspath $(lastword $(MAKEFILE_LIST))))
BENCHMARK=fleet
include $(mkfile_path)../common.mk
