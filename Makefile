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
	crossplane-uninstall

doctor:
	@$(MAKE) -C $(CORE_DIR) doctor

check-ports:
	@$(MAKE) -C $(CORE_DIR) check-ports

bootstrap:
	@$(MAKE) -C $(CORE_DIR) bootstrap

verify:
	@$(MAKE) -C $(CORE_DIR) verify

destroy:
	@$(MAKE) -C $(CORE_DIR) destroy

kind-config:
	@$(MAKE) -C $(CORE_DIR) kind-config

kind-create:
	@$(MAKE) -C $(CORE_DIR) kind-create

kind-status:
	@$(MAKE) -C $(CORE_DIR) kind-status

kind-delete:
	@$(MAKE) -C $(CORE_DIR) kind-delete

registry-create:
	@$(MAKE) -C $(CORE_DIR) registry-create

registry-delete:
	@$(MAKE) -C $(CORE_DIR) registry-delete

registry-configure-kind:
	@$(MAKE) -C $(CORE_DIR) registry-configure-kind

registry-verify:
	@$(MAKE) -C $(CORE_DIR) registry-verify

crossplane-install:
	@$(MAKE) -C $(CORE_DIR) crossplane-install

crossplane-verify:
	@$(MAKE) -C $(CORE_DIR) crossplane-verify

crossplane-status:
	@$(MAKE) -C $(CORE_DIR) crossplane-status

crossplane-uninstall:
	@$(MAKE) -C $(CORE_DIR) crossplane-uninstall