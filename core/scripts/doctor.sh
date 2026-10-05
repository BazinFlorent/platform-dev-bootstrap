#!/usr/bin/env bash
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=common.sh
source "${SCRIPT_DIR}/common.sh"

commands=(git docker kubectl kind helm crossplane openssl curl sed awk)
failed=0

echo "==> Vérification des prérequis"
for cmd in "${commands[@]}"; do
  if command -v "${cmd}" >/dev/null 2>&1; then
    printf '  [OK]   %-12s %s\n' "${cmd}" "$(command -v "${cmd}")"
  else
    printf '  [FAIL] %-12s introuvable\n' "${cmd}"
    failed=1
  fi
done

if command -v docker >/dev/null 2>&1; then
  if docker info >/dev/null 2>&1; then
    echo "  [OK]   Docker daemon accessible"
  else
    echo "  [FAIL] Docker daemon inaccessible"
    failed=1
  fi
fi

if grep -qi microsoft /proc/version 2>/dev/null; then
  echo "  [INFO] Environnement WSL détecté"
fi

echo
echo "Versions bootstrap :"
echo "  Kubernetes : ${KUBERNETES_VERSION}"
echo "  Kind image : ${KIND_NODE_IMAGE}"
echo "  Registry   : ${REGISTRY_IMAGE} (${REGISTRY_HOST}:${REGISTRY_PORT})"

if (( failed != 0 )); then
  echo >&2
  echo "ERROR: prérequis incomplets. Voir bootstrap/README.md." >&2
  exit 1
fi

echo
echo "Prérequis OK."
