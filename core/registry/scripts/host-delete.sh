#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CORE_DIR="$(cd "${SCRIPT_DIR}/../.." && pwd)"

source "${CORE_DIR}/scripts/common.sh"

HOSTS_FILE="/etc/hosts"
HOST_MARKER="# platform-bootstrap:${PLATFORM_BOOTSTRAP_NAME}"

if ! grep -Fq "${HOST_MARKER}" "${HOSTS_FILE}"; then
  echo "==> Aucune entrée ${HOSTS_FILE} gérée pour ${PLATFORM_BOOTSTRAP_NAME}"
  exit 0
fi

echo "==> Suppression de l'entrée ${HOSTS_FILE} pour ${PLATFORM_BOOTSTRAP_NAME}"

tmp_file="$(mktemp)"
trap 'rm -f "${tmp_file}"' EXIT

awk -v marker="${HOST_MARKER}" \
  'index($0, marker) == 0' \
  "${HOSTS_FILE}" > "${tmp_file}"

if [[ "${EUID}" -eq 0 ]]; then
  cat "${tmp_file}" > "${HOSTS_FILE}"
elif command -v sudo >/dev/null 2>&1; then
  sudo cp "${tmp_file}" "${HOSTS_FILE}"
else
  echo "ERROR: sudo est requis pour modifier ${HOSTS_FILE}" >&2
  exit 1
fi

echo "  [OK] entrée supprimée"