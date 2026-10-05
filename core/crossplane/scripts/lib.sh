#!/usr/bin/env bash
set -euo pipefail

LIB_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CROSSPLANE_DIR="$(cd "${LIB_DIR}/.." && pwd)"
BOOTSTRAP_DIR="$(cd "${CROSSPLANE_DIR}/.." && pwd)"
VERSIONS_FILE="${BOOTSTRAP_DIR}/versions.env"

# shellcheck disable=SC1090
source "${VERSIONS_FILE}"

# Optional Kubernetes context.
# When empty, kubectl/helm use the current context.
KUBE_CONTEXT="${KUBE_CONTEXT:-}"

kubectl_cmd() {
  if [[ -n "${KUBE_CONTEXT}" ]]; then
    kubectl --context "${KUBE_CONTEXT}" "$@"
  else
    kubectl "$@"
  fi
}

helm_cmd() {
  if [[ -n "${KUBE_CONTEXT}" ]]; then
    helm --kube-context "${KUBE_CONTEXT}" "$@"
  else
    helm "$@"
  fi
}

require_cmd() {
  command -v "$1" >/dev/null 2>&1 || {
    echo "ERROR: required command '$1' not found" >&2
    exit 1
  }
}

crossplane_version() {
  printf '%s\n' "${CROSSPLANE_VERSION}"
}

crossplane_function_pat_version() {
  printf '%s\n' "${CROSSPLANE_FUNCTION_PATCH_AND_TRANSFORM_VERSION}"
}