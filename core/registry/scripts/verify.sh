#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CORE_DIR="$(cd "${SCRIPT_DIR}/../.." && pwd)"

source "${CORE_DIR}/scripts/common.sh"

require_cmd curl
require_cmd docker
require_cmd kind

echo "==> Vérification API registry"
response="$(curl --silent --show-error --fail --cacert "${REGISTRY_CERT}" \
  "https://${REGISTRY_HOST}:${REGISTRY_PORT}/v2/")"
if [[ "${response}" != "{}" ]]; then
  echo "ERROR: réponse registry inattendue: ${response}" >&2
  exit 1
fi
echo "  [OK] https://${REGISTRY_HOST}:${REGISTRY_PORT}/v2/"

REGISTRY_DIR="/etc/containerd/certs.d/${REGISTRY_HOST}:${REGISTRY_PORT}"
while IFS= read -r node; do
  [[ -n "${node}" ]] || continue
  docker exec "${node}" test -s "${REGISTRY_DIR}/ca.crt"
  docker exec "${node}" test -s "${REGISTRY_DIR}/hosts.toml"

  # Pull volontairement inexistant : "manifest unknown" prouve que DNS + TLS +
  # containerd ont atteint le registry. Une erreur x509 est une non-régression.
  pull_output="$(docker exec "${node}" crictl pull \
    "${REGISTRY_HOST}:${REGISTRY_PORT}/${PLATFORM_BOOTSTRAP_NAME}/does-not-exist:v0.0.0" 2>&1 || true)"

  if grep -Eqi 'x509|unknown authority|certificate' <<<"${pull_output}"; then
    echo "ERROR: trust TLS containerd invalide sur ${node}" >&2
    echo "${pull_output}" >&2
    exit 1
  fi

  if ! grep -Eqi 'manifest unknown|manifest_unknown|not found|name unknown' <<<"${pull_output}"; then
    echo "ERROR: connectivité containerd -> registry non confirmée sur ${node}" >&2
    echo "${pull_output}" >&2
    exit 1
  fi

  echo "  [OK] containerd -> registry: ${node}"
done < <(kind get nodes --name "${KIND_CLUSTER}")
