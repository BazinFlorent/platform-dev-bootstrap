#!/usr/bin/env bash
set -euo pipefail

path="${1:?usage: cleanup-dir.sh <path>}"
helper_image="${2:-registry:2}"

[[ -e "${path}" ]] || exit 0

if rm -rf "${path}" 2>/dev/null; then
  exit 0
fi

# Des workloads Kubernetes/containers peuvent avoir écrit des fichiers root-owned.
# Le nettoyage est alors réalisé par un conteneur root plutôt que par sudo.
mkdir -p "${path}"
docker run --rm \
  --entrypoint sh \
  -v "${path}:/cleanup" \
  "${helper_image}" \
  -c 'find /cleanup -mindepth 1 -delete' >/dev/null
rmdir "${path}" 2>/dev/null || true
