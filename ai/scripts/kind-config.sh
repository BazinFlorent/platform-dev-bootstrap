#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
AI_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"
BOOTSTRAP_HOME="$(cd "${AI_DIR}/.." && pwd)"

source "${BOOTSTRAP_HOME}/core/scripts/common.sh"
source "${AI_DIR}/versions.env"

AI_KIND_TEMPLATE="${AI_DIR}/kind/kind-gpu.yaml.tpl"
AI_KIND_CONFIG="${KIND_LOCAL_ROOT}/kind-ai.yaml"

AI_KIND_NODE_IMAGE="${AI_KIND_NODE_IMAGE:-${AI_KIND_NODE_IMAGE_REPOSITORY}:${KUBERNETES_VERSION}-nvidia-${NVIDIA_CONTAINER_TOOLKIT_VERSION}}"

if [[ ! -f "${AI_KIND_TEMPLATE}" ]]; then
  echo "[ERROR] Template Kind AI introuvable : ${AI_KIND_TEMPLATE}" >&2
  exit 1
fi

if ! docker image inspect "${AI_KIND_NODE_IMAGE}" >/dev/null 2>&1; then
  echo "[ERROR] Image Kind NVIDIA absente : ${AI_KIND_NODE_IMAGE}" >&2
  echo "        Exécuter d'abord :" >&2
  echo "        platform-bootstrap build-ai-node-image" >&2
  exit 1
fi

echo "==> Génération de la configuration Kind AI"
echo "    Instance         : ${PLATFORM_BOOTSTRAP_NAME}"
echo "    Image standard   : ${KIND_NODE_IMAGE}"
echo "    Image GPU        : ${AI_KIND_NODE_IMAGE}"
echo "    Configuration    : ${AI_KIND_CONFIG}"

mkdir -p \
  "${KIND_STORAGE}/control-plane" \
  "${KIND_STORAGE}/worker-1" \
  "${KIND_STORAGE}/gpu-worker"

sed \
  -e "s|__KIND_NODE_IMAGE__|${KIND_NODE_IMAGE}|g" \
  -e "s|__AI_KIND_NODE_IMAGE__|${AI_KIND_NODE_IMAGE}|g" \
  -e "s|__KIND_STORAGE__|${KIND_STORAGE}|g" \
  -e "s|__KIND_HTTP_PORT__|${KIND_HTTP_PORT}|g" \
  -e "s|__KIND_HTTPS_PORT__|${KIND_HTTPS_PORT}|g" \
  "${AI_KIND_TEMPLATE}" \
  > "${AI_KIND_CONFIG}"

echo "[OK] Configuration Kind AI générée : ${AI_KIND_CONFIG}"