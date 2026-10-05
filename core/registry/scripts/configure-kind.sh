#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CORE_DIR="$(cd "${SCRIPT_DIR}/../.." && pwd)"

source "${CORE_DIR}/scripts/common.sh"

require_cmd docker
require_cmd kind

if ! kind_exists; then
  echo "ERROR: cluster Kind ${KIND_CLUSTER} absent" >&2
  exit 1
fi

if [[ ! -s "${REGISTRY_CERT}" ]]; then
  echo "ERROR: certificat registry absent: ${REGISTRY_CERT}" >&2
  exit 1
fi

REGISTRY_DIR="/etc/containerd/certs.d/${REGISTRY_HOST}:${REGISTRY_PORT}"

echo "==> Configuration du trust registry dans les nodes Kind"

while IFS= read -r node; do
  [[ -n "${node}" ]] || continue

  docker exec "${node}" mkdir -p "${REGISTRY_DIR}"

  docker cp \
    "${REGISTRY_CERT}" \
    "${node}:${REGISTRY_DIR}/ca.crt" >/dev/null

  cat <<EOF | docker exec -i "${node}" sh -c "cat > '${REGISTRY_DIR}/hosts.toml'"
server = "https://${REGISTRY_HOST}:${REGISTRY_PORT}"

[host."https://${REGISTRY_HOST}:${REGISTRY_PORT}"]
  capabilities = ["pull", "resolve", "push"]
  ca = "${REGISTRY_DIR}/ca.crt"
EOF

  echo "  [OK] ${node}"
done < <(kind get nodes --name "${KIND_CLUSTER}")