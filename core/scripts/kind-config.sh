#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/common.sh"

KIND_TOPOLOGY="${KIND_TOPOLOGY:-standard}"

echo "==> Génération de la configuration Kind"
echo "    Topologie : ${KIND_TOPOLOGY}"

case "${KIND_TOPOLOGY}" in
  standard)
    mkdir -p \
      "${KIND_STORAGE}/control-plane" \
      "${KIND_STORAGE}/worker-1" \
      "${KIND_STORAGE}/worker-2"
    ;;

  single-node)
    mkdir -p \
      "${KIND_STORAGE}/control-plane"
    ;;

  *)
    echo "ERROR: topologie Kind inconnue : ${KIND_TOPOLOGY}" >&2
    echo "Valeurs supportées : standard, single-node" >&2
    exit 1
    ;;
esac

{
  while IFS= read -r line; do
    if [[ "${line}" == "__KIND_WORKERS__" ]]; then
      if [[ "${KIND_TOPOLOGY}" == "standard" ]]; then
        cat <<EOF
  - role: worker
    extraMounts:
      - hostPath: ${KIND_STORAGE}/worker-1
        containerPath: /var/local-path-provisioner

  - role: worker
    extraMounts:
      - hostPath: ${KIND_STORAGE}/worker-2
        containerPath: /var/local-path-provisioner
EOF
      fi
    else
      printf '%s\n' "${line}"
    fi
  done < <(
    sed \
      -e "s|__KIND_STORAGE__|${KIND_STORAGE}|g" \
      -e "s|__KIND_HTTP_PORT__|${KIND_HTTP_PORT}|g" \
      -e "s|__KIND_HTTPS_PORT__|${KIND_HTTPS_PORT}|g" \
      "${KIND_TEMPLATE}"
  )
} > "${KIND_CONFIG}"

echo "==> Configuration Kind générée : ${KIND_CONFIG}"