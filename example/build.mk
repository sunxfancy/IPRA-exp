
export

SUBDIRS := $(patsubst %/build.mk,%,$(wildcard example/*/build.mk))

.PHONY: $(SUBDIRS)

$(SUBDIRS):
	mkdir -p build/$@
	$(MAKE) -C build/$@ -f $(PWD)/$@/build.mk

example/%: 
	mkdir -p build/$(dir $@)
	echo $(dir $@)
	$(MAKE) -C build/$(dir $@) -f $(PWD)/$(dir $@)build.mk $(notdir $@)