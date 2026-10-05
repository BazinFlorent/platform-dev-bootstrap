#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/common.sh"

require_cmd docker
require_cmd kind

echo "==> Suppression du registry"
if registry_exists; then
  docker rm -f "${REGISTRY_NAME}" >/dev/null
fi

echo "==> Nettoyage de la résolution locale"
"${BOOTSTRAP_DIR}/registry/scripts/host-delete.sh"

echo "==> Suppression du cluster Kind"
if kind_exists; then
  kind delete cluster --name "${KIND_CLUSTER}"
fi

rm -f "${KIND_CONFIG}"

"${SCRIPT_DIR}/cleanup-dir.sh" \
  "${KIND_LOCAL_ROOT}" \
  "${KIND_NODE_IMAGE}"

"${SCRIPT_DIR}/cleanup-dir.sh" \
  "${REGISTRY_ROOT}" \
  "${REGISTRY_IMAGE}"

echo "==> Environnement bootstrap supprimé"