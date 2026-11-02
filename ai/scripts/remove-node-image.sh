#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
AI_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"
BOOTSTRAP_HOME="$(cd "${AI_DIR}/.." && pwd)"

source "${BOOTSTRAP_HOME}/core/scripts/common.sh"
source "${AI_DIR}/versions.env"

require_cmd docker

AI_KIND_NODE_IMAGE="${AI_KIND_NODE_IMAGE:-${AI_KIND_NODE_IMAGE_REPOSITORY}:${KUBERNETES_VERSION}-nvidia-${NVIDIA_CONTAINER_TOOLKIT_VERSION}}"

if ! docker image inspect "${AI_KIND_NODE_IMAGE}" >/dev/null 2>&1; then
  echo "  [OK] Image Kind NVIDIA absente : ${AI_KIND_NODE_IMAGE}"
  exit 0
fi

USERS="$(
  docker ps -a \
    --filter "ancestor=${AI_KIND_NODE_IMAGE}" \
    --format '{{.Names}}'
)"

if [[ -n "${USERS}" ]]; then
  echo "  [INFO] Image Kind NVIDIA conservée : encore utilisée"
  echo "${USERS}" | sed 's/^/         - /'
  exit 0
fi

docker image rm "${AI_KIND_NODE_IMAGE}" >/dev/null

echo "  [OK] Image Kind NVIDIA supprimée : ${AI_KIND_NODE_IMAGE}"