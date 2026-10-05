# -----------------------------------------------------------------------------
# Bootstrap local générique
# -----------------------------------------------------------------------------

BASH ?= bash

# -----------------------------------------------------------------------------
# Instance
# -----------------------------------------------------------------------------

PLATFORM_BOOTSTRAP_NAME ?= platform

# -----------------------------------------------------------------------------
# Kind
# -----------------------------------------------------------------------------

KIND_CLUSTER ?= $(PLATFORM_BOOTSTRAP_NAME)
KIND_CONTEXT := kind-$(KIND_CLUSTER)

# -----------------------------------------------------------------------------
# Runtime state
# -----------------------------------------------------------------------------

STATE_HOME ?= $(if $(XDG_STATE_HOME),$(XDG_STATE_HOME),$(HOME)/.local/state)

PLATFORM_BOOTSTRAP_STATE_ROOT ?= $(STATE_HOME)/platform-bootstrap
PLATFORM_BOOTSTRAP_STATE_DIR ?= $(PLATFORM_BOOTSTRAP_STATE_ROOT)/$(PLATFORM_BOOTSTRAP_NAME)

KIND_STATE_DIR := $(PLATFORM_BOOTSTRAP_STATE_DIR)/kind
KIND_STORAGE := $(KIND_STATE_DIR)/storage

export PLATFORM_BOOTSTRAP_NAME
export PLATFORM_BOOTSTRAP_STATE_ROOT
export PLATFORM_BOOTSTRAP_STATE_DIR

# -----------------------------------------------------------------------------
# Sources
# -----------------------------------------------------------------------------

SCRIPTS_DIR := scripts

KIND_DIR := kind
KIND_TEMPLATE := $(KIND_DIR)/kind.yaml.tpl
KIND_CONFIG := $(KIND_STATE_DIR)/kind.yaml

REGISTRY_DIR := registry
REGISTRY_SCRIPTS := $(REGISTRY_DIR)/scripts

CROSSPLANE_DIR := crossplane
CROSSPLANE_SCRIPTS := $(CROSSPLANE_DIR)/scripts

# -----------------------------------------------------------------------------
# Targets
# -----------------------------------------------------------------------------

.PHONY: \
	doctor \
	check-ports \
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
	bootstrap \
	verify \
	destroy

# -----------------------------------------------------------------------------
# Prérequis
# -----------------------------------------------------------------------------

doctor:
	@$(BASH) $(SCRIPTS_DIR)/doctor.sh

check-ports:
	@$(BASH) $(SCRIPTS_DIR)/check-ports.sh

# -----------------------------------------------------------------------------
# Kind
# -----------------------------------------------------------------------------

kind-config:
	@$(BASH) $(SCRIPTS_DIR)/kind-config.sh

kind-create: kind-config check-ports
	@echo "==> Création du cluster Kind $(KIND_CLUSTER)"
	@kind create cluster \
		--name $(KIND_CLUSTER) \
		--config $(KIND_CONFIG)

kind-status:
	@kubectl --context $(KIND_CONTEXT) get nodes -o wide

kind-delete:
	@kind delete cluster --name $(KIND_CLUSTER)

# -----------------------------------------------------------------------------
# Registry OCI local
# -----------------------------------------------------------------------------

registry-create:
	@$(BASH) $(REGISTRY_SCRIPTS)/create.sh

registry-delete:
	@$(BASH) $(REGISTRY_SCRIPTS)/delete.sh

registry-configure-kind:
	@$(BASH) $(REGISTRY_SCRIPTS)/configure-kind.sh

registry-verify:
	@$(BASH) $(REGISTRY_SCRIPTS)/verify.sh

# -----------------------------------------------------------------------------
# Crossplane
# -----------------------------------------------------------------------------

crossplane-install:
	@KUBE_CONTEXT=$(KIND_CONTEXT) \
		$(BASH) $(CROSSPLANE_SCRIPTS)/install.sh

crossplane-verify:
	@KUBE_CONTEXT=$(KIND_CONTEXT) \
		$(BASH) $(CROSSPLANE_SCRIPTS)/verify.sh

crossplane-status:
	@kubectl --context $(KIND_CONTEXT) get pods -n crossplane-system
	@helm --kube-context $(KIND_CONTEXT) list -n crossplane-system

crossplane-uninstall:
	@KUBE_CONTEXT=$(KIND_CONTEXT) \
		$(BASH) $(CROSSPLANE_SCRIPTS)/uninstall.sh

# -----------------------------------------------------------------------------
# Bootstrap complet
# -----------------------------------------------------------------------------

bootstrap: \
	doctor \
	kind-create \
	registry-create \
	registry-configure-kind \
	crossplane-install \
	crossplane-verify
	@echo
	@echo "Bootstrap local terminé."

# -----------------------------------------------------------------------------
# Vérification
# -----------------------------------------------------------------------------

verify:
	@$(BASH) $(SCRIPTS_DIR)/verify.sh

# -----------------------------------------------------------------------------
# Destruction
# -----------------------------------------------------------------------------

destroy:
	@$(BASH) $(SCRIPTS_DIR)/destroy.sh