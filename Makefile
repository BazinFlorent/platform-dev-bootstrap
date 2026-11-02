# -----------------------------------------------------------------------------
# Platform Bootstrap
# -----------------------------------------------------------------------------

CORE_DIR := $(CURDIR)/core

.PHONY: \
	doctor \
	check-ports \
	bootstrap \
	verify \
	destroy \
	kind-config \
	kind-create \
	kind-status \
	kind-delete \
	registry-create \
	registry-delete \
	registry-configure-kind \
	registry-verify \
	crossplane-install \
	crossplane-verify \
	crossplane-status \
	crossplane-uninstall \
	instance-save \
	list \
	doctor-ai \
	build-ai-node-image \
	kind-ai-config \
	kind-ai-create \
	configure-ai-containerd \
	install-ai-device-plugin \
	verify-ai

doctor:
	@$(MAKE) --no-print-directory -C $(CORE_DIR) doctor

check-ports:
	@$(MAKE) --no-print-directory -C $(CORE_DIR) check-ports

bootstrap:
	@$(MAKE) --no-print-directory -C $(CORE_DIR) bootstrap

verify:
	@$(MAKE) --no-print-directory -C $(CORE_DIR) verify

destroy:
	@$(MAKE) --no-print-directory -C $(CORE_DIR) destroy

kind-config:
	@$(MAKE) --no-print-directory -C $(CORE_DIR) kind-config

kind-create:
	@$(MAKE) --no-print-directory -C $(CORE_DIR) kind-create

kind-status:
	@$(MAKE) --no-print-directory -C $(CORE_DIR) kind-status

kind-delete:
	@$(MAKE) --no-print-directory -C $(CORE_DIR) kind-delete

registry-create:
	@$(MAKE) --no-print-directory -C $(CORE_DIR) registry-create

registry-delete:
	@$(MAKE) --no-print-directory -C $(CORE_DIR) registry-delete

registry-configure-kind:
	@$(MAKE) --no-print-directory -C $(CORE_DIR) registry-configure-kind

registry-verify:
	@$(MAKE) --no-print-directory -C $(CORE_DIR) registry-verify

crossplane-install:
	@$(MAKE) --no-print-directory -C $(CORE_DIR) crossplane-install

crossplane-verify:
	@$(MAKE) --no-print-directory -C $(CORE_DIR) crossplane-verify

crossplane-status:
	@$(MAKE) --no-print-directory -C $(CORE_DIR) crossplane-status

crossplane-uninstall:
	@$(MAKE) --no-print-directory -C $(CORE_DIR) crossplane-uninstall

instance-save:
	@$(MAKE) --no-print-directory -C $(CORE_DIR) instance-save

list:
	@$(MAKE) --no-print-directory -C $(CORE_DIR) list LIST_ARGS="$(LIST_ARGS)"

doctor-ai:
	@$(MAKE) --no-print-directory -C ai doctor

build-ai-node-image:
	@$(MAKE) --no-print-directory -C ai build-node-image

kind-ai-config:
	@$(MAKE) --no-print-directory -C ai kind-config

kind-ai-create:
	@$(MAKE) --no-print-directory -C ai kind-create

configure-ai-containerd:
	@$(MAKE) --no-print-directory -C ai configure-containerd

install-ai-device-plugin:
	@$(MAKE) --no-print-directory -C ai install-device-plugin

verify-ai:
	@$(MAKE) --no-print-directory -C ai verify