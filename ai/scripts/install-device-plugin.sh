#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
AI_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"
BOOTSTRAP_HOME="$(cd "${AI_DIR}/.." && pwd)"

source "${BOOTSTRAP_HOME}/core/scripts/common.sh"
source "${AI_DIR}/versions.env"

require_cmd helm
require_cmd kubectl

echo "==> Installation du NVIDIA Device Plugin"
echo "    Cluster   : ${KIND_CLUSTER}"
echo "    Namespace : ${NVIDIA_DEVICE_PLUGIN_NAMESPACE}"
echo "    Version   : ${NVIDIA_DEVICE_PLUGIN_VERSION}"

if ! kind_exists; then
  echo "[ERROR] Cluster Kind introuvable : ${KIND_CLUSTER}" >&2
  exit 1
fi

helm repo add nvdp https://nvidia.github.io/k8s-device-plugin \
  --force-update >/dev/null

helm repo update nvdp >/dev/null

helm upgrade --install nvidia-device-plugin \
  nvdp/nvidia-device-plugin \
  --kube-context "${KIND_CONTEXT}" \
  --namespace "${NVIDIA_DEVICE_PLUGIN_NAMESPACE}" \
  --create-namespace \
  --version "${NVIDIA_DEVICE_PLUGIN_VERSION}"

echo
echo "==> Attente du NVIDIA Device Plugin"

kubectl \
  --context "${KIND_CONTEXT}" \
  --namespace "${NVIDIA_DEVICE_PLUGIN_NAMESPACE}" \
  rollout status daemonset/nvidia-device-plugin \
  --timeout=120s

echo
echo "[OK] NVIDIA Device Plugin installé"
