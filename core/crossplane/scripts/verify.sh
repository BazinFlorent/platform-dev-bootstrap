#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# shellcheck source=lib.sh
source "${SCRIPT_DIR}/lib.sh"

require_cmd helm
require_cmd kubectl

EXPECTED_VERSION="$(crossplane_version)"
TEST_PACKAGE="${REGISTRY_HOST}:${REGISTRY_PORT}/${PLATFORM_BOOTSTRAP_NAME}/does-not-exist:v0.0.0"
TEST_NAME="registry-connectivity-test"

echo "==> Checking Helm release"
helm_cmd status crossplane -n crossplane-system >/dev/null

echo "==> Checking Crossplane deployments"
kubectl_cmd wait \
  --namespace crossplane-system \
  --for=condition=Available \
  deployment/crossplane \
  --timeout=180s

kubectl_cmd wait \
  --namespace crossplane-system \
  --for=condition=Available \
  deployment/crossplane-rbac-manager \
  --timeout=180s

echo "==> Checking Crossplane CRDs"
kubectl_cmd get crd \
  compositeresourcedefinitions.apiextensions.crossplane.io \
  >/dev/null

kubectl_cmd get crd \
  compositions.apiextensions.crossplane.io \
  >/dev/null

echo "==> Checking TLS trust toward local OCI registry"

cat <<EOF | kubectl_cmd apply -f - >/dev/null
apiVersion: pkg.crossplane.io/v1
kind: Configuration
metadata:
  name: ${TEST_NAME}
spec:
  package: ${TEST_PACKAGE}
EOF

trap 'kubectl_cmd delete configuration.pkg.crossplane.io "${TEST_NAME}" --ignore-not-found >/dev/null 2>&1 || true' EXIT

trust_ok=0

for _ in $(seq 1 20); do
  message="$(
    kubectl_cmd get configuration.pkg.crossplane.io "${TEST_NAME}" \
      -o jsonpath='{range .status.conditions[*]}{.message}{"\n"}{end}' \
      2>/dev/null || true
  )"

  if grep -Eqi 'x509|unknown authority|certificate' <<<"${message}"; then
    echo "ERROR: Crossplane ne fait pas confiance au certificat du registry" >&2
    echo "${message}" >&2
    exit 1
  fi

  if grep -Eqi 'manifest unknown|manifest_unknown|not found|name unknown' <<<"${message}"; then
    trust_ok=1
    break
  fi

  sleep 2
done

if (( trust_ok == 0 )); then
  echo "ERROR: impossible de confirmer la connectivité Crossplane -> registry" >&2
  kubectl_cmd get configuration.pkg.crossplane.io "${TEST_NAME}" -o yaml >&2 || true
  exit 1
fi

echo "  [OK] Trust TLS Crossplane -> ${REGISTRY_HOST}:${REGISTRY_PORT}"
echo
echo "Crossplane foundation is READY (version: ${EXPECTED_VERSION})."