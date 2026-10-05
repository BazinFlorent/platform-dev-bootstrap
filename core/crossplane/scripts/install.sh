#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# shellcheck source=lib.sh
source "${SCRIPT_DIR}/lib.sh"

require_cmd helm
require_cmd kubectl

VERSION="$(crossplane_version)"

PLATFORM_BOOTSTRAP_STATE_DIR="${PLATFORM_BOOTSTRAP_STATE_DIR:-${XDG_STATE_HOME:-${HOME}/.local/state}/platform-bootstrap}"

REGISTRY_CA_CERT="${REGISTRY_CA_CERT:-${PLATFORM_BOOTSTRAP_STATE_DIR}/registry/certs/domain.crt}"
REGISTRY_CA_CONFIGMAP="${REGISTRY_CA_CONFIGMAP:-registry-ca-bundle}"

VALUES_FILE="${CROSSPLANE_DIR}/values.yaml"

if [[ -z "${VERSION}" ]]; then
  echo "ERROR: Crossplane version not found in ${VERSIONS_FILE}" >&2
  exit 1
fi

if [[ ! -s "${REGISTRY_CA_CERT}" ]]; then
  echo "ERROR: registry CA certificate not found: ${REGISTRY_CA_CERT}" >&2
  exit 1
fi

if [[ ! -s "${VALUES_FILE}" ]]; then
  echo "ERROR: Crossplane values file not found: ${VALUES_FILE}" >&2
  exit 1
fi

echo "==> Preparing Crossplane registry CA"

kubectl_cmd create namespace crossplane-system \
  --dry-run=client \
  -o yaml \
  | kubectl_cmd apply -f - >/dev/null

kubectl_cmd -n crossplane-system create configmap "${REGISTRY_CA_CONFIGMAP}" \
  --from-file=ca.crt="${REGISTRY_CA_CERT}" \
  --dry-run=client \
  -o yaml \
  | kubectl_cmd apply -f - >/dev/null

echo "==> Installing Crossplane ${VERSION}"

helm repo add crossplane-stable \
  https://charts.crossplane.io/stable \
  --force-update >/dev/null

helm repo update crossplane-stable >/dev/null

helm_cmd upgrade --install crossplane \
  crossplane-stable/crossplane \
  --namespace crossplane-system \
  --version "${VERSION}" \
  --values "${VALUES_FILE}" \
  --set "registryCaBundleConfig.name=${REGISTRY_CA_CONFIGMAP}" \
  --set 'registryCaBundleConfig.key=ca.crt' \
  --wait \
  --timeout 5m

echo "==> Crossplane ${VERSION} installed"