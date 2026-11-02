#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
AI_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"
BOOTSTRAP_HOME="$(cd "${AI_DIR}/.." && pwd)"

source "${BOOTSTRAP_HOME}/core/scripts/common.sh"
source "${AI_DIR}/versions.env"

require_cmd docker
require_cmd kubectl
require_cmd kind

echo "==> Vérification du bootstrap AI"

if ! kind_exists; then
  echo "[ERROR] Cluster Kind introuvable : ${KIND_CLUSTER}" >&2
  exit 1
fi

AI_KIND_NODE_IMAGE="${AI_KIND_NODE_IMAGE:-${AI_KIND_NODE_IMAGE_REPOSITORY}:${KUBERNETES_VERSION}-nvidia-${NVIDIA_CONTAINER_TOOLKIT_VERSION}}"

GPU_NODE="$(
  docker ps \
    --filter "label=io.x-k8s.kind.cluster=${KIND_CLUSTER}" \
    --format '{{.Names}}\t{{.Image}}' \
    | awk -v image="${AI_KIND_NODE_IMAGE}" '$2 == image { print $1 }'
)"

if [[ -z "${GPU_NODE}" ]]; then
  echo "[ERROR] Aucun worker Kind GPU trouvé." >&2
  exit 1
fi

echo "  [OK] Worker GPU détecté : ${GPU_NODE}"

GPU_LABEL="$(
  kubectl \
    --context "${KIND_CONTEXT}" \
    get node "${GPU_NODE}" \
    -o jsonpath='{.metadata.labels.nvidia\.com/gpu\.present}'
)"

if [[ "${GPU_LABEL}" != "true" ]]; then
  echo "[ERROR] Label nvidia.com/gpu.present=true absent sur ${GPU_NODE}" >&2
  exit 1
fi

echo "  [OK] Label GPU présent"

if ! docker exec "${GPU_NODE}" \
  containerd config dump 2>/dev/null \
  | grep -q "default_runtime_name = 'nvidia'"; then

  echo "[ERROR] Runtime NVIDIA non configuré dans containerd." >&2
  exit 1
fi

echo "  [OK] Runtime NVIDIA actif dans containerd"

DESIRED="$(
  kubectl \
    --context "${KIND_CONTEXT}" \
    --namespace "${NVIDIA_DEVICE_PLUGIN_NAMESPACE}" \
    get daemonset nvidia-device-plugin \
    -o jsonpath='{.status.desiredNumberScheduled}'
)"

READY="$(
  kubectl \
    --context "${KIND_CONTEXT}" \
    --namespace "${NVIDIA_DEVICE_PLUGIN_NAMESPACE}" \
    get daemonset nvidia-device-plugin \
    -o jsonpath='{.status.numberReady}'
)"

if [[ "${DESIRED}" -lt 1 ]]; then
  echo "[ERROR] NVIDIA Device Plugin ne cible aucun node." >&2
  exit 1
fi

if [[ "${READY}" != "${DESIRED}" ]]; then
  echo "[ERROR] NVIDIA Device Plugin non prêt : ${READY}/${DESIRED}" >&2
  exit 1
fi

echo "  [OK] NVIDIA Device Plugin prêt : ${READY}/${DESIRED}"

GPU_CAPACITY="$(
  kubectl \
    --context "${KIND_CONTEXT}" \
    get node "${GPU_NODE}" \
    -o jsonpath='{.status.capacity.nvidia\.com/gpu}'
)"

GPU_ALLOCATABLE="$(
  kubectl \
    --context "${KIND_CONTEXT}" \
    get node "${GPU_NODE}" \
    -o jsonpath='{.status.allocatable.nvidia\.com/gpu}'
)"

if [[ -z "${GPU_CAPACITY}" || "${GPU_CAPACITY}" == "0" ]]; then
  echo "[ERROR] Aucune capacité GPU exposée par Kubernetes." >&2
  exit 1
fi

if [[ -z "${GPU_ALLOCATABLE}" || "${GPU_ALLOCATABLE}" == "0" ]]; then
  echo "[ERROR] Aucun GPU allocatable exposé par Kubernetes." >&2
  exit 1
fi

echo "  [OK] GPU Kubernetes exposé"
echo "       Capacity    : ${GPU_CAPACITY}"
echo "       Allocatable : ${GPU_ALLOCATABLE}"

echo
echo "AI bootstrap READY."