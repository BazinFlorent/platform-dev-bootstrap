#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/common.sh"

echo "==> Génération de la configuration Kind"

mkdir -p \
  "${KIND_STORAGE}/control-plane" \
  "${KIND_STORAGE}/worker-1" \
  "${KIND_STORAGE}/worker-2"

sed \
  -e "s|__KIND_STORAGE__|${KIND_STORAGE}|g" \
  -e "s|__KIND_HTTP_PORT__|${KIND_HTTP_PORT}|g" \
  -e "s|__KIND_HTTPS_PORT__|${KIND_HTTPS_PORT}|g" \
  "${KIND_TEMPLATE}" > "${KIND_CONFIG}"

echo "==> Configuration Kind générée : ${KIND_CONFIG}"
