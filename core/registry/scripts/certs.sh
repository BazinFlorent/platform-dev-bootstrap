#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CORE_DIR="$(cd "${SCRIPT_DIR}/../.." && pwd)"

source "${CORE_DIR}/scripts/common.sh"

require_cmd openssl
mkdir -p "${REGISTRY_CERT_DIR}" "${REGISTRY_DATA_DIR}"

if [[ -s "${REGISTRY_CERT}" && -s "${REGISTRY_KEY}" ]]; then
  echo "==> Certificat registry déjà présent: ${REGISTRY_CERT}"
  exit 0
fi

echo "==> Génération du certificat TLS local pour ${REGISTRY_HOST}"
openssl req \
  -newkey rsa:4096 \
  -nodes \
  -sha256 \
  -keyout "${REGISTRY_KEY}" \
  -x509 \
  -days "${REGISTRY_CERT_DAYS}" \
  -out "${REGISTRY_CERT}" \
  -subj "/CN=${REGISTRY_HOST}" \
  -addext "subjectAltName=DNS:${REGISTRY_HOST},DNS:localhost,IP:127.0.0.1" \
  >/dev/null 2>&1

chmod 600 "${REGISTRY_KEY}"
echo "==> Certificat créé: ${REGISTRY_CERT}"
