#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/common.sh"

require_cmd docker

port_in_use() {
  local port="$1"

  if command -v ss >/dev/null 2>&1; then
    ss -H -ltn "sport = :${port}" 2>/dev/null | grep -q .
    return
  fi

  # Fallback via Docker pour les ports publiés par des containers.
  docker ps \
    --format '{{.Ports}}' \
    | grep -Eq "(127\\.0\\.0\\.1|0\\.0\\.0\\.0|:::).*:${port}->"
}

check_port() {
  local name="$1"
  local port="$2"

  if port_in_use "${port}"; then
    echo "ERROR: ${name} port ${port} is already in use." >&2
    return 1
  fi

  echo "  [OK] ${name} port ${port} available"
}

echo "==> Vérification des ports"

check_port "HTTP" "${KIND_HTTP_PORT}"
check_port "HTTPS" "${KIND_HTTPS_PORT}"
check_port "Registry" "${REGISTRY_PORT}"