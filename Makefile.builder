ifneq (,$(filter win%-cross,$(DIST)))
    WINDOWS_PLUGIN_DIR := $(dir $(abspath $(lastword $(MAKEFILE_LIST))))
    DISTRIBUTION := windows
    BUILDER_MAKEFILE = $(WINDOWS_PLUGIN_DIR)Makefile.windows
endif
