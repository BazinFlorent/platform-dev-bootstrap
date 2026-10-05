#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CORE_DIR="$(cd "${SCRIPT_DIR}/../.." && pwd)"

source "${CORE_DIR}/scripts/common.sh"

require_cmd docker

"${SCRIPT_DIR}/certs.sh"
"${SCRIPT_DIR}/host.sh"

if ! docker network inspect kind >/dev/null 2>&1; then
  echo "ERROR: réseau Docker 'kind' absent. Créer le cluster Kind avant le registry." >&2
  exit 1
fi

if registry_running; then
  echo "==> Registry ${REGISTRY_NAME} déjà démarré"
  exit 0
fi

if registry_exists; then
  docker rm -f "${REGISTRY_NAME}" >/dev/null
fi

echo "==> Démarrage du registry OCI TLS ${REGISTRY_HOST}:${REGISTRY_PORT}"

docker run -d \
  --restart=always \
  --name "${REGISTRY_NAME}" \
  --network kind \
  --network-alias "${REGISTRY_HOST}" \
  -p "127.0.0.1:${REGISTRY_PORT}:${REGISTRY_PORT}" \
  -v "${REGISTRY_CERT_DIR}:/certs:ro" \
  -v "${REGISTRY_DATA_DIR}:/var/lib/registry" \
  -e "REGISTRY_HTTP_ADDR=0.0.0.0:${REGISTRY_PORT}" \
  -e REGISTRY_HTTP_TLS_CERTIFICATE=/certs/domain.crt \
  -e REGISTRY_HTTP_TLS_KEY=/certs/domain.key \
  "${REGISTRY_IMAGE}" >/dev/null

echo "==> Registry démarré"