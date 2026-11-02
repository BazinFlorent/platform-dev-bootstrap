#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
AI_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"
BOOTSTRAP_HOME="$(cd "${AI_DIR}/.." && pwd)"

source "${BOOTSTRAP_HOME}/core/scripts/common.sh"
source "${AI_DIR}/versions.env"

AI_KIND_NODE_IMAGE="${AI_KIND_NODE_IMAGE:-${AI_KIND_NODE_IMAGE_REPOSITORY}:${KUBERNETES_VERSION}-nvidia-${NVIDIA_CONTAINER_TOOLKIT_VERSION}}"

GPU_NODE="$(
  docker ps \
    --filter "label=io.x-k8s.kind.cluster=${KIND_CLUSTER}" \
    --format '{{.Names}}\t{{.Image}}' \
    | awk -v image="${AI_KIND_NODE_IMAGE}" '$2 == image { print $1 }'
)"

if [[ -z "${GPU_NODE}" ]]; then
  echo "[ERROR] Aucun node Kind utilisant l'image NVIDIA n'a été trouvé." >&2
  exit 1
fi

echo "==> Configuration containerd NVIDIA"
echo "    Node GPU : ${GPU_NODE}"

docker exec "${GPU_NODE}" \
  nvidia-ctk runtime configure \
    --runtime=containerd \
    --set-as-default \
    --cdi.enabled

docker exec "${GPU_NODE}" systemctl restart containerd

echo "==> Vérification du runtime NVIDIA"

if ! docker exec "${GPU_NODE}" \
  containerd config dump 2>/dev/null \
  | grep -q "default_runtime_name = 'nvidia'"; then

  echo "[ERROR] Le runtime NVIDIA n'est pas configuré comme runtime par défaut." >&2
  exit 1
fi

echo "[OK] containerd utilise le runtime NVIDIA sur ${GPU_NODE}"
