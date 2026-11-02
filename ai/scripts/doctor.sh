#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
AI_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"

source "${AI_DIR}/versions.env"

require_cmd() {
  if ! command -v "$1" >/dev/null 2>&1; then
    echo "[ERROR] Commande requise absente : $1" >&2
    exit 1
  fi
}

echo "==> Vérification des prérequis AI"

require_cmd nvidia-smi
require_cmd docker

echo
echo "==> Vérification GPU depuis WSL"

if ! nvidia-smi >/dev/null 2>&1; then
  echo "[ERROR] Le GPU NVIDIA n'est pas accessible depuis WSL." >&2
  exit 1
fi

GPU_NAME="$(
  nvidia-smi \
    --query-gpu=name \
    --format=csv,noheader \
    | head -n 1
)"

echo "  [OK] GPU NVIDIA accessible depuis WSL"
echo "       ${GPU_NAME}"

echo
echo "==> Vérification GPU depuis Docker"

if ! docker info >/dev/null 2>&1; then
  echo "[ERROR] Docker n'est pas accessible." >&2
  exit 1
fi

if ! docker run \
  --rm \
  --gpus all \
  "${CUDA_TEST_IMAGE}" \
  nvidia-smi \
  >/dev/null 2>&1; then

  echo "[ERROR] Le GPU NVIDIA n'est pas accessible depuis un container Docker." >&2
  echo "        Vérifier Docker Desktop et le support NVIDIA Container Toolkit." >&2
  exit 1
fi

echo "  [OK] GPU NVIDIA accessible depuis un container Docker"

echo
echo "AI doctor READY."
