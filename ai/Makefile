BASH ?= bash

SCRIPTS_DIR := scripts

.PHONY: doctor \
	    build-node-image \
		kind-config \
		kind-create \
		configure-containerd

doctor:
	@$(BASH) $(SCRIPTS_DIR)/doctor.sh

build-node-image:
	@$(BASH) $(SCRIPTS_DIR)/build-node-image.sh

kind-config:
	@$(BASH) $(SCRIPTS_DIR)/kind-config.sh

kind-create: kind-config
	@$(BASH) $(SCRIPTS_DIR)/kind-create.sh

configure-containerd:
	@$(BASH) $(SCRIPTS_DIR)/configure-containerd.sh