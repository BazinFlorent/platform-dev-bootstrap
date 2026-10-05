#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CORE_DIR="$(cd "${SCRIPT_DIR}/../.." && pwd)"

source "${CORE_DIR}/scripts/common.sh"

HOSTS_FILE="/etc/hosts"
HOST_IP="127.0.0.1"
HOST_MARKER="# platform-bootstrap:${PLATFORM_BOOTSTRAP_NAME}"
HOST_ENTRY="${HOST_IP} ${REGISTRY_HOST} ${HOST_MARKER}"

require_cmd getent

# Déjà géré par cette instance.
if grep -Fq "${HOST_MARKER}" "${HOSTS_FILE}"; then
  if grep -Fq "${HOST_ENTRY}" "${HOSTS_FILE}"; then
    echo "==> ${REGISTRY_HOST} est déjà configuré dans ${HOSTS_FILE}"
    exit 0
  fi

  echo "ERROR: une entrée ${HOST_MARKER} existe mais ne correspond pas à la configuration attendue" >&2
  grep -F "${HOST_MARKER}" "${HOSTS_FILE}" >&2 || true
  exit 1
fi

# Le hostname existe déjà mais n'est pas géré par platform-bootstrap.
if getent hosts "${REGISTRY_HOST}" >/dev/null 2>&1; then
  resolved="$(
    getent hosts "${REGISTRY_HOST}" \
      | awk 'NR == 1 { print $1 }'
  )"

  if [[ "${resolved}" == "${HOST_IP}" ]]; then
    echo "==> ${REGISTRY_HOST} est déjà résolu vers ${HOST_IP} (entrée externe conservée)"
    exit 0
  fi

  echo "ERROR: ${REGISTRY_HOST} est déjà résolu vers ${resolved}, attendu ${HOST_IP}" >&2
  echo "       platform-bootstrap ne modifiera pas cette résolution externe." >&2
  exit 1
fi

echo "==> Ajout de ${REGISTRY_HOST} dans ${HOSTS_FILE}"

if [[ "${EUID}" -eq 0 ]]; then
  printf '%s\n' "${HOST_ENTRY}" >> "${HOSTS_FILE}"
elif command -v sudo >/dev/null 2>&1; then
  printf '%s\n' "${HOST_ENTRY}" | sudo tee -a "${HOSTS_FILE}" >/dev/null
else
  echo "ERROR: sudo est requis pour modifier ${HOSTS_FILE}" >&2
  exit 1
fi

echo "  [OK] ${HOST_ENTRY}"