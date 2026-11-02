#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
AI_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"
BOOTSTRAP_HOME="$(cd "${AI_DIR}/.." && pwd)"

source "${BOOTSTRAP_HOME}/core/scripts/common.sh"
source "${AI_DIR}/versions.env"

require_cmd kubectl
require_cmd kind

TEST_POD="platform-bootstrap-gpu-test"

cleanup() {
  kubectl \
    --context "${KIND_CONTEXT}" \
    delete pod "${TEST_POD}" \
    --ignore-not-found \
    --wait=false \
    >/dev/null 2>&1 || true
}

trap cleanup EXIT

echo "==> Test fonctionnel GPU"

if ! kind_exists; then
  echo "[ERROR] Cluster Kind introuvable : ${KIND_CLUSTER}" >&2
  exit 1
fi

# Nettoyage d'un éventuel test précédent.
cleanup

echo "==> Création d'un pod demandant 1 GPU NVIDIA"

kubectl \
  --context "${KIND_CONTEXT}" \
  apply -f - <<EOF
apiVersion: v1
kind: Pod
metadata:
  name: ${TEST_POD}
spec:
  restartPolicy: Never
  nodeSelector:
    nvidia.com/gpu.present: "true"
  containers:
    - name: gpu-test
      image: ${CUDA_TEST_IMAGE}
      command:
        - nvidia-smi
      resources:
        limits:
          nvidia.com/gpu: 1
EOF

echo "==> Attente de l'exécution du pod"

if ! kubectl \
  --context "${KIND_CONTEXT}" \
  wait \
  --for=jsonpath='{.status.phase}'=Succeeded \
  "pod/${TEST_POD}" \
  --timeout=120s; then

  echo
  echo "[ERROR] Le test fonctionnel GPU a échoué." >&2

  echo
  echo "==> État du pod"
  kubectl \
    --context "${KIND_CONTEXT}" \
    get pod "${TEST_POD}" \
    -o wide || true

  echo
  echo "==> Événements"
  kubectl \
    --context "${KIND_CONTEXT}" \
    describe pod "${TEST_POD}" || true

  exit 1
fi

echo
echo "==> Résultat nvidia-smi"

kubectl \
  --context "${KIND_CONTEXT}" \
  logs "${TEST_POD}"

echo
echo "[OK] Un workload Kubernetes a consommé le GPU NVIDIA."
echo
echo "AI functional test PASSED."