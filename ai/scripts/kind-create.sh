#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
AI_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"
BOOTSTRAP_HOME="$(cd "${AI_DIR}/.." && pwd)"

source "${BOOTSTRAP_HOME}/core/scripts/common.sh"

AI_KIND_CONFIG="${KIND_LOCAL_ROOT}/kind-ai.yaml"

require_cmd kind
require_cmd docker

if kind_exists; then
  echo "[ERROR] Le cluster Kind existe déjà : ${KIND_CLUSTER}" >&2
  exit 1
fi

if [[ ! -f "${AI_KIND_CONFIG}" ]]; then
  echo "[ERROR] Configuration Kind AI introuvable : ${AI_KIND_CONFIG}" >&2
  echo "        Exécuter d'abord :" >&2
  echo "        platform-bootstrap -n ${PLATFORM_BOOTSTRAP_NAME} kind-ai-config" >&2
  exit 1
fi

echo "==> Création du cluster Kind AI"
echo "    Cluster       : ${KIND_CLUSTER}"
echo "    Configuration : ${AI_KIND_CONFIG}"

kind create cluster \
  --name "${KIND_CLUSTER}" \
  --config "${AI_KIND_CONFIG}"

echo
echo "[OK] Cluster Kind AI créé : ${KIND_CLUSTER}"
