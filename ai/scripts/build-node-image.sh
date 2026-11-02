#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
AI_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"
BOOTSTRAP_HOME="$(cd "${AI_DIR}/.." && pwd)"

source "${BOOTSTRAP_HOME}/core/versions.env"
source "${AI_DIR}/versions.env"

if ! command -v docker >/dev/null 2>&1; then
  echo "[ERROR] Docker est requis pour construire l'image Kind NVIDIA." >&2
  exit 1
fi

AI_KIND_NODE_IMAGE="${AI_KIND_NODE_IMAGE:-${AI_KIND_NODE_IMAGE_REPOSITORY}:${KUBERNETES_VERSION}-nvidia-${NVIDIA_CONTAINER_TOOLKIT_VERSION}}"

echo "==> Construction de l'image Kind NVIDIA"
echo "    Image Kind source : ${KIND_NODE_IMAGE}"
echo "    NVIDIA Toolkit    : ${NVIDIA_CONTAINER_TOOLKIT_VERSION}"
echo "    Image cible       : ${AI_KIND_NODE_IMAGE}"

docker build \
  --build-arg "KIND_NODE_IMAGE=${KIND_NODE_IMAGE}" \
  --build-arg "NVIDIA_CONTAINER_TOOLKIT_VERSION=${NVIDIA_CONTAINER_TOOLKIT_VERSION}" \
  --tag "${AI_KIND_NODE_IMAGE}" \
  "${AI_DIR}/kind"

echo
echo "==> Vérification de NVIDIA Container Toolkit"

docker run \
  --rm \
  --entrypoint nvidia-ctk \
  "${AI_KIND_NODE_IMAGE}" \
  --version

echo
echo "[OK] Image Kind NVIDIA construite : ${AI_KIND_NODE_IMAGE}"
