#!/usr/bin/env bash
set -euo pipefail

COMMON_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BOOTSTRAP_DIR="$(cd "${COMMON_DIR}/.." && pwd)"
VERSIONS_FILE="${BOOTSTRAP_DIR}/versions.env"

# shellcheck disable=SC1090
source "${VERSIONS_FILE}"

# -----------------------------------------------------------------------------
# Runtime state
# -----------------------------------------------------------------------------

PLATFORM_BOOTSTRAP_STATE_ROOT="${PLATFORM_BOOTSTRAP_STATE_ROOT:-${XDG_STATE_HOME:-${HOME}/.local/state}/platform-bootstrap}"

PLATFORM_BOOTSTRAP_STATE_DIR="${PLATFORM_BOOTSTRAP_STATE_DIR:-${PLATFORM_BOOTSTRAP_STATE_ROOT}/${PLATFORM_BOOTSTRAP_NAME}}"

# Registry OCI
REGISTRY_ROOT="${PLATFORM_BOOTSTRAP_STATE_DIR}/registry"
REGISTRY_CERT_DIR="${REGISTRY_ROOT}/certs"
REGISTRY_DATA_DIR="${REGISTRY_ROOT}/data"
REGISTRY_CERT="${REGISTRY_CERT_DIR}/domain.crt"
REGISTRY_KEY="${REGISTRY_CERT_DIR}/domain.key"

# Kind
KIND_DIR="${BOOTSTRAP_DIR}/kind"
KIND_TEMPLATE="${KIND_DIR}/kind.yaml.tpl"

KIND_LOCAL_ROOT="${PLATFORM_BOOTSTRAP_STATE_DIR}/kind"
KIND_CONFIG="${KIND_LOCAL_ROOT}/kind.yaml"
KIND_STORAGE="${KIND_LOCAL_ROOT}/storage"

KIND_CONTEXT="kind-${KIND_CLUSTER}"

require_cmd() {
  command -v "$1" >/dev/null 2>&1 || {
    echo "ERROR: commande requise introuvable: $1" >&2
    return 1
  }
}

kind_exists() {
  kind get clusters 2>/dev/null | grep -Fxq "${KIND_CLUSTER}"
}

registry_exists() {
  docker inspect "${REGISTRY_NAME}" >/dev/null 2>&1
}

registry_running() {
  [[ "$(docker inspect -f '{{.State.Running}}' "${REGISTRY_NAME}" 2>/dev/null || true)" == "true" ]]
}