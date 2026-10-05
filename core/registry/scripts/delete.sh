#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CORE_DIR="$(cd "${SCRIPT_DIR}/../.." && pwd)"

source "${CORE_DIR}/scripts/common.sh"

require_cmd docker

echo "==> Suppression du registry"

if registry_exists; then
  docker rm -f "${REGISTRY_NAME}" >/dev/null
fi

# Les données OCI peuvent être réinitialisées.
# Le certificat TLS est volontairement conservé : il représente
# l'identité du registry de cette instance.
"${CORE_DIR}/scripts/cleanup-dir.sh" \
  "${REGISTRY_DATA_DIR}" \
  "${REGISTRY_IMAGE}"

echo "==> Registry supprimé"
echo "==> Certificat TLS conservé : ${REGISTRY_CERT}"
