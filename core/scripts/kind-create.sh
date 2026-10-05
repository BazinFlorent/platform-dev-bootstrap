#!/usr/bin/env bash
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/common.sh"

require_cmd kind
require_cmd docker

if kind_exists; then
  echo "==> Cluster Kind ${KIND_CLUSTER} déjà présent"
  exit 0
fi

"${SCRIPT_DIR}/kind-config.sh"

echo "==> Création du cluster Kind ${KIND_CLUSTER} (${KIND_NODE_IMAGE})"
kind create cluster \
  --name "${KIND_CLUSTER}" \
  --image "${KIND_NODE_IMAGE}" \
  --config "${KIND_CONFIG}"
