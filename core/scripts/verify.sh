#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/common.sh"

require_cmd kubectl

echo "==> Vérification Kubernetes"
kubectl --context "${KIND_CONTEXT}" wait \
  --for=condition=Ready \
  nodes \
  --all \
  --timeout=180s

kubectl --context "${KIND_CONTEXT}" get nodes -o wide

"${BOOTSTRAP_DIR}/registry/scripts/verify.sh"

KUBE_CONTEXT="${KIND_CONTEXT}" \
  "${BOOTSTRAP_DIR}/crossplane/scripts/verify.sh"

echo
echo "Bootstrap READY."